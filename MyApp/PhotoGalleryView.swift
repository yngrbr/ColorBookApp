import SwiftUI
import PhotosUI
import SwiftData

struct PhotoGalleryView: View {
    @Bindable var appointment: Appointment
    @Environment(\.modelContext) private var context
    
    // Замыкание для передачи фото наверх в EditAppointmentView
    var onImageTap: (UIImage) -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var photoType: String = "before"
    @State private var isPhotoPickerPresented = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                photoCard(title: "До", data: appointment.photoBefore, type: "before")
                photoCard(title: "После", data: appointment.photoAfter, type: "after")
            }
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem = newItem else { return }
            
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    guard let uiImage = UIImage(data: data),
                          let compressedData = uiImage.jpegData(compressionQuality: 0.5) else { return }
                    
                    await MainActor.run {
                        if photoType == "before" {
                            appointment.photoBefore = compressedData
                        } else {
                            appointment.photoAfter = compressedData
                        }
                        try? context.save()
                        selectedItem = nil
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func photoCard(title: String, data: Data?, type: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            
            if let data = data, let uiImage = UIImage(data: data) {
                Button {
                    // ВЫЗЫВАЕМ ЗАМЫКАНИЕ, ЧТОБЫ ОТКРЫТЬ ФОТО НАВЕРХУ
                    onImageTap(uiImage)
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    photoType = type
                    isPhotoPickerPresented = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Добавить")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
