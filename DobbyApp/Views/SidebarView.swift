import SwiftUI

struct SidebarView: View {
    @Binding var selectedView: NavigationItem?
    
    var body: some View {
        List(selection: $selectedView) {
            Section {
                ForEach(NavigationItem.allCases, id: \.self) { item in
                    NavigationLink(value: item) {
                        Label(item.rawValue, systemImage: item.icon)
                    }
                }
            }
            
            Section("Sessions") {
                Text("Main")
                Text("Research")
                Text("Strategy")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Dobby")
    }
}
