import Foundation
@main struct MediaFeedTests {
    static func main() throws {
        var lines=MediaJSONLines(),state=NowPlayingState()
        let cover=Data(repeating:42,count:150000)
        let events:[[String:Any]]=[
            ["type":"albumart","trackId":"song","artworkId":130,"dataB64":cover.base64EncodedString()],
            ["type":"nowplaying","trackId":"song","artworkId":130,"durationMs":375000,"elapsedMs":150000,"playing":1,"playbackRate":1,"canSeek":true],
            ["type":"nowplaying","elapsedMs":151000]
        ]
        var payload=Data()
        for event in events {payload.append(try JSONSerialization.data(withJSONObject:event));payload.append(10)}
        var count=0
        for offset in stride(from:0,to:payload.count,by:4093) {
            for event in lines.append(payload.subdata(in:offset..<min(offset+4093,payload.count))) {
                state.receive(event,at:100);count += 1
            }
        }
        precondition(count==3 && state.artwork==cover && state.duration==375 && state.position==151 && state.canSeek)
        print("Media feed: fragmented large artwork, real JSON integer fields and subsequent progress deltas passed")
    }
}
