import SwiftUI

struct PetDetailView: View {
    let pet: Pet

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: pet.imageUrls?.first ?? "")) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text(pet.name ?? "Без имени").font(.largeTitle).bold()
                    if let breed = pet.breed { Text(breed).font(.title3).foregroundColor(.secondary) }
                    if let age = pet.age { Text("Возраст: \(age) \(age == 1 ? "год" : age < 5 ? "года" : "лет")").font(.body) }
                    if let description = pet.description { Text(description).padding(.top) }
                }
                .padding(.horizontal)

                if let goal = pet.donationGoal {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Сбор средств").font(.headline).padding(.horizontal)
                        ProgressView(value: Double(pet.currentDonations ?? 0), total: Double(goal))
                            .padding(.horizontal)
                        Text("Собрано \(pet.currentDonations ?? 0) из \(goal) ₽")
                            .font(.caption).foregroundColor(.secondary).padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(pet.name ?? "Питомец")
        .navigationBarTitleDisplayMode(.inline)
    }
}
