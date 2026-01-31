import SwiftUI
import AppKit

struct MarkdownText: View {
    let content: String

    var body: some View {
        Text(markdown: content)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// Keep a more robust version that handles code blocks with copy buttons
struct RichMarkdownText: View {
    let content: String
    private let segments: [MarkdownSegment]

    init(content: String) {
        self.content = content
        self.segments = Self.parseContent(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(segments) { segment in
                switch segment.type {
                case .text:
                    Text(markdown: segment.text)
                        .textSelection(.enabled)
                case .code(let language):
                    CodeBlockView(language: language, code: segment.text)
                }
            }
        }
    }

    private static func parseContent(_ text: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        let pattern = "```(.*?)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else {
            return [.init(type: .text, text: text)]
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        var lastEnd = text.startIndex
        for match in matches {
            if let textRange = Range(match.range(at: 0), in: text) {
                // Add text before the code block
                if textRange.lowerBound > lastEnd {
                    let textSegment = String(text[lastEnd..<textRange.lowerBound])
                    if !textSegment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        segments.append(.init(type: .text, text: textSegment))
                    }
                }

                // Add the code block
                let langRange = Range(match.range(at: 1), in: text)
                let codeRange = Range(match.range(at: 2), in: text)
                let language = langRange.map { String(text[$0]) } ?? ""
                let code = codeRange.map { String(text[$0]) } ?? ""
                segments.append(.init(type: .code(language: language.isEmpty ? nil : language), text: code))

                lastEnd = textRange.upperBound
            }
        }

        // Add any remaining text after the last code block
        if lastEnd < text.endIndex {
            let remainingText = String(text[lastEnd...])
            if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(.init(type: .text, text: remainingText))
            }
        }
        
        // If no matches, it's all text
        if segments.isEmpty {
            segments.append(.init(type: .text, text: text))
        }

        return segments
    }
}

private struct CodeBlockView: View {
    let language: String?
    let code: String
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language ?? "code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.windowBackgroundColor))

            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        .onHover { self.isHovered = $0 }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }
}

private struct MarkdownSegment: Identifiable {
    let id = UUID()
    let type: SegmentType
    let text: String
}

private enum SegmentType {
    case text
    case code(language: String?)
}
