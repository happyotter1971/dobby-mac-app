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

    var body: some View {
        List(selection: $selectedView) {
            Section {
                ForEach(NavigationItem.allCases, id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }

            Section(header: Text("Sessions")) {
                ForEach(sessions) { session in
                    NavigationLink(value: session) {
                        Label(session.name, systemImage: session.icon)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteSession(session)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Dobby")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewSessionSheet = true }) {
                    Label("New Session", systemImage: "plus")
                }
            }
        }
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
