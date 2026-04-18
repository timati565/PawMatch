import SwiftUI
import PhotosUI

@MainActor
class AddPetViewModel: ObservableObject {
    @Published var name = ""
    @Published var age = ""
    @Published var breed = ""
    @Published var description = ""
    @Published var donationGoal = ""
    @Published var requiresSpace = false
    @Published var catFriendly = true
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let service = SupabaseService.shared
    
    var isValid: Bool {
        !name.isEmpty && !age.isEmpty && !description.isEmpty
    }
    
    // AddPetViewModel.swift (фрагмент submit)
    func submit(imageData: Data?) async -> Bool {
        guard let ageInt = Int(age) else {
            errorMessage = "Введите корректный возраст"
            showError = true
            return false
        }
        guard let ownerId = service.currentUserID else {
            errorMessage = "Пользователь не авторизован"
            showError = true
            return false
        }
        guard let imageData else {
            errorMessage = "Выберите фотографию"
            showError = true
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        do {
            print("📤 Начинаем загрузку фото в Storage...")
            let fileName = "\(UUID().uuidString).jpg"
            let filePath = "public/\(fileName)"
            _ = try await service.client.storage
                .from("pet-images")
                .upload(filePath, data: imageData)
            print("✅ Фото загружено")
            
            let publicURL = try service.client.storage
                .from("pet-images")
                .getPublicURL(path: filePath).absoluteString
            print("🔗 Публичный URL: \(publicURL)")
            
            let goalInt = Int(donationGoal) ?? 0
            let pet = Pet(
                id: UUID(),
                shelterId: ownerId,
                name: name,
                age: ageInt,
                breed: breed.isEmpty ? nil : breed,
                description: description,
                imageUrls: [publicURL],
                donationGoal: goalInt,
                currentDonations: 0,
                attributes: PetAttributes(requiresSpace: requiresSpace, catFriendly: catFriendly, status: nil),
                createdAt: Date(),
                matchPercentage: nil
            )
            
            print("💾 Сохраняем питомца в БД...")
            try await service.addPet(pet)
            print("✅ Питомец успешно добавлен")
            return true
        } catch {
            errorMessage = "Ошибка: \(error.localizedDescription)"
            showError = true
            print("❌ Ошибка публикации: \(error)")
            return false
        }
    }
}
