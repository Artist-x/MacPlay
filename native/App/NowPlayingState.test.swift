import Foundation
@main struct NowPlayingTests {
    static func main() {
        var state=NowPlayingState()
        let cover=Data([1,2,3]).base64EncodedString()
        state.receive(["type":"albumart","artworkId":7,"dataB64":cover],at:100)
        state.receive(["trackId":"A","title":"Song A","artworkId":7,"durationMs":180000.0,"elapsedMs":10000.0,"playing":1,"canSeek":true],at:100)
        precondition(state.artwork==Data([1,2,3])) // Cover may precede track metadata.
        state.receive(["trackId":"A","title":"Song A","playing":1],at:105)
        precondition(state.artwork != nil && state.position==15) // Repeated deltas preserve cover and clock.
        state.receive(["title":"歌词第一行"],at:105)
        state.receive(["title":"歌词第二行","artworkId":99],at:105)
        precondition(state.trackID=="A" && state.artwork==Data([1,2,3]) && state.duration==180 && state.position==15 && state.canSeek)
        state.receive(["artworkId":7],at:105)
        state.receive(["playing":0,"playbackRate":1.0],at:107);state.advance(to:110)
        precondition(state.position==17 && state.rate==0) // Pause freezes the extrapolated position.
        state.receive(["playing":1],at:110);state.advance(to:113)
        precondition(state.position==20)
        state.acceptSeek(80,at:113)
        state.receive(["elapsedMs":21000.0],at:114)
        precondition(state.position==81) // Stale pre-seek position cannot undo the jump.
        state.receive(["elapsedMs":81000.0],at:114)
        precondition(state.position==81)
        state.receive(["trackId":"B","title":"Song A","durationMs":30000.0],at:115)
        precondition(state.artwork==nil && state.position==0 && state.canSeek) // Same title, different identity.
        state.receive(["type":"albumart","trackId":"A","artworkId":7,"dataB64":cover],at:115)
        state.receive(["artworkId":7],at:115)
        precondition(state.artwork==nil) // Late previous-track artwork must not replace current cover.
        state.receive(["type":"albumart","trackId":"B","artworkId":7,"dataB64":Data([4]).base64EncodedString()],at:115)
        precondition(state.artwork==Data([4])) // Transfer IDs can be reused by a new track.
        state.receive(["type":"albumart","trackId":"A","artworkId":7,"dataB64":cover],at:115)
        state.receive(["artworkId":7],at:115)
        precondition(state.artwork==Data([4]))
        state.advance(to:200)
        precondition(state.position==30) // Never exceed duration.
        print("NowPlaying: artwork ordering, delta updates, pause/resume, seek correction and track reset passed")
    }
}
