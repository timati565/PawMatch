import SwiftUI
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var needsOnboarding = false
    
    private let service = SupabaseService.shared
    private var authTask: Task<Void, Never>?
    
    init() {
        authTask = Task {
            for await state in service.client.auth.authStateChanges {
                if state.session != nil {
                    isLoggedIn = true
                    await loadUserProfile()
                } else {
                    isLoggedIn = false
                    currentUser = nil
                    needsOnboarding = false
                }
                isLoading = false
            }
        }
    }
    
    func loadUserProfile() async {
        do {
            let user = try await service.fetchProfile()
            currentUser = user
            needsOnboarding = (user.onboardingAnswers == nil)
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
    
    func refreshProfile() async {
        await loadUserProfile()
    }
    
    func signOut() async {
        try? await service.signOut()
        isLoggedIn = false
        currentUser = nil
    }
}
