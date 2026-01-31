import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedView: NavigationItem?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settings: AppSettings
    @Query(sort: \ChatSession.createdAt, order: .forward) private var sessions: [ChatSession]

    @State private var showingNewSessionSheet = false
    @State private var newSessionName = ""
    @State private var newSessionIcon = "bubble.left.fill"
    @State private var isChatExpanded: Bool = true

    var body: some View {
        List(selection: $selectedView) {
            DisclosureGroup(isExpanded: $isChatExpanded) {
                ForEach(sessions) { session in
                    HStack {
                        Text(session.name)
                        Spacer()
                        if session.id.uuidString == settings.activeSessionId {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.activeSessionId = session.id.uuidString
                        selectedView = .chat
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteSession(session)
                        }
                    }
                }
            } label: {
                HStack {
                    Label("Chat", systemImage: "bubble.left.fill")
                    Spacer()
                    Button(action: { showingNewSessionSheet = true }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("New Session")
                }
            }

            ForEach([NavigationItem.tasks, .today, .search, .archived], id: \.self) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Dobby")
        .onAppear(perform: ensureDefaultSession)
        .sheet(isPresented: $showingNewSessionSheet) {
            NewSessionSheet(
                sessionName: $newSessionName,
                sessionIcon: $newSessionIcon,
                onCreate: {
                    createSession()
                    showingNewSessionSheet = false
                },
                onCancel: {
                    showingNewSessionSheet = false
                }
            )
        }
    }
    
    private func ensureDefaultSession() {
        if sessions.isEmpty {
            let mainSession = ChatSession(name: "Main", icon: "bubble.left.fill")
            modelContext.insert(mainSession)
            settings.activeSessionId = mainSession.id.uuidString
        } else if settings.activeSessionId.isEmpty, let firstSession = sessions.first {
            settings.activeSessionId = firstSession.id.uuidString
        }
    }

    private func createSession() {
        let session = ChatSession(
            name: newSessionName.isEmpty ? "New Session" : newSessionName,
            icon: newSessionIcon
        )
        modelContext.insert(session)
        settings.activeSessionId = session.id.uuidString
        newSessionName = ""
        newSessionIcon = "bubble.left.fill"
    }

    private func deleteSession(_ session: ChatSession) {
        guard sessions.count > 1 else { return }

        if settings.activeSessionId == session.id.uuidString {
            if let newActive = sessions.first(where: { $0.id != session.id }) {
                settings.activeSessionId = newActive.id.uuidString
            }
        }
        modelContext.delete(session)
    }
}

struct NewSessionSheet: View {
    @Binding var sessionName: String
    @Binding var sessionIcon: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    let iconOptions = [
        "bubble.left.fill", "star.fill", "briefcase.fill", "house.fill", 
        "person.fill", "folder.fill", "bookmark.fill", "heart.fill", "flag.fill"
    ]

    var body: some View {
        Form {
            Section {
                TextField("Session Name", text: $sessionName)
            }
            
            Section("Icon") {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6)) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title2)
                            .padding(8)
                            .background(sessionIcon == icon ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(4)
                            .onTapGesture { sessionIcon = icon }
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel", action: onCancel).keyboardShortcut(.cancelAction)
                Button("Create", action: onCreate).disabled(sessionName.isEmpty).keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 400)
        .navigationTitle("New Session")
    }
}
