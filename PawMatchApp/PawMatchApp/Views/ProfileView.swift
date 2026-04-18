import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditingPreferences = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader

                    if effectiveRole == "adopter" {
                        statsGrid
                        preferencesSection
                    } else {
                        shelterPetsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let userId = authManager.currentUser?.id {
                    if effectiveRole == "adopter" {
                        await viewModel.loadStats(for: userId)
                        await viewModel.loadRating(for: userId)
                    } else {
                        await viewModel.loadShelterPets(for: userId)
                        await viewModel.loadRating(for: userId)
                    }
                }
            }
            .sheet(isPresented: $isEditingPreferences) {
                PreferencesEditView(viewModel: viewModel, authManager: authManager)
            }
        }
    }

    private var profileHeader: some View {
        let user = authManager.currentUser
        let displayName = user?.name ?? user?.email.components(separatedBy: "@").first ?? "Пользователь"
        let email = user?.email ?? ""

        return ZStack {
            Circle()
                .fill(Color.appAccent.opacity(0.1))
                .frame(width: 256, height: 256)
                .blur(radius: 40)
                .offset(x: 100, y: -100)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: effectiveRole == "shelter" ? "building.2.fill" : "person.fill")
                            .font(.largeTitle).foregroundColor(.appAccent))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(effectiveRole == "shelter" ? "АККАУНТ ПРИЮТА" : "АККАУНТ УСЫНОВИТЕЛЯ")
                            .font(.caption).bold().foregroundColor(.appAccent)
                        Text(displayName).font(.title2).bold()
                        Text(email).font(.subheadline).foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                    Button { Task { await authManager.signOut() } } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.appDanger)
                            .frame(width: 44, height: 44)
                            .background(Color.appDanger.opacity(0.1))
                            .clipShape(Circle())
                    }
                }

                if effectiveRole == "shelter" {
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                            Text(String(format: "%.1f", viewModel.rating)).bold()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.white.opacity(0.05)).cornerRadius(20)

                        Text("\(viewModel.reviewsCount) отзывов")
                            .font(.caption).foregroundColor(.appTextSecondary)
                    }
                }
            }
            .padding(20)
            .background(Color.appCard)
            .cornerRadius(32)
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 16) {
            StatCard(icon: "heart.fill", iconColor: .appSuccess, value: "\(viewModel.likesCount)", title: "Симпатий")
            StatCard(icon: "message.fill", iconColor: .appAccent, value: "\(viewModel.matchesCount)", title: "Матчей")
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Настройки подбора", systemImage: "slider.horizontal.3").bold()
                Spacer()
                Button("Изменить") { isEditingPreferences = true }.foregroundColor(.appAccent)
            }
            if let answers = authManager.currentUser?.onboardingAnswers {
                VStack(spacing: 12) {
                    PreferenceRow(title: "Где вы живете?", value: answers.housing == "apartment" ? "В квартире" : "Дом с участком")
                    PreferenceRow(title: "Уровень активности", value: answers.activity == "active" ? "Активно гуляю" : "Домосед")
                    PreferenceRow(title: "Другие животные", value: answers.otherPets == "yes" ? "Да, уже есть" : "Нет, первый")
                }
            } else {
                Text("Настройки не заполнены").foregroundColor(.appTextSecondary)
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(24)
    }

    private var shelterPetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Мои питомцы", systemImage: "pawprint.fill").font(.headline).bold()
            if viewModel.shelterPets.isEmpty {
                Text("Вы ещё не добавили ни одного питомца")
                    .foregroundColor(.appTextSecondary)
                    .padding()
            } else {
                ForEach(viewModel.shelterPets) { pet in
                    NavigationLink(destination: PetDetailView(pet: pet)) {
                        HStack {
                            AsyncImage(url: URL(string: pet.imageUrls?.first ?? "")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading) {
                                Text(pet.name ?? "Без имени").font(.headline)
                                Text(pet.breed ?? "").font(.caption).foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.appTextSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.appCard)
        .cornerRadius(24)
    }

    private var effectiveRole: String {
        authManager.currentUser?.role ?? "adopter"
    }
}

// MARK: - StatCard
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(iconColor)
            Text(value).font(.title).bold()
            Text(title).font(.caption).foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
        .background(Color.appCard).cornerRadius(24)
    }
}

// MARK: - PreferenceRow
struct PreferenceRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundColor(.appTextSecondary)
            Spacer()
            Text(value).bold()
        }
    }
}

// MARK: - PreferencesEditView
struct PreferencesEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var housing = ""
    @State private var activity = ""
    @State private var otherPets = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Жильё") {
                    Picker("Жильё", selection: $housing) {
                        Text("В квартире").tag("apartment")
                        Text("Дом с участком").tag("house_yard")
                    }.pickerStyle(.segmented)
                }
                Section("Активность") {
                    Picker("Активность", selection: $activity) {
                        Text("Активно гуляю").tag("active")
                        Text("Домосед").tag("chill")
                    }.pickerStyle(.segmented)
                }
                Section("Другие животные") {
                    Picker("Другие животные", selection: $otherPets) {
                        Text("Да, уже есть").tag("yes")
                        Text("Нет, первый").tag("no")
                    }.pickerStyle(.segmented)
                }
            }
            .navigationTitle("Изменить настройки")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        Task {
                            let answers = OnboardingAnswers(housing: housing, activity: activity, otherPets: otherPets)
                            try? await SupabaseService.shared.updateOnboardingAnswers(answers)
                            await authManager.refreshProfile()
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if let answers = authManager.currentUser?.onboardingAnswers {
                    housing = answers.housing ?? "apartment"
                    activity = answers.activity ?? "active"
                    otherPets = answers.otherPets ?? "no"
                }
            }
        }
    }
}
