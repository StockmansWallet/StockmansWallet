//
//  BackgroundImageSelectorView.swift
//  StockmansWallet
//
//  Background Image Selector with Carousel and Custom Upload
//  Debug: Allows users to select from built-in backgrounds or upload custom images
//

import SwiftUI
import SwiftData
import PhotosUI

struct BackgroundImageSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    // Debug: State management for image selection and upload
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    
    // Debug: Built-in background images from Assets catalog
    private let builtInBackgrounds = [
        "BackgroundDefault",
        "FarmBG_01",
        "FarmBG_02",
        "FarmBG_03",
        "FarmBG_04",
        "FarmBG_05",
        "FarmBG_06",
        "FarmBG_07",
        "FarmBG_08",
        "FarmBG_09",
        "FarmBG_10",
        "FarmBG_11",
        "FarmBG_12",
        "FarmBG_13",
        "FarmBG_14",
        "FarmBG_15",
        "FarmBG_16",
        "FarmBG_17"
    ]
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                // Debug: Header section with description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dashboard Background")
                        .font(Theme.title2)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("Choose a background image for your dashboard. Swipe through the options or upload your own photo.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, Theme.cardPadding)
                
                // Debug: Built-in backgrounds carousel
                VStack(alignment: .leading, spacing: 12) {
                    Text("Built-in Backgrounds")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, Theme.cardPadding)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(builtInBackgrounds, id: \.self) { imageName in
                                BackgroundImageCard(
                                    imageName: imageName,
                                    isSelected: !userPrefs.isCustomBackground && userPrefs.backgroundImageName == imageName,
                                    isCustom: false
                                ) {
                                    selectBuiltInBackground(imageName)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.cardPadding)
                        .scrollTargetLayout() // Debug: Better scrolling behavior
                    }
                    .scrollTargetBehavior(.viewAligned) // Debug: Snap to items for better UX
                }
                
                // Debug: Custom background upload section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Background")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, Theme.cardPadding)
                    
                    // Debug: Show current custom background if exists
                    if userPrefs.isCustomBackground, let customImageName = userPrefs.backgroundImageName {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                CustomBackgroundImageCard(
                                    imageName: customImageName,
                                    isSelected: true
                                ) {
                                    // Already selected, do nothing
                                }
                            }
                            .padding(.horizontal, Theme.cardPadding)
                            .scrollTargetLayout() // Debug: Better scrolling behavior
                        }
                        .scrollTargetBehavior(.viewAligned) // Debug: Snap to items for better UX
                    }
                    
                    // Debug: Upload button with PhotosPicker
                    Button(action: {
                        HapticManager.tap()
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 20))
                            Text("Upload Custom Photo")
                                .font(Theme.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                    .padding(.horizontal, Theme.cardPadding)
                    .photosPicker(
                        isPresented: $showingImagePicker,
                        selection: $selectedImageItem,
                        matching: .images
                    )
                    .accessibilityLabel("Upload custom background photo")
                    .accessibilityHint("Opens photo picker to select a custom background image")
                    
                    // Debug: Show upload error if any
                    if let error = uploadError {
                        Text(error)
                            .font(Theme.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, Theme.cardPadding)
                    }
                    
                    // Debug: Upload progress indicator
                    if isUploadingImage {
                        HStack {
                            ProgressView()
                                .tint(Theme.accent)
                            Text("Uploading image...")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .padding(.horizontal, Theme.cardPadding)
                    }
                }
                .padding(.top, Theme.sectionSpacing)
            }
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Background Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: selectedImageItem) { oldValue, newValue in
            Task {
                await handleImageSelection(newValue)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Debug: Select a built-in background image from assets
    private func selectBuiltInBackground(_ imageName: String) {
        // Debug: Update user preferences with selected built-in background
        if let prefs = preferences.first {
            print("🖼️ BackgroundSelector: Changing background to \(imageName)")
            prefs.backgroundImageName = imageName
            prefs.isCustomBackground = false
            try? modelContext.save()
            
            // Debug: Post notification to trigger dashboard refresh immediately
            print("🖼️ BackgroundSelector: Posting BackgroundImageChanged notification")
            NotificationCenter.default.post(name: NSNotification.Name("BackgroundImageChanged"), object: nil)
        }
    }
    
    /// Debug: Handle custom image selection and save to document directory
    private func handleImageSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run {
            isUploadingImage = true
            uploadError = nil
        }
        
        do {
            // Debug: Load image data from PhotosPicker
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    uploadError = "Failed to load image data"
                    isUploadingImage = false
                }
                HapticManager.error()
                return
            }
            
            // Debug: Validate and compress image
            guard let uiImage = UIImage(data: imageData) else {
                await MainActor.run {
                    uploadError = "Invalid image format"
                    isUploadingImage = false
                }
                HapticManager.error()
                return
            }
            
            // Debug: Compress image to reasonable size (max 2048px width, 0.8 quality)
            let compressedImage = compressImage(uiImage, maxWidth: 2048, quality: 0.8)
            guard let compressedData = compressedImage.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    uploadError = "Failed to compress image"
                    isUploadingImage = false
                }
                HapticManager.error()
                return
            }
            
            // Debug: Save to document directory with unique filename
            let filename = "custom_background_\(UUID().uuidString).jpg"
            let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
            
            try compressedData.write(to: fileURL)
            
            // Debug: Update user preferences with custom background
            await MainActor.run {
                if let prefs = preferences.first {
                    // Delete old custom background if exists
                    if prefs.isCustomBackground, let oldFilename = prefs.backgroundImageName {
                        deleteCustomBackground(oldFilename)
                    }
                    
                    prefs.backgroundImageName = filename
                    prefs.isCustomBackground = true
                    try? modelContext.save()
                    
                    // Debug: Post notification to trigger dashboard refresh immediately
                    NotificationCenter.default.post(name: NSNotification.Name("BackgroundImageChanged"), object: nil)
                }
                
                isUploadingImage = false
                selectedImageItem = nil
                HapticManager.success()
            }
            
        } catch {
            await MainActor.run {
                uploadError = "Failed to save image: \(error.localizedDescription)"
                isUploadingImage = false
            }
            HapticManager.error()
        }
    }
    
    /// Debug: Compress image to reduce file size while maintaining quality
    private func compressImage(_ image: UIImage, maxWidth: CGFloat, quality: CGFloat) -> UIImage {
        let size = image.size
        
        // Debug: Only resize if image is larger than maxWidth
        if size.width <= maxWidth {
            return image
        }
        
        let ratio = maxWidth / size.width
        let newSize = CGSize(width: maxWidth, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Debug: Get app's document directory for storing custom backgrounds
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Debug: Delete old custom background file to free up space
    private func deleteCustomBackground(_ filename: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Background Image Card Component
struct BackgroundImageCard: View {
    let imageName: String
    let isSelected: Bool
    let isCustom: Bool
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Debug: Image preview with parallax-like appearance
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Theme.accent : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            
            // Debug: Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .background(
                        Circle()
                            .fill(Theme.backgroundColor)
                            .frame(width: 24, height: 24)
                    )
                    .padding(8)
                    .accessibilityLabel("Selected")
            }
        }
        .contentShape(Rectangle()) // Debug: Make entire card area tappable
        .onTapGesture {
            // Debug: Direct tap gesture for better responsiveness in ScrollView
            // Trigger haptic feedback immediately on main thread
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
            onSelect()
        }
        .accessibilityLabel("Background image \(imageName)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to select this background")
    }
}

// MARK: - Custom Background Image Card Component
struct CustomBackgroundImageCard: View {
    let imageName: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Debug: Load custom image from document directory
            if let image = loadCustomImage(imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? Theme.accent : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            } else {
                // Debug: Fallback if image can't be loaded
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
                    .frame(width: 160, height: 240)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.secondaryText)
                            Text("Custom")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    )
            }
            
            // Debug: Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
                    .background(
                        Circle()
                            .fill(Theme.backgroundColor)
                            .frame(width: 24, height: 24)
                    )
                    .padding(8)
                    .accessibilityLabel("Selected")
            }
        }
        .contentShape(Rectangle()) // Debug: Make entire card area tappable
        .onTapGesture {
            // Debug: Direct tap gesture for better responsiveness in ScrollView
            // Trigger haptic feedback immediately on main thread
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
            onSelect()
        }
        .accessibilityLabel("Custom background image")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to select this background")
    }
    
    /// Debug: Load custom image from document directory
    private func loadCustomImage(_ filename: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
}

