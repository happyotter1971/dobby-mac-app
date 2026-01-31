import SwiftUI
import AppKit

struct MarkdownText: View {
    let content: String

    var body: some View {
        Text((try? AttributedString(markdown: preprocessMarkdown(content))) ?? AttributedString(content))
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func preprocessMarkdown(_ text: String) -> String {
        // Convert single newlines to hard line breaks (two spaces + newline)
        // but preserve double newlines as paragraph breaks
        var result = text
        // First, protect double newlines
        result = result.replacingOccurrences(of: "\n\n", with: "{{PARA}}")
        // Convert single newlines to hard breaks
        result = result.replacingOccurrences(of: "\n", with: "  \n")
        // Restore paragraph breaks
        result = result.replacingOccurrences(of: "{{PARA}}", with: "\n\n")
        return result
    }
}

// Keep a more robust version that handles code blocks with copy buttons
struct RichMarkdownText: View {
    let content: String
    private let paragraphs: [String]

    init(content: String) {
        self.content = content
        self.paragraphs = Self.parseIntoParagraphs(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                if paragraph.hasPrefix("```") {
                    // Code block
                    let parts = Self.parseCodeBlock(paragraph)
                    CodeBlockView(language: parts.language, code: parts.code)
                } else {
                    // Regular text paragraph
                    Text((try? AttributedString(markdown: paragraph)) ?? AttributedString(paragraph))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
            }
        }
    }

    private static func parseIntoParagraphs(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inCodeBlock = false

        let lines = text.components(separatedBy: "\n")

        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    current += line
                    result.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                    inCodeBlock = false
                } else {
                    // Start of code block - save any pending text first
                    if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        result.append(contentsOf: splitTextIntoParagraphs(current))
                    }
                    current = line + "\n"
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                current += line + "\n"
            } else {
                current += line + "\n"
            }
        }

        // Handle remaining content
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if inCodeBlock {
                result.append(current)
            } else {
                result.append(contentsOf: splitTextIntoParagraphs(current))
            }
        }

        return result.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func splitTextIntoParagraphs(_ text: String) -> [String] {
        // Split on double newlines first
        var paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Further split paragraphs that have bold headers (e.g., "**Header:** content")
        var result: [String] = []
        for para in paragraphs {
            let split = splitOnBoldHeaders(para)
            result.append(contentsOf: split)
        }

        return result
    }

    private static func splitOnBoldHeaders(_ text: String) -> [String] {
        // Pattern: **Bold Header:** followed by content
        // Split these into separate paragraphs for better readability
        let pattern = #"(\*\*[^*]+:\*\*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [text]
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)

        if matches.isEmpty {
            return [text]
        }

        var result: [String] = []
        var lastEnd = text.startIndex

        for match in matches {
            guard let matchRange = Range(match.range, in: text) else { continue }

            // Add text before this header (if any)
            if matchRange.lowerBound > lastEnd {
                let beforeText = String(text[lastEnd..<matchRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !beforeText.isEmpty {
                    result.append(beforeText)
                }
            }

            lastEnd = matchRange.lowerBound
        }

        // Add remaining text (includes the headers and their content)
        if lastEnd < text.endIndex {
            let remaining = String(text[lastEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty {
                // Split by bold headers but keep header with its content
                let headerPattern = #"(\*\*[^*]+:\*\*\s*)"#
                if let headerRegex = try? NSRegularExpression(pattern: headerPattern) {
                    let parts = headerRegex.stringByReplacingMatches(
                        in: remaining,
                        range: NSRange(remaining.startIndex..., in: remaining),
                        withTemplate: "\n\n$1"
                    )
                    let splitParts = parts.components(separatedBy: "\n\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    result.append(contentsOf: splitParts)
                } else {
                    result.append(remaining)
                }
            }
        }

        return result.isEmpty ? [text] : result
    }

    private static func parseCodeBlock(_ block: String) -> (language: String?, code: String) {
        let lines = block.components(separatedBy: "\n")
        guard lines.count >= 2 else { return (nil, block) }

        let firstLine = lines[0]
        let language = firstLine.dropFirst(3).trimmingCharacters(in: .whitespaces)

        var codeLines = Array(lines.dropFirst())
        if codeLines.last?.hasPrefix("```") == true {
            codeLines = Array(codeLines.dropLast())
        }

        return (language.isEmpty ? nil : language, codeLines.joined(separator: "\n"))
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

