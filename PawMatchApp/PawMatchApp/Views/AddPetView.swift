import SwiftUI
import PhotosUI

struct AddPetView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = AddPetViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Имя", text: $viewModel.name)
                    TextField("Возраст (лет)", text: $viewModel.age)
                        .keyboardType(.numberPad)
                    TextField("Порода", text: $viewModel.breed)
                }

                Section("Описание") {
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                }

                Section("Фотография") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title)
                                    .foregroundColor(.appAccent)
                            }
                            Text(selectedImageData == nil ? "Выбрать фото" : "Изменить фото")
                                .foregroundColor(.appAccent)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            selectedImageData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }
                }

                Section("Сбор средств (опционально)") {
                    TextField("Цель сбора (₽)", text: $viewModel.donationGoal)
                        .keyboardType(.numberPad)
                }

                Section("Особенности") {
                    Toggle("Нужен просторный дом", isOn: $viewModel.requiresSpace)
                    Toggle("Дружит с котами", isOn: $viewModel.catFriendly)
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.submit(imageData: selectedImageData)
                            if success {
                                dismiss()
                            }
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
                    .disabled(viewModel.isLoading || !viewModel.isValid || selectedImageData == nil)
                }
            }
            .navigationTitle("Добавить питомца")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
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
}
