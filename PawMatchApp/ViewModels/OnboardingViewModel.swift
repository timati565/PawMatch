import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var answers = OnboardingAnswers()
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let service = SupabaseService.shared
    
    func isStepValid(step: Int) -> Bool {
        switch step {
        case 0: return answers.housing != nil
        case 1: return answers.activity != nil
        case 2: return answers.otherPets != nil
        default: return false
        }
    }
    
    func finish(authManager: AuthManager) async {
        isLoading = true
        do {
            try await service.updateOnboardingAnswers(answers)
            await authManager.refreshProfile()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}
