import XCTest
@testable import Dobby

/// Tests for AppSettings persistence and defaults
final class AppSettingsTests: XCTestCase {

    var mockDefaults: MockUserDefaults!
    var settings: AppSettings!

    override func setUp() {
        super.setUp()
        mockDefaults = MockUserDefaults()
    }

    override func tearDown() {
        mockDefaults = nil
        settings = nil
        super.tearDown()
    }

    // MARK: - Default Values Tests

    func testAppSettings_DefaultIsDarkMode() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertFalse(settings.isDarkMode)
    }

    func testAppSettings_DefaultNotificationsEnabled() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertTrue(settings.notificationsEnabled)
    }

    func testAppSettings_DefaultAutoCreateTasks() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertTrue(settings.autoCreateTasks)
    }

    func testAppSettings_DefaultSyncToTelegram() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertFalse(settings.syncToTelegram)
    }

    func testAppSettings_DefaultActiveSessionId() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertEqual(settings.activeSessionId, "")
    }

    func testAppSettings_DefaultAuthToken() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertEqual(settings.authToken, "")
    }

    func testAppSettings_DefaultTaskArchiveDays() {
        settings = AppSettings(defaults: mockDefaults)
        XCTAssertEqual(settings.taskArchiveDays, 30)
    }

    // MARK: - Persistence Tests

    func testAppSettings_PersistsIsDarkMode() {
        settings = AppSettings(defaults: mockDefaults)

        settings.isDarkMode = true

        XCTAssertTrue(mockDefaults.bool(forKey: "isDarkMode"))
    }

    func testAppSettings_PersistsNotificationsEnabled() {
        settings = AppSettings(defaults: mockDefaults)

        settings.notificationsEnabled = false

        XCTAssertFalse(mockDefaults.bool(forKey: "notificationsEnabled"))
    }

    func testAppSettings_PersistsAutoCreateTasks() {
        settings = AppSettings(defaults: mockDefaults)

        settings.autoCreateTasks = false

        XCTAssertFalse(mockDefaults.bool(forKey: "autoCreateTasks"))
    }

    func testAppSettings_PersistsSyncToTelegram() {
        settings = AppSettings(defaults: mockDefaults)

        settings.syncToTelegram = true

        XCTAssertTrue(mockDefaults.bool(forKey: "syncToTelegram"))
    }

    func testAppSettings_PersistsActiveSessionId() {
        settings = AppSettings(defaults: mockDefaults)

        settings.activeSessionId = "session-123"

        XCTAssertEqual(mockDefaults.string(forKey: "activeSessionId"), "session-123")
    }

    func testAppSettings_PersistsAuthToken() {
        settings = AppSettings(defaults: mockDefaults)

        settings.authToken = "my-secret-token"

        XCTAssertEqual(mockDefaults.string(forKey: "authToken"), "my-secret-token")
    }

    func testAppSettings_PersistsTaskArchiveDays() {
        settings = AppSettings(defaults: mockDefaults)

        settings.taskArchiveDays = 60

        XCTAssertEqual(mockDefaults.integer(forKey: "taskArchiveDays"), 60)
    }

    // MARK: - Load from UserDefaults Tests

    func testAppSettings_LoadsIsDarkMode() {
        mockDefaults.set(true, forKey: "isDarkMode")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertTrue(settings.isDarkMode)
    }

    func testAppSettings_LoadsNotificationsEnabled() {
        mockDefaults.set(false, forKey: "notificationsEnabled")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertFalse(settings.notificationsEnabled)
    }

    func testAppSettings_LoadsAutoCreateTasks() {
        mockDefaults.set(false, forKey: "autoCreateTasks")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertFalse(settings.autoCreateTasks)
    }

    func testAppSettings_LoadsSyncToTelegram() {
        mockDefaults.set(true, forKey: "syncToTelegram")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertTrue(settings.syncToTelegram)
    }

    func testAppSettings_LoadsActiveSessionId() {
        mockDefaults.set("loaded-session", forKey: "activeSessionId")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertEqual(settings.activeSessionId, "loaded-session")
    }

    func testAppSettings_LoadsAuthToken() {
        mockDefaults.set("loaded-token", forKey: "authToken")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertEqual(settings.authToken, "loaded-token")
    }

    func testAppSettings_LoadsTaskArchiveDays() {
        mockDefaults.set(45, forKey: "taskArchiveDays")

        settings = AppSettings(defaults: mockDefaults)

        XCTAssertEqual(settings.taskArchiveDays, 45)
    }

    // MARK: - Round Trip Tests

    func testAppSettings_RoundTrip_AllSettings() {
        // Set values
        mockDefaults.set(true, forKey: "isDarkMode")
        mockDefaults.set(false, forKey: "notificationsEnabled")
        mockDefaults.set(false, forKey: "autoCreateTasks")
        mockDefaults.set(true, forKey: "syncToTelegram")
        mockDefaults.set("session-abc", forKey: "activeSessionId")
        mockDefaults.set("token-xyz", forKey: "authToken")
        mockDefaults.set(90, forKey: "taskArchiveDays")

        // Load settings
        settings = AppSettings(defaults: mockDefaults)

        // Verify all loaded correctly
        XCTAssertTrue(settings.isDarkMode)
        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertFalse(settings.autoCreateTasks)
        XCTAssertTrue(settings.syncToTelegram)
        XCTAssertEqual(settings.activeSessionId, "session-abc")
        XCTAssertEqual(settings.authToken, "token-xyz")
        XCTAssertEqual(settings.taskArchiveDays, 90)
    }

    func testAppSettings_ModifyAndVerify() {
        settings = AppSettings(defaults: mockDefaults)

        // Modify all settings
        settings.isDarkMode = true
        settings.notificationsEnabled = false
        settings.autoCreateTasks = false
        settings.syncToTelegram = true
        settings.activeSessionId = "modified-session"
        settings.authToken = "modified-token"
        settings.taskArchiveDays = 7

        // Verify all persisted
        XCTAssertTrue(mockDefaults.bool(forKey: "isDarkMode"))
        XCTAssertFalse(mockDefaults.bool(forKey: "notificationsEnabled"))
        XCTAssertFalse(mockDefaults.bool(forKey: "autoCreateTasks"))
        XCTAssertTrue(mockDefaults.bool(forKey: "syncToTelegram"))
        XCTAssertEqual(mockDefaults.string(forKey: "activeSessionId"), "modified-session")
        XCTAssertEqual(mockDefaults.string(forKey: "authToken"), "modified-token")
        XCTAssertEqual(mockDefaults.integer(forKey: "taskArchiveDays"), 7)
    }

    // MARK: - Edge Cases

    func testAppSettings_EmptyAuthToken() {
        settings = AppSettings(defaults: mockDefaults)

        settings.authToken = ""

        XCTAssertEqual(settings.authToken, "")
        XCTAssertEqual(mockDefaults.string(forKey: "authToken"), "")
    }

    func testAppSettings_ZeroTaskArchiveDays() {
        settings = AppSettings(defaults: mockDefaults)

        settings.taskArchiveDays = 0

        XCTAssertEqual(settings.taskArchiveDays, 0)
        XCTAssertEqual(mockDefaults.integer(forKey: "taskArchiveDays"), 0)
    }

    func testAppSettings_NegativeTaskArchiveDays() {
        // The model doesn't prevent negative values, but we can test the behavior
        settings = AppSettings(defaults: mockDefaults)

        settings.taskArchiveDays = -1

        XCTAssertEqual(settings.taskArchiveDays, -1)
    }
}
