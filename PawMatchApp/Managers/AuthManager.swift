import SwiftUI
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = true
    @Published var needsOnboarding: Bool = false

    private let service = SupabaseService.shared
    private var authStateTask: Task<Void, Never>?

    init() {
        authStateTask = Task {
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
            if user.role == "adopter" && user.onboardingAnswers == nil {
                needsOnboarding = true
            } else {
                needsOnboarding = false
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    func refreshProfile() async {
        await loadUserProfile()
    }

    func signOut() async {
        do {
            try await service.signOut()
            isLoggedIn = false
            currentUser = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}
