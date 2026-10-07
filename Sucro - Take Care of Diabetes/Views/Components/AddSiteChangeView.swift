//
//  AddSiteChangeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/12/26.
//


//
//  AddSiteChangeView.swift
//  Sucro - Take Care of Diabetes
//
//  Created by Angad Kumar on 3/13/26.
//

import SwiftUI
import CoreData

struct AddSiteChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HomeViewModel.self) private var viewModel
    
    @State private var selectedLocation: SiteLocation = .abdomenLeft
    @State private var notes: String = ""
    @State private var showPhotoPicker = false
    @State private var sitePhoto: UIImage?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Site Location") {
                    Picker("Location", selection: $selectedLocation) {
                        ForEach(SiteLocation.allCases, id: \.self) { location in
                            HStack {
                                Image(systemName: location.iconName)
                                Text(location.rawValue)
                            }
                            .tag(location)
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    Text("Body Region: \(selectedLocation.bodyRegion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Change every \(selectedLocation.rotationDays) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Photo (Optional)") {
                    if let sitePhoto = sitePhoto {
                        Image(uiImage: sitePhoto)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    
                    Button(sitePhoto == nil ? "Add Photo" : "Change Photo") {
                        showPhotoPicker = true
                    }
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section {
                    Button("Save Site Change") {
                        saveSiteChange()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(.rect(cornerRadius: 8))
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Change Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                // Use system photo picker or camera
                ImagePicker(selectedImage: $sitePhoto)
            }
        }
    }
    
    private func saveSiteChange() {
        let siteChange = SiteChange(context: viewModel.viewContext)
        siteChange.id = UUID()
        siteChange.timestamp = Date()
        siteChange.location = selectedLocation.rawValue
        siteChange.notes = notes.isEmpty ? nil : notes
        siteChange.siteType = "Infusion"
        siteChange.deviceType = "Pump"
        
        if let photo = sitePhoto, let photoData = photo.jpegData(compressionQuality: 0.8) {
            siteChange.photo = photoData
        }
        
        viewModel.save()
        // Refreshing also schedules the reminder for the next change.
        viewModel.fetchLatestData()
        dismiss()
    }
}

// Simple image picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary // Or .camera for camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddSiteChangeView()
        .environment(HomeViewModel(context: PersistenceController.preview.container.viewContext))
}