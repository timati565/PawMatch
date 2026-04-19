import SwiftUI

@MainActor
class ShelterProfileViewModel: ObservableObject {
    @Published var shelterName: String?
    @Published var rating: Double = 0
    @Published var reviewsCount: Int = 0
    @Published var pets: [Pet] = []
    
    private let service = SupabaseService.shared
    
    func loadShelterData(shelterId: UUID) async {
        
        do {
            let profiles: [User] = try await service.client
                .from("profiles")
                .select()
                .eq("id", value: shelterId)
                .execute()
                .value
            if let profile = profiles.first {
                shelterName = profile.name ?? "Приют"
            }
        } catch {
            print("Ошибка загрузки профиля приюта: \(error)")
        }
        
        
        do {
            rating = try await service.fetchShelterRating(shelterId: shelterId)
            
            
            struct RatingRow: Codable {
                let shelterRating: Int
                enum CodingKeys: String, CodingKey {
                    case shelterRating = "shelter_rating"
                }
            }
            let rows: [RatingRow] = try await service.client
                .from("matches")
                .select("shelter_rating")
                .eq("shelter_id", value: shelterId)
                .execute()
                .value
            reviewsCount = rows.count
        } catch {
            print("Ошибка загрузки рейтинга: \(error)")
        }
        
        
        do {
            pets = try await service.client
                .from("pets")
                .select()
                .eq("shelter_id", value: shelterId)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            print("Ошибка загрузки питомцев: \(error)")
        }
    }
}
