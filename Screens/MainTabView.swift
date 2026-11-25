import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. ГЛОБАЛЬНЫЙ ФОН (САМЫЙ НИЖНИЙ СЛОЙ)
            MeshBackground()
                .ignoresSafeArea()
            
            // 2. КОНТЕНТ (КАЛЕНДАРЬ / КЛИЕНТЫ)
            Group {
                if selectedTab == 0 {
                    CalendarScreen()
                } else {
                    ClientsScreen()
                }
            }
            .ignoresSafeArea(edges: .bottom) // Растягиваем на весь низ
            
            // 3. ТАББАР
            HStack(spacing: 0) {
                TabBarButton(icon: "calendar", title: "Календарь", isSelected: selectedTab == 0) {
                    withAnimation(.snappy) { selectedTab = 0 }
                }
                TabBarButton(icon: "person.2.fill", title: "Клиенты", isSelected: selectedTab == 1) {
                    withAnimation(.snappy) { selectedTab = 1 }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            }
            .overlay {
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .padding(.bottom, 12) // Отступ от самого низа
        }
    }
}

// Кнопка таббара
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
