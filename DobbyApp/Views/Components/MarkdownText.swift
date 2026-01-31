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

// MARK: - Content Types for Rich Rendering

enum RichContentBlock: Identifiable {
    case text(String)
    case codeBlock(language: String?, code: String)
    case suggestion(String)
    case sectionCard(title: String, content: [RichContentBlock])
    case styledHeader(String, content: String)

    var id: String {
        switch self {
        case .text(let s): return "text-\(s.prefix(50).hashValue)"
        case .codeBlock(_, let code): return "code-\(code.prefix(50).hashValue)"
        case .suggestion(let s): return "suggestion-\(s.hashValue)"
        case .sectionCard(let title, _): return "section-\(title.hashValue)"
        case .styledHeader(let h, _): return "header-\(h.hashValue)"
        }
    }
}

// MARK: - Rich Markdown Text with Enhanced Rendering

struct RichMarkdownText: View {
    let content: String
    var onSuggestionTapped: ((String) -> Void)?

    private let blocks: [RichContentBlock]

    init(content: String, onSuggestionTapped: ((String) -> Void)? = nil) {
        self.content = content
        self.onSuggestionTapped = onSuggestionTapped
        self.blocks = Self.parseContent(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(blocks) { block in
                renderBlock(block)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: RichContentBlock) -> some View {
        switch block {
        case .text(let text):
            Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code)

        case .suggestion(let suggestion):
            SuggestionChipView(suggestion: suggestion, onTap: onSuggestionTapped)

        case .sectionCard(let title, let content):
            SectionCardView(title: title, content: content, onSuggestionTapped: onSuggestionTapped)

        case .styledHeader(let header, let content):
            StyledHeaderView(header: header, content: content)
        }
    }

    // MARK: - Content Parsing

    private static func parseContent(_ text: String) -> [RichContentBlock] {
        var blocks: [RichContentBlock] = []
        var currentText = ""
        var inCodeBlock = false
        var codeBlockContent = ""
        var codeBlockLanguage: String?

        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]

            // Handle code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    blocks.append(contentsOf: processTextBlock(currentText))
                    currentText = ""
                    blocks.append(.codeBlock(language: codeBlockLanguage, code: codeBlockContent.trimmingCharacters(in: .newlines)))
                    inCodeBlock = false
                    codeBlockContent = ""
                    codeBlockLanguage = nil
                } else {
                    // Start code block
                    blocks.append(contentsOf: processTextBlock(currentText))
                    currentText = ""
                    inCodeBlock = true
                    let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = lang.isEmpty ? nil : lang
                }
                i += 1
                continue
            }

            if inCodeBlock {
                codeBlockContent += (codeBlockContent.isEmpty ? "" : "\n") + line
                i += 1
                continue
            }

            // Check for numbered section start (e.g., "1. As a Strategic...")
            if let sectionMatch = matchNumberedSection(line) {
                blocks.append(contentsOf: processTextBlock(currentText))
                currentText = ""

                // Collect all lines until next numbered section or end
                var sectionContent = ""
                i += 1
                while i < lines.count {
                    let nextLine = lines[i]
                    if matchNumberedSection(nextLine) != nil {
                        break
                    }
                    sectionContent += (sectionContent.isEmpty ? "" : "\n") + nextLine
                    i += 1
                }

                let innerBlocks = processTextBlock(sectionContent)
                blocks.append(.sectionCard(title: sectionMatch, content: innerBlocks))
                continue
            }

            currentText += (currentText.isEmpty ? "" : "\n") + line
            i += 1
        }

        // Handle remaining content
        if inCodeBlock {
            blocks.append(.codeBlock(language: codeBlockLanguage, code: codeBlockContent))
        } else {
            blocks.append(contentsOf: processTextBlock(currentText))
        }

        return blocks.filter { block in
            switch block {
            case .text(let t): return !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            default: return true
            }
        }
    }

    private static func matchNumberedSection(_ line: String) -> String? {
        // Match patterns like "1. As a Strategic Thought Partner" or "2. As a Content & Brand-Building Assistant"
        let pattern = #"^(\d+)\.\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let titleRange = Range(match.range(at: 2), in: line) else {
            return nil
        }
        return String(line[titleRange])
    }

    private static func processTextBlock(_ text: String) -> [RichContentBlock] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var blocks: [RichContentBlock] = []

        // Split by paragraphs first
        let paragraphs = trimmed.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for paragraph in paragraphs {
            // Check for "Try asking:" patterns
            if let suggestion = extractSuggestion(paragraph) {
                blocks.append(.suggestion(suggestion))
                continue
            }

            // Check for styled header pattern (**Header:** content)
            if let (header, content) = extractStyledHeader(paragraph) {
                blocks.append(.styledHeader(header, content: content))
                continue
            }

            // Regular text
            blocks.append(.text(paragraph))
        }

        return blocks
    }

    private static func extractSuggestion(_ text: String) -> String? {
        // Match "Try asking: "..." " or "*Try asking: "..."*"
        let patterns = [
            #"^\*?Try asking:\*?\s*["""](.+?)["""]"#,
            #"^Try asking:\s*["""](.+?)["""]"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let suggestionRange = Range(match.range(at: 1), in: text) {
                return String(text[suggestionRange])
            }
        }
        return nil
    }

    private static func extractStyledHeader(_ text: String) -> (String, String)? {
        // Match **Header:** followed by content
        let pattern = #"^\*\*([^*]+):\*\*\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let headerRange = Range(match.range(at: 1), in: text),
              let contentRange = Range(match.range(at: 2), in: text) else {
            return nil
        }
        return (String(text[headerRange]), String(text[contentRange]))
    }
}

// MARK: - Suggestion Chip View

private struct SuggestionChipView: View {
    let suggestion: String
    let onTap: ((String) -> Void)?
    @State private var isHovered = false

    var body: some View {
        Button(action: { onTap?(suggestion) }) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble")
                    .font(.caption)
                Text(suggestion)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovered ? Color.accentColor.opacity(0.25) : Color.accentColor.opacity(0.15))
            .foregroundColor(.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help("Click to use this suggestion")
    }
}

// MARK: - Section Card View

private struct SectionCardView: View {
    let title: String
    let content: [RichContentBlock]
    let onSuggestionTapped: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Section content
            VStack(alignment: .leading, spacing: 12) {
                ForEach(content) { block in
                    renderBlock(block)
                }
            }
        }
        .padding(16)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor).opacity(0.5), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func renderBlock(_ block: RichContentBlock) -> some View {
        switch block {
        case .text(let text):
            Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code)

        case .suggestion(let suggestion):
            SuggestionChipView(suggestion: suggestion, onTap: onSuggestionTapped)

        case .styledHeader(let header, let content):
            StyledHeaderView(header: header, content: content)

        case .sectionCard(let title, let innerContent):
            // Nested cards - render flat to avoid too much nesting
            NestedSectionView(title: title, content: innerContent, onSuggestionTapped: onSuggestionTapped)
        }
    }
}

// Helper view to break recursive type inference
private struct NestedSectionView: View {
    let title: String
    let content: [RichContentBlock]
    let onSuggestionTapped: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            ForEach(content) { block in
                switch block {
                case .text(let text):
                    Text((try? AttributedString(markdown: text)) ?? AttributedString(text))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                case .codeBlock(let language, let code):
                    CodeBlockView(language: language, code: code)
                case .suggestion(let suggestion):
                    SuggestionChipView(suggestion: suggestion, onTap: onSuggestionTapped)
                case .styledHeader(let header, let content):
                    StyledHeaderView(header: header, content: content)
                case .sectionCard:
                    EmptyView() // Don't support deeply nested sections
                }
            }
        }
    }
}

// MARK: - Styled Header View

private struct StyledHeaderView: View {
    let header: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(header)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accentColor)

            Text((try? AttributedString(markdown: content)) ?? AttributedString(content))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }
}

// MARK: - Code Block View

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
