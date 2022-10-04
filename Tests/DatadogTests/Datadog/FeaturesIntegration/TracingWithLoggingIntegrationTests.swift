/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDK

class TracingWithLoggingIntegrationTests: XCTestCase {
    private let core = PassthroughCoreMock()

    func testSendingLogWithOTMessageField() throws {
        core.expectation = expectation(description: "Send log")

        // Given
        let integration = TracingWithLoggingIntegration(core: core, logBuilder: .mockAny())

        // When
        integration.writeLog(
            withSpanContext: .mockWith(traceID: 1, spanID: 2),
            fields: [
                OTLogFields.message: "hello",
                "custom field": 123,
            ],
            date: .mockDecember15th2019At10AMUTC()
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let log: LogEvent = try XCTUnwrap(core.events().last, "It should send log")
        XCTAssertEqual(log.date, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(log.status, .info)
        XCTAssertEqual(log.message, "hello")
        XCTAssertEqual(
            log.attributes.userAttributes as? [String: Int],
            ["custom field": 123]
        )
        XCTAssertEqual(
            log.attributes.internalAttributes as? [String: String],
            [
                "dd.span_id": "2",
                "dd.trace_id": "1"
            ]
        )
    }

    func testWritingLogWithOTErrorField() throws {
        core.expectation = expectation(description: "Send 3 logs")
        core.expectation?.expectedFulfillmentCount = 3

        // Given
        let integration = TracingWithLoggingIntegration(core: core, logBuilder: .mockAny())

        // When
        integration.writeLog(
            withSpanContext: .mockAny(),
            fields: [OTLogFields.event: "error"],
            date: .mockAny()
        )

        integration.writeLog(
            withSpanContext: .mockAny(),
            fields: [OTLogFields.errorKind: "Swift error"],
            date: .mockAny()
        )

        integration.writeLog(
            withSpanContext: .mockAny(),
            fields: [OTLogFields.event: "error", OTLogFields.errorKind: "Swift error"],
            date: .mockAny()
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let logs: [LogEvent] = try XCTUnwrap(core.events())
        XCTAssertEqual(logs.count, 3, "It should send 3 logs")
        logs.forEach { log in
            XCTAssertEqual(log.status, .error)
            XCTAssertEqual(log.message, "Span event")
        }
    }

    func testWritingCustomLogWithoutAnyOTFields() throws {
        core.expectation = expectation(description: "Send log")

        // Given
        let integration = TracingWithLoggingIntegration(core: core, logBuilder: .mockAny())

        // When
        integration.writeLog(
            withSpanContext: .mockWith(traceID: 1, spanID: 2),
            fields: ["custom field": 123],
            date: .mockDecember15th2019At10AMUTC()
        )

        // Then
        waitForExpectations(timeout: 0.5, handler: nil)

        let log: LogEvent = try XCTUnwrap(core.events().last, "It should send log")
        XCTAssertEqual(log.date, .mockDecember15th2019At10AMUTC())
        XCTAssertEqual(log.status, .info)
        XCTAssertEqual(log.message, "Span event", "It should use default message.")
        XCTAssertEqual(
            log.attributes.userAttributes as? [String: Int],
            ["custom field": 123]
        )
        XCTAssertEqual(
            log.attributes.internalAttributes as? [String: String],
            [
                "dd.span_id": "2",
                "dd.trace_id": "1"
            ]
        )
    }
}
