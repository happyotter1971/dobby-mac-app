import Foundation
@testable import Dobby

/// Mock UserDefaults for testing AppSettings without persisting to disk
/// Uses in-memory storage instead of actual UserDefaults
final class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    /// Initialize with a unique suite name to avoid conflicts
    init(suiteName: String = "MockUserDefaults-\(UUID().uuidString)") {
        super.init(suiteName: suiteName)!
        // Clear any persisted data from previous test runs
        removePersistentDomain(forName: suiteName)
    }

    // MARK: - Setters

    override func set(_ value: Bool, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func set(_ value: Int, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func set(_ value: Double, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        if let value = value {
            storage[defaultName] = value
        } else {
            storage.removeValue(forKey: defaultName)
        }
    }

    override func set(_ url: URL?, forKey defaultName: String) {
        storage[defaultName] = url
    }

    // MARK: - Getters

    override func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    override func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    override func double(forKey defaultName: String) -> Double {
        storage[defaultName] as? Double ?? 0.0
    }

    override func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func url(forKey defaultName: String) -> URL? {
        storage[defaultName] as? URL
    }

    override func array(forKey defaultName: String) -> [Any]? {
        storage[defaultName] as? [Any]
    }

    override func dictionary(forKey defaultName: String) -> [String: Any]? {
        storage[defaultName] as? [String: Any]
    }

    override func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    // MARK: - Removal

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    // MARK: - Test Helpers

    /// Get all stored values
    var allValues: [String: Any] {
        storage
    }

    /// Check if a key exists
    func hasValue(forKey key: String) -> Bool {
        storage[key] != nil
    }

    /// Clear all stored values
    func reset() {
        storage.removeAll()
    }

    /// Pre-populate with values for testing
    func populate(with values: [String: Any]) {
        for (key, value) in values {
            storage[key] = value
        }
    }
}
