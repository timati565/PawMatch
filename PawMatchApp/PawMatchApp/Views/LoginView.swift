import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                        .font(.title)
                        .foregroundColor(.appAccent)
                    Text("PawMatch")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.appAccent)
                }

                Text(viewModel.isLogin ? "И снова здравствуйте!" : "Создайте аккаунт, чтобы найти друга")
                    .foregroundColor(.appTextSecondary)
                    .font(.subheadline)

                if !viewModel.isLogin {
                    HStack(spacing: 12) {
                        RoleButton(title: "Я ищу питомца", isSelected: viewModel.selectedRole == .adopter) {
                            viewModel.selectedRole = .adopter
                        }
                        RoleButton(title: "Я приют", isSelected: viewModel.selectedRole == .shelter) {
                            viewModel.selectedRole = .shelter
                        }
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ИМЯ")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        CustomTextField(placeholder: "Как к вам обращаться?", text: $viewModel.name)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("EMAIL")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    CustomTextField(placeholder: "hello@pawmatch.com", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("ПАРОЛЬ")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    CustomTextField(placeholder: "••••••••", text: $viewModel.password, isSecure: true)
                }

                Button {
                    Task { await viewModel.submit(authManager: authManager) }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appAccent)
                            .frame(height: 56)
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(viewModel.isLogin ? "Войти" : "Зарегистрироваться")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.isLoading)

                Button {
                    viewModel.isLogin.toggle()
                } label: {
                    Text(viewModel.isLogin ? "Нет аккаунта? Создать" : "Уже есть аккаунт? Войти")
                        .font(.footnote)
                        .foregroundColor(.appAccent)
                }
            }
            .padding(.horizontal, 20)
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

struct RoleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.appAccent : Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}
