import Foundation

@objc(HelperProtocol)
protocol HelperProtocol {
    func forceQuit(pid: Int32, withReply reply: @escaping (Bool) -> Void)
    func purgeMemory(withReply reply: @escaping (Bool) -> Void)
}
