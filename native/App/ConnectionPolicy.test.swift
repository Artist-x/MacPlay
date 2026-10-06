import Foundation
@main struct ConnectionPolicyTests {
    static func main() {
        var policy=ReconnectBackoff()
        precondition((0..<8).map{_ in policy.nextDelay()} == [5,10,20,30,60,60,60,60])
        policy.reset();precondition(policy.nextDelay()==5)
        precondition(!ReconnectBackoff.permitted(enabled:true,successfulWirelessSession:false))
        precondition(!ReconnectBackoff.permitted(enabled:false,successfulWirelessSession:true))
        precondition(ReconnectBackoff.permitted(enabled:true,successfulWirelessSession:true))
        print("Reconnect: bounded backoff, reset, first-failure and disabled gates passed")
    }
}
