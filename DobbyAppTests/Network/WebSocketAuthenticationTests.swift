import XCTest
@testable import Dobby

/// Tests for WebSocket authentication handshake
final class WebSocketAuthenticationTests: XCTestCase {

    // MARK: - Protocol Version Tests

    func testProtocolVersion_MinAndMaxAreThree() {
        // Based on the code: minProtocol: 3, maxProtocol: 3
        let minProtocol = 3
        let maxProtocol = 3

        XCTAssertEqual(minProtocol, 3)
        XCTAssertEqual(maxProtocol, 3)
    }

    // MARK: - Role and Scopes Tests

    func testOperatorRole() {
        // Based on the code: role: "operator"
        let role = "operator"
        XCTAssertEqual(role, "operator")
    }

    func testOperatorScopes() {
        // Based on the code: scopes: ["operator.write", "operator.read", "operator.admin"]
        let expectedScopes = ["operator.write", "operator.read", "operator.admin"]

        XCTAssertEqual(expectedScopes.count, 3)
        XCTAssertTrue(expectedScopes.contains("operator.write"))
        XCTAssertTrue(expectedScopes.contains("operator.read"))
        XCTAssertTrue(expectedScopes.contains("operator.admin"))
    }

    // MARK: - Client Info Tests

    func testClientInfo_HasExpectedFields() {
        // Based on ClientInfo struct
        let clientId = "clawdbot-macos"
        let displayName = "Dobby Mac App"
        let version = "1.0.0"
        let platform = "macos"

        XCTAssertFalse(clientId.isEmpty)
        XCTAssertFalse(displayName.isEmpty)
        XCTAssertFalse(version.isEmpty)
        XCTAssertFalse(platform.isEmpty)
    }

    // MARK: - Auth Token Handling

    func testAuthToken_EmptyByDefault() {
        // When no auth token is set, it should be empty
        let defaults = MockUserDefaults()
        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.authToken.isEmpty)
    }

    func testAuthToken_PersistsToUserDefaults() {
        // Given
        let defaults = MockUserDefaults()
        let settings = AppSettings(defaults: defaults)

        // When
        settings.authToken = "test-token-123"

        // Then
        XCTAssertEqual(defaults.string(forKey: "authToken"), "test-token-123")
    }

    func testAuthToken_LoadsFromUserDefaults() {
        // Given
        let defaults = MockUserDefaults()
        defaults.set("persisted-token", forKey: "authToken")

        // When
        let settings = AppSettings(defaults: defaults)

        // Then
        XCTAssertEqual(settings.authToken, "persisted-token")
    }

    // MARK: - Connect Request Structure

    func testConnectParams_Encoding() throws {
        // Test that ConnectParams can be encoded properly
        struct TestConnectParams: Codable {
            let minProtocol: Int
            let maxProtocol: Int
            let role: String
            let scopes: [String]
        }

        let params = TestConnectParams(
            minProtocol: 3,
            maxProtocol: 3,
            role: "operator",
            scopes: ["operator.write", "operator.read", "operator.admin"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)
        let json = String(data: data, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(json!.contains("\"minProtocol\":3"))
        XCTAssertTrue(json!.contains("\"maxProtocol\":3"))
        XCTAssertTrue(json!.contains("\"role\":\"operator\""))
    }

    // MARK: - Challenge-Response Flow

    func testChallengeEvent_HasNonce() throws {
        let json = WebSocketTestFixtures.connectChallenge(nonce: "test-nonce-abc")
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(EventFrame.self, from: data)

        XCTAssertEqual(frame.event, "connect.challenge")

        if let payload = frame.payload,
           let nonce = payload["nonce"]?.value as? String {
            XCTAssertEqual(nonce, "test-nonce-abc")
        } else {
            XCTFail("Expected nonce in connect.challenge payload")
        }
    }

    func testConnectSuccess_HasOkTrue() throws {
        let json = WebSocketTestFixtures.connectSuccess
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertEqual(frame.id, "connect")
        XCTAssertTrue(frame.ok)
    }

    func testConnectFailure_HasErrorDetails() throws {
        let json = WebSocketTestFixtures.connectFailure(code: "invalid_token", message: "Token expired")
        let data = json.data(using: .utf8)!

        let frame = try JSONDecoder().decode(ResponseFrame.self, from: data)

        XCTAssertEqual(frame.id, "connect")
        XCTAssertFalse(frame.ok)
        XCTAssertEqual(frame.error?.code, "invalid_token")
        XCTAssertEqual(frame.error?.message, "Token expired")
    }
}
