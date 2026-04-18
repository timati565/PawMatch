import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLogin = true
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var selectedRole: UserRole = .adopter
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let service = SupabaseService.shared

    enum UserRole: String {
        case adopter = "adopter"
        case shelter = "shelter"
    }

    func submit(authManager: AuthManager) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните все поля"
            showError = true
            return
        }
        if !isLogin && name.isEmpty {
            errorMessage = "Введите имя"
            showError = true
            return
        }

        isLoading = true
        do {
            if isLogin {
                try await service.signIn(email: email, password: password)
            } else {
                try await service.signUp(email: email, password: password, name: name, role: selectedRole.rawValue)
            }
            await authManager.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}
