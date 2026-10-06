import Foundation

struct ReconnectBackoff {
    private(set) var attempts=0
    mutating func nextDelay()->Int {
        let delay=[5,10,20,30,60][min(attempts,4)]
        attempts += 1
        return delay
    }
    mutating func reset(){attempts=0}
    static func permitted(enabled:Bool,successfulWirelessSession:Bool)->Bool {
        enabled && successfulWirelessSession
    }
}
