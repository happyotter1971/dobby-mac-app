import SwiftUI
import SwiftData
import AppKit

struct TaskDetailSheet: View {
    @Bindable var task: Task
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var resultCopied = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Task Details")
                    .font(.title2.bold())
                Spacer()
                Button("Done") {
                    task.updatedAt = Date()
                    try? modelContext.save()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Content
            Form {
                // Result section - prominently at the top if available
                if let resultSummary = task.resultSummary {
                    Section {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header with copy button
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                Text("Task Result")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(resultSummary, forType: .string)
                                    resultCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        resultCopied = false
                                    }
                                } label: {
                                    Label(resultCopied ? "Copied!" : "Copy", systemImage: resultCopied ? "checkmark" : "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.bottom, 12)

                            // Scrollable result content
                            ScrollView {
                                RichMarkdownText(content: resultSummary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 250)
                            .padding(12)
                            .background(Color(.textBackgroundColor).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.vertical, 8)
                    }
                }

                Section("Details") {
                    TextField("Title", text: $task.title, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Status", selection: $task.status) {
                        Text("Backlog").tag(TaskStatus.backlog)
                        Text("In Process").tag(TaskStatus.inProcess)
                        Text("Completed").tag(TaskStatus.completed)
                    }

                    Picker("Priority", selection: $task.priority) {
                        HStack {
                            Text("🔴 High")
                        }.tag(TaskPriority.high)
                        HStack {
                            Text("🟠 Medium")
                        }.tag(TaskPriority.medium)
                        HStack {
                            Text("🟢 Low")
                        }.tag(TaskPriority.low)
                    }
                }

                Section("Schedule") {
                    Toggle("Set due date", isOn: Binding(
                        get: { task.dueDate != nil },
                        set: { if $0 { task.dueDate = Date() } else { task.dueDate = nil } }
                    ))

                    if task.dueDate != nil {
                        DatePicker(
                            "Due date",
                            selection: Binding(
                                get: { task.dueDate ?? Date() },
                                set: { task.dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    Toggle("Set reminder", isOn: Binding(
                        get: { task.reminder != nil },
                        set: { if $0 { task.reminder = Date() } else { task.reminder = nil } }
                    ))

                    if task.reminder != nil {
                        DatePicker(
                            "Reminder",
                            selection: Binding(
                                get: { task.reminder ?? Date() },
                                set: { task.reminder = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section("Tags") {
                    TagEditor(tags: $task.tags)
                }

                Section("Notes") {
                    TextEditor(text: Binding(
                        get: { task.notes ?? "" },
                        set: { task.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                    .font(.body)
                }

                Section("Metadata") {
                    LabeledContent("Created", value: task.createdAt, format: .dateTime)
                    LabeledContent("Updated", value: task.updatedAt, format: .dateTime)
                    if let completedAt = task.completedAt {
                        LabeledContent("Completed", value: completedAt, format: .dateTime)
                    }
                    LabeledContent("Source", value: task.source.rawValue.capitalized)
                    if let progress = task.progressPercent {
                        LabeledContent("Progress", value: "\(progress)%")
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 600, height: 700)
    }
}

struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""

    let suggestedTags = ["Work", "Personal", "Urgent", "Bug", "Feature", "Research"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current tags
            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        TagBadge(tag: tag, onDelete: {
                            tags.removeAll { $0 == tag }
                        })
                    }
                }
            }

            // Add new tag
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
                    addTag()
                }
                .disabled(newTag.isEmpty)
            }

            // Suggested tags
            if !suggestedTags.filter({ !tags.contains($0) }).isEmpty {
                Text("Suggestions:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(suggestedTags.filter { !tags.contains($0) }, id: \.self) { tag in
                        Button(action: {
                            tags.append(tag)
                        }) {
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

struct TagBadge: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tagColor.opacity(0.2))
        .foregroundStyle(tagColor)
        .clipShape(Capsule())
    }

    private var tagColor: Color {
        // Simple hash-based color selection
        let hash = abs(tag.hashValue)
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan]
        return colors[hash % colors.count]
    }
}

// Flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}
