import Foundation

@main
struct VerifyStateSounds {
    static func main() throws {
        guard CodexState.idle.soundResourceName == nil else {
            throw VerificationError("Expected idle state to stay silent by default")
        }

        guard CodexState.running.soundResourceName == nil else {
            throw VerificationError("Expected running state to stay silent by default")
        }

        guard CodexState.success.soundResourceName == "success" else {
            throw VerificationError("Expected success state to map to success.wav")
        }

        guard CodexState.error.soundResourceName == "error" else {
            throw VerificationError("Expected error state to map to error.wav")
        }

        print("state sound verification passed")
    }
}

private struct VerificationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
