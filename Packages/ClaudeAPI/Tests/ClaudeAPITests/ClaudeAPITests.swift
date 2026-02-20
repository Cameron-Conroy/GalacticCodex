import XCTest
@testable import ClaudeAPI

// MARK: - Mock URLProtocol

final class MockURLProtocol: URLProtocol {
    static var mockHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.mockHandler else {
            fatalError("MockURLProtocol handler not set")
        }
        do {
            // URLSession strips httpBody in URLProtocol; read from stream instead.
            var req = request
            if req.httpBody == nil, let stream = req.httpBodyStream {
                stream.open()
                let bufferSize = 4096
                var data = Data()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    if read > 0 { data.append(buffer, count: read) }
                    else { break }
                }
                stream.close()
                req.httpBody = data
            }

            let (response, data) = try handler(req)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

final class ClaudeAPITests: XCTestCase {
    private var session: URLSession!
    private var client: ClaudeAPIClient!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        client = ClaudeAPIClient(apiKey: "test-key", session: session)
    }

    override func tearDown() {
        MockURLProtocol.mockHandler = nil
        super.tearDown()
    }

    // MARK: - ChatMessage Encoding

    func testChatMessageEncoding() throws {
        let message = ChatMessage(role: .user, content: "Hello")
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        XCTAssertEqual(decoded.role, .user)
        XCTAssertEqual(decoded.content, "Hello")
    }

    func testChatMessageRoles() throws {
        let user = ChatMessage(role: .user, content: "hi")
        let assistant = ChatMessage(role: .assistant, content: "hello")
        XCTAssertEqual(user.role.rawValue, "user")
        XCTAssertEqual(assistant.role.rawValue, "assistant")
    }

    // MARK: - Request Encoding

    func testRequestEncodesCorrectJSON() async throws {
        MockURLProtocol.mockHandler = { request in
            // Validate request structure
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "test-key")
            XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
            XCTAssertEqual(request.url?.absoluteString, "https://api.anthropic.com/v1/messages")

            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["model"] as? String, "claude-sonnet-4-20250514")
            XCTAssertEqual(body["max_tokens"] as? Int, 4096)
            XCTAssertEqual(body["system"] as? String, "You are helpful")

            let messages = body["messages"] as! [[String: String]]
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0]["role"], "user")
            XCTAssertEqual(messages[0]["content"], "Hello")

            let responseJSON = """
            {"content":[{"type":"text","text":"Hi there!"}],"id":"msg_1","type":"message","role":"assistant","model":"claude-sonnet-4-20250514","stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":5}}
            """
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON.data(using: .utf8)!)
        }

        let result = try await client.sendMessage(
            systemPrompt: "You are helpful",
            messages: [ChatMessage(role: .user, content: "Hello")]
        )
        XCTAssertEqual(result, "Hi there!")
    }

    func testRequestUsesCustomModel() async throws {
        MockURLProtocol.mockHandler = { request in
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["model"] as? String, "claude-opus-4-20250514")

            let responseJSON = #"{"content":[{"type":"text","text":"ok"}],"id":"msg_1","type":"message","role":"assistant","model":"claude-opus-4-20250514","stop_reason":"end_turn","usage":{"input_tokens":1,"output_tokens":1}}"#
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON.data(using: .utf8)!)
        }

        let result = try await client.sendMessage(
            systemPrompt: "test",
            messages: [ChatMessage(role: .user, content: "hi")],
            model: "claude-opus-4-20250514"
        )
        XCTAssertEqual(result, "ok")
    }

    // MARK: - Response Decoding

    func testResponseDecodesValidJSON() async throws {
        MockURLProtocol.mockHandler = { request in
            let responseJSON = #"{"content":[{"type":"text","text":"Decoded correctly"}],"id":"msg_1","type":"message","role":"assistant","model":"x","stop_reason":"end_turn","usage":{"input_tokens":1,"output_tokens":1}}"#
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON.data(using: .utf8)!)
        }

        let result = try await client.sendMessage(
            systemPrompt: "test",
            messages: [ChatMessage(role: .user, content: "test")]
        )
        XCTAssertEqual(result, "Decoded correctly")
    }

    func testEmptyContentBlocksReturnsEmptyString() async throws {
        MockURLProtocol.mockHandler = { request in
            let responseJSON = #"{"content":[],"id":"msg_1","type":"message","role":"assistant","model":"x","stop_reason":"end_turn","usage":{"input_tokens":1,"output_tokens":0}}"#
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, responseJSON.data(using: .utf8)!)
        }

        let result = try await client.sendMessage(
            systemPrompt: "test",
            messages: [ChatMessage(role: .user, content: "test")]
        )
        XCTAssertEqual(result, "")
    }

    // MARK: - Error Handling

    func testHTTP429ThrowsError() async {
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
            return (response, #"{"error":{"type":"rate_limit_error","message":"Rate limited"}}"#.data(using: .utf8)!)
        }

        do {
            _ = try await client.sendMessage(
                systemPrompt: "test",
                messages: [ChatMessage(role: .user, content: "test")]
            )
            XCTFail("Expected error")
        } catch let error as ClaudeAPIError {
            if case .httpError(let code, _) = error {
                XCTAssertEqual(code, 429)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHTTP500ThrowsError() async {
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, "Internal Server Error".data(using: .utf8)!)
        }

        do {
            _ = try await client.sendMessage(
                systemPrompt: "test",
                messages: [ChatMessage(role: .user, content: "test")]
            )
            XCTFail("Expected error")
        } catch let error as ClaudeAPIError {
            if case .httpError(let code, let body) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(body, "Internal Server Error")
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testInvalidJSONThrowsDecodingError() async {
        MockURLProtocol.mockHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json at all".data(using: .utf8)!)
        }

        do {
            _ = try await client.sendMessage(
                systemPrompt: "test",
                messages: [ChatMessage(role: .user, content: "test")]
            )
            XCTFail("Expected error")
        } catch is DecodingError {
            // Expected
        } catch {
            XCTFail("Expected DecodingError, got \(error)")
        }
    }

    // MARK: - Error Description

    func testErrorDescriptions() {
        let invalidResponse = ClaudeAPIError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid response from Claude API")

        let httpError = ClaudeAPIError.httpError(statusCode: 403, body: "Forbidden")
        XCTAssertEqual(httpError.errorDescription, "HTTP 403: Forbidden")
    }
}
