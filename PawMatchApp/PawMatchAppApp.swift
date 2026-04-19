import SwiftUI
import UserNotifications

extension Notification.Name {
    static let switchToMessagesTab = Notification.Name("switchToMessagesTab")
    static let shelterRatingUpdated = Notification.Name("shelterRatingUpdated")
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

@main
struct PawMatchApp: App {
    @StateObject private var authManager = AuthManager()
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if authManager.isLoading {
            ProgressView()
                .tint(.appAccent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
        } else if authManager.isLoggedIn {
            if authManager.needsOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        } else {
            NavigationStack {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var matchToOpen: Match?

    var body: some View {
        TabView(selection: $selectedTab) {
            if authManager.currentUser?.role == "adopter" {
                HomeView()
                    .tabItem { Label("Главная", systemImage: "flame.fill") }
                    .tag(0)
            }
            if authManager.currentUser?.role == "shelter" {
                AddPetView()
                    .tabItem { Label("Добавить", systemImage: "plus.circle.fill") }
                    .tag(1)
            }
            MessagesView(matchToOpen: $matchToOpen)
                .tabItem { Label("Чаты", systemImage: "message.fill") }
                .tag(2)
            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.fill") }
                .tag(3)
        }
        .accentColor(.appAccent)
        .onReceive(NotificationCenter.default.publisher(for: .switchToMessagesTab)) { notif in
            if let match = notif.object as? Match {
                matchToOpen = match
                selectedTab = 2
            }
        }
    }
    
}
