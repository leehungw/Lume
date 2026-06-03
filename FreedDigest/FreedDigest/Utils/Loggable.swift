import Logging

public let appLogger = Logger(label: "")

public extension Logger {
    func recordInfo(tag: String, _ message: String) {
        self.info("[\(tag)] \(message)")
    }

    func recordDebug(tag: String, _ message: String) {
        self.debug("[\(tag)] \(message)")
    }

    func recordWarning(tag: String, _ message: String) {
        self.warning("[\(tag)] \(message)")
    }

    func recordError(tag: String, _ message: String) {
        self.error("[\(tag)] \(message)")
    }
}

protocol Loggable {
    var logTag: String { get }
}

extension Loggable {
    var logTag: String {
        String(describing: Self.self)
    }

    func logInfo(_ message: String) {
        appLogger.recordInfo(tag: logTag, message)
    }

    func logDebug(_ message: String) {
        appLogger.recordDebug(tag: logTag, message)
    }

    func logWarning(_ message: String) {
        appLogger.recordWarning(tag: logTag, message)
    }

    func logError(_ message: String) {
        appLogger.recordError(tag: logTag, message)
    }
}
