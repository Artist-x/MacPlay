import Foundation
import Darwin

// Metadata has its own socket: large artwork must never share a byte stream
// with receiver stdout/stderr. Read and deliver all deltas in FIFO order.
struct MediaJSONLines {
    private var pending = Data()
    mutating func append(_ data:Data) -> [[String:Any]] {
        pending.append(data)
        var events:[[String:Any]]=[]
        while let end=pending.firstIndex(of:0x0a) {
            if let event=(try? JSONSerialization.jsonObject(with:pending[..<end])) as? [String:Any] {events.append(event)}
            pending.removeSubrange(...end)
        }
        if pending.count>12*1024*1024 {pending.removeAll()}
        return events
    }
}

@MainActor final class NowPlayingFeed {
    private var source:DispatchSourceRead?
    private var retry:Timer?
    private var lines=MediaJSONLines()
    private var stopped=false
    private let phone:String
    private let receive:([String:Any])->Void
    init(phone:String,receive:@escaping ([String:Any])->Void) {
        self.phone=phone.replacingOccurrences(of:"-",with:":").lowercased()
        self.receive=receive
    }
    func start() {
        guard !stopped,source==nil else {return}
        let fd=socket(AF_UNIX,SOCK_STREAM,0)
        guard fd>=0 else {scheduleRetry();return}
        var address=sockaddr_un()
        address.sun_family=sa_family_t(AF_UNIX)
        let path=Array("/tmp/cp-bt.sock".utf8)+[0]
        withUnsafeMutableBytes(of:&address.sun_path) { bytes in bytes.copyBytes(from:path) }
        address.sun_len=UInt8(MemoryLayout<sockaddr_un>.size)
        let result=withUnsafePointer(to:&address) { pointer in
            pointer.withMemoryRebound(to:sockaddr.self,capacity:1) {connect(fd,$0,socklen_t(MemoryLayout<sockaddr_un>.size))}
        }
        guard result==0 else {close(fd);scheduleRetry();return}
        var noSignal:Int32=1
        setsockopt(fd,SOL_SOCKET,SO_NOSIGPIPE,&noSignal,socklen_t(MemoryLayout<Int32>.size))
        let request=Array("subscribe\n".utf8)
        let sent=request.withUnsafeBytes {write(fd,$0.baseAddress,request.count)}
        guard sent==request.count else {close(fd);scheduleRetry();return}
        guard fcntl(fd,F_SETFL,fcntl(fd,F_GETFL)|O_NONBLOCK)==0 else {close(fd);scheduleRetry();return}
        lines=MediaJSONLines()
        let reader=DispatchSource.makeReadSource(fileDescriptor:fd,queue:.main)
        reader.setEventHandler { [weak self] in self?.readAvailable(fd) }
        reader.setCancelHandler {close(fd)}
        source=reader;reader.resume()
    }
    private func readAvailable(_ fd:Int32) {
        var buffer=[UInt8](repeating:0,count:65536)
        // Bound each turn so a large cover does not monopolize the UI queue.
        for _ in 0..<32 {
            let count=read(fd,&buffer,buffer.count)
            if count<0 && errno==EINTR {continue}
            if count<0 && (errno==EAGAIN || errno==EWOULDBLOCK) {return}
            guard count>0 else {source?.cancel();source=nil;scheduleRetry();return}
            for event in lines.append(Data(buffer.prefix(count))) {
                guard let kind=event["type"] as? String,["nowplaying","albumart","seekResult"].contains(kind) else {continue}
                if let peer=event["phoneId"] as? String,peer.replacingOccurrences(of:"-",with:":").lowercased() != phone {continue}
                receive(event)
            }
        }
    }
    private func scheduleRetry() {
        guard !stopped,retry==nil else {return}
        retry=Timer.scheduledTimer(withTimeInterval:1,repeats:false) { [weak self] _ in
            MainActor.assumeIsolated {self?.retry=nil;self?.start()}
        }
    }
    func stop() {stopped=true;retry?.invalidate();retry=nil;source?.cancel();source=nil}
}
