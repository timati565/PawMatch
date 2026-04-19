import SwiftUI
import UserNotifications

@MainActor
class HomeViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var filteredPets: [Pet] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSponsorSheet = false
    @Published var showMatchAlert = false
    @Published var matchedPet: Pet?
    @Published var createdMatch: Match?

    var authManager: AuthManager?
    private let service = SupabaseService.shared
    private var currentFilter = "Все"

    func loadFeed() async {
        isLoading = true
        do {
            let swipedIds = try await service.fetchSwipedPetIds()
            var loadedPets = try await service.fetchPets(excludingSwipedPetIds: swipedIds)
            for i in loadedPets.indices { loadedPets[i].matchPercentage = Int.random(in: 60...99) }
            pets = loadedPets
            filterPets(by: currentFilter)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func filterPets(by filter: String) {
        currentFilter = filter
        if filter == "Все" {
            filteredPets = pets
        } else {
            let typeMap = ["Собаки": "dog", "Кошки": "cat", "Попугаи": "parrot", "Грызуны": "rodent", "Рептилии": "reptile"]
            filteredPets = pets.filter { $0.type == typeMap[filter] }
        }
    }

    func handleSwipe(pet: Pet, liked: Bool) {
        Task {
            do {
                let action: Swipe.SwipeAction = liked ? .like : .pass
                try await service.recordSwipe(petId: pet.id, action: action)

                if liked {
                    guard let currentUserId = service.currentUserID,
                          let shelterId = pet.shelterId else { return }
                    try await service.createMatch(userId: currentUserId, petId: pet.id, shelterId: shelterId)
                    let match = Match(
                        id: UUID(),
                        userId: currentUserId,
                        petId: pet.id,
                        shelterId: shelterId,
                        createdAt: Date()
                    )
                    createdMatch = match
                    matchedPet = pet
                    showMatchAlert = true
                }

                if let index = pets.firstIndex(where: { $0.id == pet.id }) {
                    pets.remove(at: index)
                }
                filterPets(by: currentFilter)
                if filteredPets.count < 3 { await loadFeed() }
            } catch {
                print("Swipe error: \(error)")
            }
        }
    }

    func skipCurrent() {
        guard let first = filteredPets.first else { return }
        handleSwipe(pet: first, liked: false)
    }

    func likeCurrent() {
        guard let first = filteredPets.first else { return }
        handleSwipe(pet: first, liked: true)
    }

    func sponson(pet: Pet, amount: Int) async {
        guard amount > 0 else { return }
        do {
            let newTotal = (pet.currentDonations ?? 0) + amount
            try await service.updateDonations(petId: pet.id, amount: newTotal)
            if let index = pets.firstIndex(where: { $0.id == pet.id }) {
                pets[index].currentDonations = newTotal
            }
            filterPets(by: currentFilter)
        } catch {
            print("Sponsor error: \(error)")
        }
    }
}
