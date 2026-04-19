import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var likesCount: Int = 0
    @Published var matchesCount: Int = 0
    @Published var rating: Double = 0
    @Published var reviewsCount: Int = 0
    @Published var shelterPets: [Pet] = []

    private let service = SupabaseService.shared

    func loadStats(for userId: UUID) async {
        
        do {
            let myPets: [Pet] = try await service.client
                .from("pets")
                .select()
                .eq("shelter_id", value: userId)
                .execute()
                .value
            let myPetIds = myPets.map { $0.id }
            if !myPetIds.isEmpty {
                let likes: [Swipe] = try await service.client
                    .from("swipes")
                    .select()
                    .in("pet_id", values: myPetIds)
                    .eq("action", value: "LIKE")
                    .execute()
                    .value
                likesCount = likes.count
            } else {
                likesCount = 0
            }
        } catch {
            print("Load likes error: \(error)")
        }

        
        do {
            let matches: [Match] = try await service.client
                .from("matches")
                .select()
                .or("user_id.eq.\(userId),shelter_id.eq.\(userId)")
                .execute()
                .value
            matchesCount = matches.count
        } catch {
            print("Load matches error: \(error)")
        }
    }

    func loadRating(for userId: UUID) async {
        do {
            let matches: [Match] = try await service.client
                .from("matches")
                .select("shelter_rating")
                .eq("shelter_id", value: userId)
                .execute()
                .value
            let ratings = matches.compactMap { $0.shelterRating }
            reviewsCount = ratings.count
            rating = reviewsCount > 0 ? Double(ratings.reduce(0, +)) / Double(reviewsCount) : 0
        } catch {
            print("Load rating error: \(error)")
        }
    }

    func loadShelterPets(for userId: UUID) async {
        do {
            shelterPets = try await service.client
                .from("pets")
                .select()
                .eq("shelter_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            print("Ошибка загрузки питомцев приюта: \(error)")
        }
    }
}
