import SwiftUI

struct ShelterProfileView: View {
    let shelterId: UUID
    @StateObject private var viewModel = ShelterProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.appAccent)
                        
                        Text(viewModel.shelterName ?? "Приют")
                            .font(.title.bold())
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", viewModel.rating))
                                .font(.title2.bold())
                        }
                        
                        Text("на основе \(viewModel.reviewsCount) отзывов")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appCard)
                    .cornerRadius(24)
                    
                    
                    VStack {
                        Text("Здесь будет статистика ваших пристроенных животных и отзывы волонтеров.")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.appCard)
                    .cornerRadius(24)
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Питомцы приюта", systemImage: "pawprint.fill")
                            .font(.headline.bold())
                        
                        if viewModel.pets.isEmpty {
                            Text("У приюта пока нет питомцев")
                                .foregroundColor(.appTextSecondary)
                                .padding()
                        } else {
                            ForEach(viewModel.pets) { pet in
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
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Профиль приюта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .task {
            await viewModel.loadShelterData(shelterId: shelterId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .shelterRatingUpdated)) { notif in
            if let updatedShelterId = notif.object as? UUID, updatedShelterId == shelterId {
                Task { await viewModel.loadShelterData(shelterId: shelterId) }
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
}
