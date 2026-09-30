import Foundation

// iAP2 updates are deltas. Keep artwork and the playback clock independent.
struct NowPlayingState {
    var trackID: String?
    var title = ""
    var artist = ""
    var album = ""
    var appID = ""
    var artworkID: Int?
    var artwork: Data?
    var duration = 0.0
    var position = 0.0
    var rate = 0.0
    var canSeek = false
    private var clock = 0.0
    private var lastElapsedAt = 0.0
    private var covers: [String:Data] = [:]
    private func coverKey(_ id:Int,_ track:String?) -> String {"\(track ?? ""):\(id)"}
    private var pendingSeek: (position:Double, until:Double)?

    mutating func advance(to now:Double) {
        if clock>0 {position += max(0,now-clock)*rate}
        position=max(0,position)
        if duration>0 {position=min(position,duration)}
        clock=now
    }
    mutating func acceptSeek(_ seconds:Double, at now:Double) {
        advance(to:now)
        position=max(0,min(seconds,duration))
        pendingSeek=(position,now+2)
    }
    mutating func receive(_ event:[String:Any], at now:Double) {
        advance(to:now)
        if event["type"] as? String == "albumart" {
            guard let id=event["artworkId"] as? Int,let encoded=event["dataB64"] as? String,let bytes=Data(base64Encoded:encoded),!bytes.isEmpty else {return}
            let track=event["trackId"] as? String
            let key=coverKey(id,track)
            covers[key]=bytes
            if covers.count>16,let stale=covers.keys.first(where:{$0 != key && $0 != artworkID.map({coverKey($0,trackID)})}) {covers.removeValue(forKey:stale)}
            if track != nil && track==trackID && artworkID==nil {artworkID=id}
            if id==artworkID && (track==nil || track==trackID) {artwork=bytes}
            return
        }
        let nextID=event["trackId"] as? String
        let nextTitle=event["title"] as? String
        let nextApp=event["appId"] as? String
        let changed=(nextID != nil && nextID != trackID)
            || (nextApp != nil && !appID.isEmpty && nextApp != appID)
        if changed {
            trackID=nextID;title="";artist="";album="";duration=0;position=0;artworkID=nil;artwork=nil;pendingSeek=nil;lastElapsedAt=0
        }
        if let id=nextID {trackID=id}
        if let value=nextTitle {title=value}
        if let value=event["artist"] as? String {artist=value}
        if let value=event["album"] as? String {album=value}
        if let value=nextApp {if !appID.isEmpty && value != appID {canSeek=false};appID=value}
        if let id=event["artworkId"] as? Int {
            artworkID=id
            let key=coverKey(id,trackID),unknown=coverKey(id,nil)
            if covers[key]==nil,let bytes=covers[unknown],trackID != nil {covers[key]=bytes;covers.removeValue(forKey:unknown)}
            if let bytes=covers[key] {artwork=bytes}
        }
        if artwork==nil,let track=trackID,let key=covers.keys.first(where:{$0.hasPrefix(track+":")}) {
            if let bytes=covers[key] {artwork=bytes};artworkID=Int(key.dropFirst(track.count+1))
        }
        if let ms=event["durationMs"] as? Double,ms.isFinite {duration=max(0,ms/1000)}
        if let ms=event["elapsedMs"] as? Double,ms.isFinite,
           (event["elapsedAtMs"] as? Double).map({$0>=lastElapsedAt}) ?? true {
            if let stamp=event["elapsedAtMs"] as? Double {lastElapsedAt=stamp}
            let effectiveRate=(event["playing"] as? Int)==0 ? 0 : ((event["playbackRate"] as? Double) ?? ((event["playing"] as? Int)==1 ? 1 : rate))
            let age=(event["elapsedAtMs"] as? Double).map{max(0,Date().timeIntervalSince1970-$0/1000)} ?? 0
            let seconds=max(0,ms/1000 + min(age,300)*max(0,effectiveRate))
            if let pending=pendingSeek,now<pending.until,abs(seconds-position)>2 {
                // Ignore the last in-flight update from before the user's seek.
            } else {position=seconds;pendingSeek=nil}
        }
        if let playing=event["playing"] as? Int {rate=playing==1 ? 1 : 0}
        if let value=event["playbackRate"] as? Double,value.isFinite,value>=0,(event["playing"] as? Int) != 0 {rate=value}
        if let available=event["canSeek"] as? Bool {canSeek=available}
        if duration>0 {position=min(position,duration)}
    }
}
