import Foundation

class Helper: NSObject, HelperProtocol {
    func forceQuit(pid: Int32, withReply reply: @escaping (Bool) -> Void) {
        let result = kill(pid, SIGKILL)
        reply(result == 0)
    }

    func purgeMemory(withReply reply: @escaping (Bool) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
        
        do {
            try process.run()
            process.waitUntilExit()
            reply(process.terminationStatus == 0)
        } catch {
            reply(false)
        }
    }
}
