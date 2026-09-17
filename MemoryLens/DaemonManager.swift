import Foundation
import ServiceManagement
import os

class DaemonManager: ObservableObject {
    static let shared = DaemonManager()
    private let logger = Logger(subsystem: "com.memorylens.app", category: "DaemonManager")
    
    @Published var isDaemonRegistered = false
    
    private lazy var connection: NSXPCConnection = {
        let connection = NSXPCConnection(machServiceName: "com.memorylens.app.helper", options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.invalidationHandler = { [weak self] in
            self?.logger.error("XPC Connection Invalidated")
        }
        connection.interruptionHandler = { [weak self] in
            self?.logger.error("XPC Connection Interrupted")
        }
        connection.resume()
        return connection
    }()
    
    func registerDaemon() {
        let service = SMAppService.daemon(plistName: "com.memorylens.app.helper.plist")
        do {
            try service.register()
            logger.info("Daemon registered successfully")
            DispatchQueue.main.async { self.isDaemonRegistered = true }
        } catch {
            logger.error("Failed to register daemon: \(error.localizedDescription)")
            DispatchQueue.main.async { self.isDaemonRegistered = false }
        }
    }
    
    func forceQuit(pid: Int32, completion: @escaping (Bool) -> Void) {
        guard let helper = connection.remoteObjectProxyWithErrorHandler({ error in
            self.logger.error("XPC error: \(error.localizedDescription)")
            completion(false)
        }) as? HelperProtocol else {
            completion(false)
            return
        }
        
        helper.forceQuit(pid: pid) { success in
            completion(success)
        }
    }
    
    func purgeMemory(completion: @escaping (Bool) -> Void) {
        guard let helper = connection.remoteObjectProxyWithErrorHandler({ error in
            self.logger.error("XPC error: \(error.localizedDescription)")
            completion(false)
        }) as? HelperProtocol else {
            completion(false)
            return
        }
        
        helper.purgeMemory { success in
            completion(success)
        }
    }
}
