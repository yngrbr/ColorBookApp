import SwiftUI
import SwiftData

struct ClientsScreen: View {
    @Query(sort: \Client.name) private var clients: [Client]
    @State private var searchText = ""
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.phone.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ФОН
                MeshBackground()
                
                if clients.isEmpty {
                    ContentUnavailableView("Нет клиентов", systemImage: "person.2.slash", description: Text("Добавьте первую запись, чтобы создать базу клиентов"))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredClients) { client in
                                NavigationLink(destination: ClientDetailView(client: client)) {
                                    HStack(spacing: 16) {
                                        // АВАТАРКА (ПЕРВАЯ БУКВА ИМЕНИ)
                                        ZStack {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .frame(width: 50, height: 50)
                                            
                                            Text(String(client.name.prefix(1)).uppercased())
                                                .font(.system(.title3, design: .rounded).weight(.bold))
                                                .foregroundStyle(.blue)
                                        }
                                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(client.name)
                                                .font(.system(.headline, design: .rounded).weight(.bold))
                                                .foregroundStyle(.primary)
                                            
                                            if !client.phone.isEmpty {
                                                Text(client.phone)
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary.opacity(0.5))
                                    }
                                    .padding(16)
                                    // СТЕКЛЯННЫЙ ФОН КАРТОЧКИ
                                    .background {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                                    }
                                    // ГРАДИЕНТНАЯ ОБВОДКА
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Клиенты")
            .searchable(text: $searchText, prompt: "Поиск по имени или телефону")
        }
    }
}
