import Foundation
import CodexLobsterIsland

@main
struct CodexLobsterIslandVerify {
    static func main() throws {
        let line = #"{"state":"running","title":"Build project","detail":"Compiling sources","timestamp":"2026-03-30T08:15:30Z"}"#
        let event = try CodexLogEventParser().parse(line: line)

        guard event.state == .running else {
            throw VerificationError("Expected running state")
        }
        guard event.title == "Build project" else {
            throw VerificationError("Expected title to round-trip")
        }
        guard event.detail == "Compiling sources" else {
            throw VerificationError("Expected detail to round-trip")
        }

        print("verification passed")
    }
}

private struct VerificationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
