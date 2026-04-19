import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedFilter = "Все"
    let filterOptions = ["Все", "Собаки", "Кошки", "Попугаи", "Грызуны", "Рептилии"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    HStack {
                        Text("PawMatch")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appAccent)
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle")
                                .font(.title)
                                .foregroundColor(.appTextPrimary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filterOptions, id: \.self) { option in
                                Button(option) {
                                    selectedFilter = option
                                    viewModel.filterPets(by: option)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedFilter == option ? Color.appAccent : Color.appCard)
                                .foregroundColor(selectedFilter == option ? .white : .appTextPrimary)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 8)
                    .background(Color.appBackground)
                    .zIndex(1)
                    
                    
                    ZStack {
                        if viewModel.filteredPets.isEmpty && !viewModel.isLoading {
                            emptyStateView
                        } else if viewModel.isLoading && viewModel.filteredPets.isEmpty {
                            ProgressView("Загружаем питомцев...")
                                .tint(.appAccent)
                        } else {
                            ForEach(viewModel.filteredPets.reversed()) { pet in
                                SwipeCardView(pet: pet) { liked in
                                    viewModel.handleSwipe(pet: pet, liked: liked)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    
                    HStack(spacing: 20) {
                        Button(action: { viewModel.skipCurrent() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.appDanger)
                                .frame(width: 60, height: 60)
                                .background(Color.appCard)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8)
                        }
                        
                        Button(action: { viewModel.showSponsorSheet = true }) {
                            Text("Спонсировать")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .frame(height: 50)
                                .background(Color.appAccent)
                                .cornerRadius(25)
                        }
                        .disabled(viewModel.filteredPets.isEmpty)
                        
                        Button(action: { viewModel.likeCurrent() }) {
                            Image(systemName: "heart.fill")
                                .font(.title2)
                                .foregroundColor(.appAccent)
                                .frame(width: 60, height: 60)
                                .background(Color.appCard)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 8)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .task {
                viewModel.authManager = authManager
                await viewModel.loadFeed()
            }
            .alert("Ошибка", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Это мэтч! 🎉", isPresented: $viewModel.showMatchAlert) {
                Button("Перейти в чат") {
                    if let match = viewModel.createdMatch {
                        NotificationCenter.default.post(name: .switchToMessagesTab, object: match)
                    }
                }
                Button("Продолжить", role: .cancel) { }
            } message: {
                if let pet = viewModel.matchedPet {
                    Text("Вы лайкнули \(pet.name ?? "питомца"). Теперь вы можете начать чат с приютом!")
                }
            }
            .sheet(isPresented: $viewModel.showSponsorSheet) {
                if let pet = viewModel.filteredPets.first {
                    SponsorView(pet: pet, viewModel: viewModel)
                }
            }
        }
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint")
                .font(.system(size: 50))
                .foregroundColor(.appTextSecondary.opacity(0.5))
            Text("Пока нет новых питомцев")
                .foregroundColor(.appTextSecondary)
            Button("Обновить") {
                Task { await viewModel.loadFeed() }
            }
            .foregroundColor(.appAccent)
        }
    }
}
struct PhotoCarouselView: View {
    let imageUrls: [String]
    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                TabView(selection: $currentIndex) {
                    ForEach(imageUrls.indices, id: \.self) { idx in
                        AsyncImage(url: URL(string: imageUrls[idx])) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                
                if imageUrls.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(imageUrls.indices, id: \.self) { idx in
                            Circle()
                                .fill(idx == currentIndex ? Color.appAccent : Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(8)
                }
            }
        }
        .frame(height: 420)
    }
}

struct SwipeCardView: View {
    let pet: Pet
    let onSwipe: (Bool) -> Void
    
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var isRemoved = false
    @State private var currentImageIndex = 0
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                
                ZStack(alignment: .top) {
                    TabView(selection: $currentImageIndex) {
                        ForEach(Array((pet.imageUrls ?? []).enumerated()), id: \.offset) { index, url in
                            AsyncImage(url: URL(string: url)) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 420)
                    .clipped()
                    
                    
                    if (pet.imageUrls?.count ?? 0) > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<(pet.imageUrls?.count ?? 0), id: \.self) { index in
                                Circle()
                                    .fill(index == currentImageIndex ? Color.appAccent : Color.white.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: UIScreen.main.bounds.width * 0.3)
                            .onTapGesture {
                                if currentImageIndex > 0 {
                                    withAnimation { currentImageIndex -= 1 }
                                }
                            }
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                if currentImageIndex < (pet.imageUrls?.count ?? 1) - 1 {
                                    withAnimation { currentImageIndex += 1 }
                                }
                            }
                    }
                    
                    // Бейджи
                    HStack(spacing: 8) {
                        if let match = pet.matchPercentage {
                            Text("\(match)% Match")
                                .font(.caption).bold().foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.appAccent).cornerRadius(20)
                        }
                        Text("Новый")
                            .font(.caption).bold().foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.orange).cornerRadius(20)
                    }
                    .padding(16)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(pet.name ?? "Без имени"), \(pet.age ?? 0) • \(pet.breed ?? "Без породы")")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundColor(.appTextPrimary)
                    
                    let goal = pet.donationGoal ?? 0
                    let current = pet.currentDonations ?? 0
                    let progress = goal > 0 ? Double(current) / Double(goal) : 0
                    ProgressView(value: min(max(progress, 0), 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    Text("Виртуальный опекун \(current) / \(goal) ₽")
                        .font(.caption).foregroundColor(.appTextSecondary)
                }
                .padding(16)
            }
            .background(Color.appCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 12)
            .offset(x: offset.width, y: offset.height * 0.4)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation }
                    .onEnded { _ in
                        let threshold: CGFloat = 120
                        if offset.width > threshold {
                            removeCard(liked: true)
                        } else if offset.width < -threshold {
                            removeCard(liked: false)
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                offset = .zero
                            }
                        }
                    }
            )
            .opacity(isRemoved ? 0 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func removeCard(liked: Bool) {
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(width: liked ? 600 : -600, height: 0)
            rotation = Double(liked ? 15 : -15)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isRemoved = true
            onSwipe(liked)
        }
    }
}


struct SponsorView: View {
    let pet: Pet
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var amount: Int = 500
    @State private var isLoading = false
    
    let amounts = [100, 500, 1000, 2000]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Поддержать \(pet.name ?? "питомца")")
                    .font(.title2).bold()
                Text("Собрано: \(pet.currentDonations ?? 0) из \(pet.donationGoal ?? 0) ₽")
                    .foregroundColor(.appTextSecondary)
                
                ProgressView(value: Double(pet.currentDonations ?? 0) / Double(pet.donationGoal ?? 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: .appAccent))
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Text("Выберите сумму")
                        .font(.headline)
                    HStack(spacing: 8) {
                        ForEach(amounts, id: \.self) { am in
                            Button("\(am) ₽") {
                                amount = am
                            }
                            .buttonStyle(.bordered)
                            .tint(amount == am ? .appAccent : .gray)
                        }
                    }
                    HStack {
                        Text("Другая:")
                        TextField("Сумма", value: $amount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                    }
                }
                
                Button {
                    Task {
                        isLoading = true
                        await viewModel.sponson(pet: pet, amount: amount)
                        isLoading = false
                        dismiss()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Спонсировать \(amount) ₽")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appAccent)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("Спонсирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
