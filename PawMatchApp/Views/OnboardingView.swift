import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0
    
    let totalSteps = 3
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Шаг \(currentStep + 1) из \(totalSteps)")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                Spacer()
                ProgressDots(totalSteps: totalSteps, currentStep: currentStep)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            TabView(selection: $currentStep) {
                OnboardingStepView(
                    title: "Где вы живете?",
                    subtitle: "Это поможет подобрать животное с подходящим уровнем энергии.",
                    options: ["В квартире", "Дом с участком"],
                    values: ["apartment", "house_yard"],
                    selected: $viewModel.answers.housing
                ).tag(0)
                
                OnboardingStepView(
                    title: "Ваш уровень активности?",
                    subtitle: "Вы любите гулять часами или предпочитаете сериалы?",
                    options: ["Активно гуляю", "Домосед"],
                    values: ["active", "chill"],
                    selected: $viewModel.answers.activity
                ).tag(1)
                
                OnboardingStepView(
                    title: "Есть ли другие животные?",
                    subtitle: "Важно для определения зооагрессии",
                    options: ["Да, уже есть", "Нет, первый"],
                    values: ["yes", "no"],
                    selected: $viewModel.answers.otherPets
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Button(action: {
                if currentStep < totalSteps - 1 {
                    withAnimation { currentStep += 1 }
                } else {
                    Task { await viewModel.finish(authManager: authManager) }
                }
            }) {
                Text(currentStep == totalSteps - 1 ? "Завершить" : "Далее")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.isStepValid(step: currentStep) ? Color.appAccent : Color.gray.opacity(0.4))
                    .cornerRadius(14)
            }
            .disabled(!viewModel.isStepValid(step: currentStep))
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .padding(.top, 10)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct OnboardingStepView: View {
    let title: String
    let subtitle: String
    let options: [String]
    let values: [String]
    @Binding var selected: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appTextPrimary)
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(0..<options.count, id: \.self) { index in
                    Button(action: { selected = values[index] }) {
                        HStack {
                            Text(options[index])
                                .font(.headline)
                                .foregroundColor(selected == values[index] ? .white : .appTextPrimary)
                            Spacer()
                            if selected == values[index] {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected == values[index] ? Color.appAccent : Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 10)
    }
}
