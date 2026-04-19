import SwiftUI
import PhotosUI

struct AddPetView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = AddPetViewModel()
    @Environment(\.dismiss) var dismiss

    let petTypes = ["Собака", "Кошка", "Попугай", "Грызун", "Рептилия"]

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                descriptionSection
                photoSection
                donationSection
                featuresSection
                submitButtonSection
            }
            .navigationTitle("Добавить питомца")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        dismiss()
                    }
                }
            }
            .alert("Ошибка", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var basicInfoSection: some View {
        Section("Основная информация") {
            TextField("Имя", text: $viewModel.name)
            TextField("Возраст (лет)", text: $viewModel.age)
                .keyboardType(.numberPad)
            TextField("Порода", text: $viewModel.breed)
            Picker("Тип", selection: $viewModel.selectedTypeIndex) {
                ForEach(0..<petTypes.count, id: \.self) { idx in
                    Text(petTypes[idx]).tag(idx)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var descriptionSection: some View {
        Section("Описание") {
            TextEditor(text: $viewModel.description)
                .frame(minHeight: 100)
        }
    }

    private var photoSection: some View {
        Section("Фотографии") {
            PhotosPicker(
                selection: $viewModel.selectedImages,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title)
                        .foregroundColor(.appAccent)
                    Text(viewModel.selectedImages.isEmpty ? "Выбрать фото" : "Выбрано \(viewModel.selectedImages.count)")
                        .foregroundColor(.appAccent)
                }
            }
            if !viewModel.imageDatas.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(0..<viewModel.imageDatas.count, id: \.self) { index in
                            if let uiImage = UIImage(data: viewModel.imageDatas[index]) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
    }

    private var donationSection: some View {
        Section("Сбор средств") {
            TextField("Цель (₽)", text: $viewModel.donationGoal)
                .keyboardType(.numberPad)
        }
    }

    private var featuresSection: some View {
        Section("Особенности") {
            Toggle("Нужен просторный дом", isOn: $viewModel.requiresSpace)
            Toggle("Дружит с котами", isOn: $viewModel.catFriendly)
        }
    }

    private var submitButtonSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.loadImages() 
                    let success = await viewModel.submit()
                    if success { dismiss() }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Опубликовать")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.appAccent)
                }
            }
            .disabled(viewModel.isLoading || !viewModel.isValid)
        }
    }
}
