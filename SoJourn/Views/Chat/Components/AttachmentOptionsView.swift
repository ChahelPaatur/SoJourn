import SwiftUI
import PhotosUI

struct AttachmentOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImageItem: PhotosPickerItem?
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Photo library option
            PhotosPicker(selection: $selectedImageItem, matching: .images) {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    Text("Photos")
                        .font(.caption)
                }
                .frame(width: 70, height: 70)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .onChange(of: selectedImageItem) { _, _ in
                dismiss()
            }
            
            // Camera option
            Button {
                // Would open camera
                dismiss()
            } label: {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    Text("Camera")
                        .font(.caption)
                }
                .frame(width: 70, height: 70)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Document option
            Button {
                // Would open document picker
                dismiss()
            } label: {
                VStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    Text("Files")
                        .font(.caption)
                }
                .frame(width: 70, height: 70)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
} 