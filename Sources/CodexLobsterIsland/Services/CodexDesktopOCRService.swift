import AppKit
import Foundation
import Vision

struct CodexDesktopOCRSnapshot: Equatable {
    let lines: [String]
    private let analysis: CodexDesktopConversationAnalysis

    init(lines: [String]) {
        self.lines = lines
        self.analysis = CodexDesktopConversationAnalysis(lines: lines)
    }

    var summary: String? {
        analysis.summary
    }

    var approvalReason: String? {
        analysis.approvalReason
    }

    var hasApprovalPrompt: Bool {
        approvalReason != nil
    }

    var replyReason: String? {
        analysis.replyReason
    }

    var indicatesAwaitingReply: Bool {
        analysis.indicatesAwaitingReply
    }

    var indicatesError: Bool {
        analysis.indicatesError
    }
}

final class CodexDesktopOCRService {
    private let fileManager: FileManager
    private let temporaryDirectoryURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.temporaryDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent("codex-lobster-island", isDirectory: true)
    }

    func captureWindowSnapshot(frame: CGRect) -> CodexDesktopOCRSnapshot? {
        do {
            try fileManager.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        let outputURL = temporaryDirectoryURL.appendingPathComponent("codex-window.png")
        let captureArguments = [
            "-x",
            "-R\(Int(frame.origin.x)),\(Int(frame.origin.y)),\(Int(frame.size.width)),\(Int(frame.size.height))",
            outputURL.path
        ]

        let captureProcess = Process()
        captureProcess.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        captureProcess.arguments = captureArguments
        captureProcess.standardOutput = Pipe()
        captureProcess.standardError = Pipe()

        do {
            try captureProcess.run()
            captureProcess.waitUntilExit()
            guard captureProcess.terminationStatus == 0 else { return nil }
            return recognizeText(at: outputURL)
        } catch {
            return nil
        }
    }

    private func recognizeText(at url: URL) -> CodexDesktopOCRSnapshot? {
        guard let image = NSImage(contentsOf: url) else { return nil }
        var rect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        guard let croppedImage = cropMainConversationArea(from: cgImage) else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: croppedImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        let observations = request.results ?? []
        let sortedLines = observations
            .compactMap { observation -> (CGFloat, String)? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let line = normalize(candidate.string)
                guard shouldKeep(line) else { return nil }
                return (observation.boundingBox.minY, line)
            }
            .sorted { $0.0 > $1.0 }
            .map(\.1)

        let dedupedLines = sortedLines.reduce(into: [String]()) { result, line in
            if result.last != line {
                result.append(line)
            }
        }

        guard !dedupedLines.isEmpty else { return nil }
        return CodexDesktopOCRSnapshot(lines: Array(dedupedLines.suffix(12)).reversed())
    }

    private func cropMainConversationArea(from image: CGImage) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let cropRect = CGRect(
            x: width * 0.22,
            y: height * 0.12,
            width: width * 0.74,
            height: height * 0.74
        )
        return image.cropping(to: cropRect.integral)
    }

    private func normalize(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }

    private func shouldKeep(_ line: String) -> Bool {
        guard line.count >= 2 else { return false }
        let blacklist = [
            "Codex", "File", "Edit", "View", "Window", "Help", "新线程", "技能和应用", "自动化", "设置",
            "提交", "返回", "前进", "终端", "Open in Popout Window"
        ]
        return !blacklist.contains(where: { line == $0 })
    }
}
