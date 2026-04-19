import SwiftUI
import PhotosUI

@MainActor
class AddPetViewModel: ObservableObject {
    @Published var name = ""
    @Published var age = ""
    @Published var breed = ""
    @Published var selectedTypeIndex = 0
    @Published var description = ""
    @Published var donationGoal = ""
    @Published var requiresSpace = false
    @Published var catFriendly = true
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var imageDatas: [Data] = []

    private let service = SupabaseService.shared

    var isValid: Bool {
        !name.isEmpty && !age.isEmpty && !description.isEmpty && !selectedImages.isEmpty
    }

    func loadImages() async {
        var loadedData: [Data] = []
        for item in selectedImages {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loadedData.append(data)
            }
        }
        self.imageDatas = loadedData
    }

    func submit() async -> Bool {
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
        guard !imageDatas.isEmpty else {
            errorMessage = "Выберите хотя бы одну фотографию"
            showError = true
            return false
        }

        isLoading = true
        do {
            var uploadedUrls: [String] = []
            for data in imageDatas {
                let fileName = "\(UUID().uuidString).jpg"
                let filePath = "public/\(fileName)"
                _ = try await service.client.storage
                    .from("pet-images")
                    .upload(filePath, data: data)
                let url = try service.client.storage
                    .from("pet-images")
                    .getPublicURL(path: filePath).absoluteString
                uploadedUrls.append(url)
            }

            let typeMap = ["Собака", "Кошка", "Попугай", "Грызун", "Рептилия"]
            let type = typeMap[selectedTypeIndex]
            let goalInt = Int(donationGoal) ?? 0

            let pet = Pet(
                id: UUID(),
                shelterId: ownerId,
                name: name,
                age: ageInt,
                breed: breed.isEmpty ? nil : breed,
                type: type,
                description: description,
                imageUrls: uploadedUrls,
                donationGoal: goalInt,
                currentDonations: 0,
                attributes: PetAttributes(requiresSpace: requiresSpace, catFriendly: catFriendly, status: nil),
                createdAt: Date(),
                matchPercentage: nil
            )
            try await service.addPet(pet)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
            return false
        }
    }
}
