//
//  BackgroundImageSelectorView.swift
//  StockmansWallet
//
//  Background Image Selector with Live Preview and Tabbed Interface
//  Debug: Shows selected background in real-time with Default/Custom/None tabs
//

import SwiftUI
import SwiftData
import PhotosUI

struct BackgroundImageSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var preferences: [UserPreferences]
    
    // Debug: Tab selection - which mode user is in
    enum BackgroundMode: String, CaseIterable {
        case defaultImages = "Default"
        case custom = "Custom"
        case none = "None"
    }
    
    // Debug: State management for live preview and selection
    @State private var selectedMode: BackgroundMode = .defaultImages
    @State private var previewImageName: String? = nil
    @State private var previewIsCustom: Bool = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var isUploadingImage = false
    @State private var uploadError: String?
    @State private var hasInitialized = false // Debug: Track if we've initialized from preferences
    
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
        ZStack(alignment: .top) {
            // Debug: Background preview with dashboard-style parallax settings
            // Force view to update when preferences change
            let userPrefs = preferences.first ?? UserPreferences()
            let _ = print("🖼️ BackgroundSelector: Rendering with background=\(userPrefs.backgroundImageName ?? "nil"), isCustom=\(userPrefs.isCustomBackground)")
            
            backgroundPreview
                .id("\(previewImageName ?? "none")_\(previewIsCustom)") // Debug: Force recreation when background changes
            
            // Debug: Background gradient overlay (like dashboard)
            Theme.backgroundGradient
            
            // Debug: Main content layout
            VStack(spacing: 0) {
                // Debug: Top spacing to show background
                Color.clear
                    .frame(height: 180)
                
                // Debug: Content panel with rounded top corners (like dashboard)
                VStack(spacing: 0) {
                    // Debug: Header section
                    VStack(spacing: 12) {
                        Text("Personalise your dashboard")
                            .font(Theme.title2)
                            .foregroundStyle(Theme.primaryText)
                        
                        Text("Select one of the default images or upload your own.")
                            .font(Theme.body)
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, Theme.cardPadding)
                    .padding(.bottom, 12) // Debug: Reduced spacing before carousel
                    
                    // Debug: Image carousel or custom upload UI
                    contentForSelectedMode
                        .padding(.bottom, 16)
                    
                    Spacer()
                    
                    // Debug: Add Photo button (only shown in Custom mode)
                    if selectedMode == .custom {
                        Button(action: {
                            HapticManager.tap()
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 20))
                                Text("Add Photo")
                                    .font(Theme.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                        }
                        .padding(.horizontal, Theme.cardPadding)
                        .padding(.bottom, 16)
                        .photosPicker(
                            isPresented: $showingImagePicker,
                            selection: $selectedImageItem,
                            matching: .images
                        )
                        .accessibilityLabel("Add photo from library")
                    }
                    
                    // Debug: Mode selector tabs (Default/Custom/None)
                    modeSelector
                        .padding(.horizontal, Theme.cardPadding)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    // Debug: Rounded container background (like dashboard content panel)
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        topTrailingRadius: 32
                    )
                    .fill(Theme.backgroundColor)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
                )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            // Debug: Initialize state from user preferences on first appearance
            if !hasInitialized {
                initializeFromPreferences()
                hasInitialized = true
            }
        }
        .onChange(of: selectedImageItem) { oldValue, newValue in
            Task {
                await handleImageSelection(newValue)
            }
        }
    }
    
    // MARK: - Background Preview
    
    /// Debug: Background preview - show full opacity for clear preview, matches dashboard layout
    @ViewBuilder
    private var backgroundPreview: some View {
        if let imageName = previewImageName {
            if previewIsCustom {
                // Debug: Custom image from document directory - full opacity for preview
                CustomParallaxImageView(
                    imageName: imageName,
                    intensity: 25,           // Movement amount (20-40)
                    opacity: 0.5,            // Higher opacity for preview visibility
                    scale: 0.5,              // Image takes 50% of screen height
                    verticalOffset: -60,     // Move image up to show more middle/lower area
                    blur: 0                  // No blur
                )
            } else {
                // Debug: Built-in image from assets - full opacity for preview
                ParallaxImageView(
                    imageName: imageName,
                    intensity: 25,           // Movement amount (20-40)
                    opacity: 0.5,            // Higher opacity for preview visibility
                    scale: 0.5,              // Image takes 50% of screen height
                    verticalOffset: -60,     // Move image up to show more middle/lower area
                    blur: 0                  // No blur
                )
            }
        } else {
            // Debug: No background - show solid color
            Theme.backgroundColor
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Mode Selector
    
    /// Debug: Three-tab selector at bottom (Default/Custom/None)
    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(BackgroundMode.allCases, id: \.self) { mode in
                Button(action: {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                    
                    // Debug: Update and save when switching modes
                    if mode == .none {
                        removeBackground()
                    } else if mode == .defaultImages {
                        // Set to first default image if none selected or was custom
                        if previewImageName == nil || previewIsCustom {
                            selectBuiltInBackground(builtInBackgrounds[0])
                        }
                    }
                }) {
                    Text(mode.rawValue)
                        .font(Theme.headline)
                        .foregroundStyle(selectedMode == mode ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedMode == mode ? Color.white.opacity(0.15) : Color.clear)
                        )
                }
                .accessibilityLabel("\(mode.rawValue) mode")
                .accessibilityAddTraits(selectedMode == mode ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Content for Selected Mode
    
    /// Debug: Show different UI based on selected tab
    @ViewBuilder
    private var contentForSelectedMode: some View {
        switch selectedMode {
        case .defaultImages:
            defaultImagesCarousel
        case .custom:
            customUploadUI
        case .none:
            noneUI
        }
    }
    
    /// Debug: Horizontal scrolling carousel of default background images
    private var defaultImagesCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(builtInBackgrounds, id: \.self) { imageName in
                    BackgroundThumbnail(
                        imageName: imageName,
                        isSelected: !previewIsCustom && previewImageName == imageName,
                        isCustom: false
                    ) {
                        HapticManager.tap()
                        selectBuiltInBackground(imageName)
                    }
                }
            }
            .padding(.horizontal, Theme.cardPadding)
        }
        .frame(height: 140)
    }
    
    /// Debug: Custom image display area
    private var customUploadUI: some View {
        VStack(spacing: 12) {
            // Debug: Show current custom image if exists
            if previewIsCustom, let customImageName = previewImageName {
                ScrollView(.horizontal, showsIndicators: false) {
                    CustomBackgroundThumbnail(
                        imageName: customImageName,
                        isSelected: true
                    ) {
                        // Already selected
                    }
                    .padding(.horizontal, Theme.cardPadding)
                }
                .frame(height: 140)
            } else {
                // Debug: Empty state when no custom image
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("No Custom Image")
                        .font(Theme.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                    
                    Text("Tap 'Add Photo' below to upload your own image")
                        .font(Theme.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .frame(height: 140)
                .padding(.horizontal, Theme.cardPadding)
            }
            
            // Debug: Upload progress or error
            if isUploadingImage {
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Uploading image...")
                        .font(Theme.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, Theme.cardPadding)
            }
            
            if let error = uploadError {
                Text(error)
                    .font(Theme.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Theme.cardPadding)
            }
        }
    }
    
    /// Debug: Empty state for "None" mode
    private var noneUI: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.slash")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))
            
            Text("No Background")
                .font(Theme.headline)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            Text("Your dashboard will use the default theme color")
                .font(Theme.caption)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 2)
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(height: 140)
    }
    
    // MARK: - Initialization
    
    /// Debug: Initialize preview state from user preferences
    private func initializeFromPreferences() {
        let prefs = userPrefs
        
        // Set initial mode based on current background state
        if prefs.backgroundImageName == nil {
            selectedMode = .none
        } else if prefs.isCustomBackground {
            selectedMode = .custom
        } else {
            selectedMode = .defaultImages
        }
        
        // Set preview to current background
        previewImageName = prefs.backgroundImageName
        previewIsCustom = prefs.isCustomBackground
        
        print("🖼️ BackgroundSelector: Initialized - mode: \(selectedMode), image: \(previewImageName ?? "nil"), isCustom: \(previewIsCustom)")
    }
    
    // MARK: - Actions
    
    /// Debug: Select a built-in background and save immediately
    private func selectBuiltInBackground(_ imageName: String) {
        guard let prefs = preferences.first else { return }
        
        // Debug: Update preview with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            previewImageName = imageName
            previewIsCustom = false
        }
        
        // Debug: Save to preferences immediately
        print("🖼️ BackgroundSelector: Changing background to \(imageName)")
        prefs.backgroundImageName = imageName
        prefs.isCustomBackground = false
        try? modelContext.save()
        
        // Debug: Post notification to trigger dashboard refresh immediately
        print("🖼️ BackgroundSelector: Posting BackgroundImageChanged notification")
        NotificationCenter.default.post(name: NSNotification.Name("BackgroundImageChanged"), object: nil)
    }
    
    /// Debug: Remove background and save immediately
    private func removeBackground() {
        guard let prefs = preferences.first else { return }
        
        // Debug: Update preview with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            previewImageName = nil
            previewIsCustom = false
        }
        
        // Debug: Save to preferences immediately
        print("🖼️ BackgroundSelector: Removing background")
        prefs.backgroundImageName = nil
        prefs.isCustomBackground = false
        try? modelContext.save()
        
        // Debug: Post notification to trigger dashboard refresh immediately
        print("🖼️ BackgroundSelector: Posting BackgroundImageChanged notification")
        NotificationCenter.default.post(name: NSNotification.Name("BackgroundImageChanged"), object: nil)
    }
    
    // MARK: - Helper Functions
    
    /// Debug: Handle custom image selection, save immediately and update both pages
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
            
            // Debug: Update preview and save to preferences immediately
            await MainActor.run {
                guard let prefs = preferences.first else {
                    isUploadingImage = false
                    return
                }
                
                // Delete old custom background if it exists and is different
                if let oldFilename = prefs.backgroundImageName, prefs.isCustomBackground, oldFilename != filename {
                    deleteCustomBackground(oldFilename)
                }
                
                // Update preview to show new custom image
                previewImageName = filename
                previewIsCustom = true
                
                // Debug: Save to preferences immediately
                print("🖼️ BackgroundSelector: Custom image uploaded - \(filename)")
                prefs.backgroundImageName = filename
                prefs.isCustomBackground = true
                try? modelContext.save()
                
                // Debug: Post notification to trigger dashboard refresh immediately
                print("🖼️ BackgroundSelector: Posting BackgroundImageChanged notification")
                NotificationCenter.default.post(name: NSNotification.Name("BackgroundImageChanged"), object: nil)
                
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

// MARK: - Background Thumbnail Component
/// Debug: Landscape thumbnail for carousel (built-in images) - no borders
struct BackgroundThumbnail: View {
    let imageName: String
    let isSelected: Bool
    let isCustom: Bool
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Debug: Landscape image thumbnail without border (like mockup)
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            
            // Debug: Selection indicator overlay
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: 180, height: 120)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.accent)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.5))
                                    .frame(width: 28, height: 28)
                            )
                            .padding(8)
                        , alignment: .bottomTrailing
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .accessibilityLabel("Background image \(imageName)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to preview this background")
    }
}

// MARK: - Custom Background Thumbnail Component
/// Debug: Landscape thumbnail for custom uploaded images - no borders
struct CustomBackgroundThumbnail: View {
    let imageName: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Debug: Load custom image from document directory
            if let image = loadCustomImage(imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            } else {
                // Debug: Fallback if image can't be loaded
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.cardBackground)
                    .frame(width: 180, height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(Theme.secondaryText)
                            Text("Custom")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            }
            
            // Debug: Selection indicator overlay
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: 180, height: 120)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.accent)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.5))
                                    .frame(width: 28, height: 28)
                            )
                            .padding(8)
                        , alignment: .bottomTrailing
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .accessibilityLabel("Custom background image")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint("Double tap to preview this background")
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

