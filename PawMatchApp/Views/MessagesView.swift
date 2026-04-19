import SwiftUI



struct MessagesView: View {
    @Binding var matchToOpen: Match?
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedShelterId: UUID?

    var body: some View {
        NavigationSplitView {
            List(viewModel.matches, selection: $viewModel.activeMatch) { match in
                NavigationLink(value: match) {
                    HStack {
                        AsyncImage(url: URL(string: match.pet?.imageUrls?.first ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text(match.pet?.name ?? "Питомец")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                            Text("Нажмите, чтобы открыть чат")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.appCard)
            }
            .listStyle(.plain)
            .background(Color.appBackground)
            .navigationTitle("Сообщения")
            .overlay {
                if viewModel.matches.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.appTextSecondary.opacity(0.6))
                        Text("У вас пока нет чатов")
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)
                        Text("Когда вы лайкнете питомца, здесь появится диалог с приютом.")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        } detail: {
            if let match = viewModel.activeMatch {
                ChatView(match: match, viewModel: viewModel, selectedShelterId: $selectedShelterId)
                    .id(match.id)
            } else {
                VStack {
                    Image(systemName: "message")
                        .font(.largeTitle)
                        .foregroundColor(.appTextSecondary)
                    Text("Выберите диалог")
                        .foregroundColor(.appTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
            }
        }
        .task {
            await viewModel.loadMatches()
        }
        .onChange(of: matchToOpen) { _, newMatch in
            if let match = newMatch {
                viewModel.activeMatch = match
                matchToOpen = nil
            }
        }
        .sheet(item: $selectedShelterId) { shelterId in
            ShelterProfileView(shelterId: shelterId)
        }
    }
}

struct ChatView: View {
    let match: Match
    @ObservedObject var viewModel: MessagesViewModel
    @Binding var selectedShelterId: UUID?
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.appAccent)
                }
                .frame(width: 44)

                Spacer()

                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: match.pet?.imageUrls?.first ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                    Text(match.pet?.name ?? "Питомец")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                }

                Spacer()

                if let currentUserId = viewModel.currentUserId,
                   match.shelterId != currentUserId {
                    HStack(spacing: 12) {
                        Button {
                            selectedShelterId = match.shelterId
                        } label: {
                            Image(systemName: "building.2.circle")
                                .font(.title3)
                                .foregroundColor(.appAccent)
                        }
                        .frame(width: 44)

                        Button {
                            viewModel.showRatingSheet = true
                        } label: {
                            Image(systemName: "star")
                                .font(.title3)
                                .foregroundColor(.appAccent)
                        }
                        .frame(width: 44)
                    }
                } else {
                    Spacer()
                        .frame(width: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appBackground)

            Divider()
                .background(Color.white.opacity(0.1))

            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { msg in
                            HStack {
                                if msg.senderId == viewModel.currentUserId {
                                    Spacer()
                                    Text(msg.text)
                                        .padding()
                                        .background(Color.appAccent)
                                        .foregroundColor(.white)
                                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                                } else {
                                    Text(msg.text)
                                        .padding()
                                        .background(Color.appCard)
                                        .foregroundColor(.appTextPrimary)
                                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                                    Spacer()
                                }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            
            HStack {
                TextField("Сообщение...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task {
                        await viewModel.sendMessage(text: messageText)
                        messageText = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.appAccent)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .background(Color.appBackground)
        .onAppear {
            Task { await viewModel.loadMessages(for: match) }
        }
        .sheet(isPresented: $viewModel.showRatingSheet) {
            RatingSheet(match: match, viewModel: viewModel)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }
}


struct RatingSheet: View {
    let match: Match
    @ObservedObject var viewModel: MessagesViewModel
    @Environment(\.dismiss) var dismiss
    @State private var rating = 0
    @State private var isSubmitting = false
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isSuccess {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appSuccess)
                        Text("Оценка сохранена!")
                            .font(.title2).bold()
                        Button("Закрыть") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.appAccent)
                    }
                    .padding()
                } else {
                    Text("Оцените приют")
                        .font(.title2).bold()

                    Text("Питомец: \(match.pet?.name ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)

                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                                .onTapGesture { rating = star }
                        }
                    }

                    Button {
                        Task {
                            isSubmitting = true
                            await viewModel.submitRating(for: match, rating: rating)
                            isSubmitting = false
                            isSuccess = true
                            NotificationCenter.default.post(name: .shelterRatingUpdated, object: match.shelterId)
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Оценить")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appAccent)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .disabled(rating == 0 || isSubmitting)
                }
            }
            .padding()
            .navigationTitle("Оценка приюта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isSuccess {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
