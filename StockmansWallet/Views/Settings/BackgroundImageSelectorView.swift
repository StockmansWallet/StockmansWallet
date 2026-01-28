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
        "FarmBG_17",
        "FarmBG_18",
        "FarmBG_19"
    ]
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        // Debug: Use GeometryReader to make thumbnails responsive to screen size
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Debug: Background preview with dashboard-style parallax settings (fixed, doesn't scroll)
                // Force view to update when preferences change
                let currentPrefs = preferences.first ?? UserPreferences()
                let _ = print("🖼️ BackgroundSelector: Rendering with background=\(currentPrefs.backgroundImageName ?? "nil"), isCustom=\(currentPrefs.isCustomBackground)")
                
                backgroundPreview
                    .id("\(previewImageName ?? "none")_\(previewIsCustom)") // Debug: Force recreation when background changes
                
                // Debug: Scrollable content panel - slides up over the fixed background
                // Aligned to bottom for consistent positioning
                ScrollView {
                    VStack(spacing: 0) {
                        // Debug: Spacer pushes content panel to the bottom, revealing background at top
                        Spacer()
                            .frame(minHeight: 60) // Minimum spacing to always show some background
                        
                        // Debug: Content panel with rounded top corners - scrolls up over background
                        contentPanel(screenHeight: geometry.size.height)
                    }
                    .frame(minHeight: geometry.size.height) // Ensure VStack fills available height
                }
                .scrollIndicators(.visible)
            }
            .ignoresSafeArea(edges: .bottom) // Debug: Extend entire view to bottom edge to eliminate black bar
        }
        .navigationTitle("Dashboard Background")
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
    
    // MARK: - Content Panel
    
    /// Debug: Rounded content panel with all selector content - scrolls over background (like dashboard)
    @ViewBuilder
    private func contentPanel(screenHeight: CGFloat) -> some View {
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
            .padding(.bottom, 24)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Personalise your dashboard. Select one of the default images or upload your own.")
            
            // Debug: Mode selector tabs (Default/Custom/None) - moved above thumbnails
            modeSelector
                .padding(.horizontal, Theme.cardPadding)
                .padding(.bottom, 24)
            
            // Debug: Image carousel or custom upload UI with responsive sizing
            contentForSelectedMode(screenHeight: screenHeight)
                .padding(.bottom, 16)
            
            // Debug: Add Photo button (only shown in Custom mode) - iOS native PhotosPicker
            if selectedMode == .custom {
                PhotosPicker(
                    selection: $selectedImageItem,
                    matching: .images
                ) {
                    Label("Add Photo", systemImage: "photo.badge.plus")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.buttonHeight)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.cardPadding)
                .padding(.bottom, 16)
                .accessibilityLabel("Add photo from library")
                .accessibilityHint("Opens your photo library to select a custom background image")
            }
        }
        .padding(.bottom, 20) // Debug: Minimal bottom padding
        .background(
            // Debug: Flat rounded container background (no gradient for settings pages)
            // Extends to bottom edge
            GeometryReader { geo in
                UnevenRoundedRectangle(
                    topLeadingRadius: Theme.sheetCornerRadius,
                    topTrailingRadius: Theme.sheetCornerRadius,
                    style: .continuous
                )
                .fill(Theme.backgroundColor)
                .frame(height: geo.size.height + 100) // Debug: Extend beyond container to eliminate gaps
                .shadow(color: .black.opacity(0.8), radius: 30, y: -8)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Background Preview
    
    /// Debug: Background preview - matches dashboard opacity exactly for accurate preview
    @ViewBuilder
    private var backgroundPreview: some View {
        if let imageName = previewImageName {
            if previewIsCustom {
                // Debug: Custom image from document directory - uses Theme constant for consistent opacity
                CustomParallaxImageView(
                    imageName: imageName,
                    intensity: 25,                          // Movement amount (20-40)
                    opacity: Theme.backgroundImageOpacity,  // Background opacity (from Theme)
                    scale: 0.5,                             // Image takes 50% of screen height
                    verticalOffset: -60,                    // Move image up to show more middle/lower area
                    blur: 0                                 // No blur
                )
            } else {
                // Debug: Built-in image from assets - uses Theme constant for consistent opacity
                ParallaxImageView(
                    imageName: imageName,
                    intensity: 25,                          // Movement amount (20-40)
                    opacity: Theme.backgroundImageOpacity,  // Background opacity (from Theme)
                    scale: 0.5,                             // Image takes 50% of screen height
                    verticalOffset: -60,                    // Move image up to show more middle/lower area
                    blur: 0                                 // No blur
                )
            }
        } else {
            // Debug: No background - show almost black color with subtle accent glow
            ZStack {
                // Debug: Almost black base layer for strong contrast
                Theme.noBackgroundColor
                    .ignoresSafeArea()
                
                // Debug: Very subtle orange glow at top for minimal warmth (matching dashboard)
                RadialGradient(
                    colors: [
                        Theme.accent.opacity(0.08),  // Minimal orange glow at top
                        Theme.accent.opacity(0.02),  // Fade to barely visible
                        Color.clear                   // Fade to transparent
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Mode Selector
    
    /// Debug: Native iOS segmented control for mode selection (HIG compliant)
    @ViewBuilder
    private var modeSelector: some View {
        Picker("Background Mode", selection: $selectedMode) {
            ForEach(BackgroundMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedMode) { oldValue, newValue in
            // Debug: Haptic feedback on selection change
            HapticManager.selectionChanged()
            
            // Debug: Update and save when switching modes
            if newValue == .none {
                removeBackground()
            } else if newValue == .defaultImages {
                // Set to first default image if none selected or was custom
                if previewImageName == nil || previewIsCustom {
                    selectBuiltInBackground(builtInBackgrounds[0])
                }
            }
        }
    }
    
    // MARK: - Content for Selected Mode
    
    /// Debug: Calculate responsive thumbnail size based on available screen space
    /// Uses aggressive sizing to maximize thumbnail size and minimize empty space
    private func calculateThumbnailSize(for screenHeight: CGFloat) -> (width: CGFloat, height: CGFloat, containerHeight: CGFloat) {
        // Debug: Fixed elements heights - measured more accurately from design
        let topSpacing: CGFloat = 180           // Background preview area
        let headerHeight: CGFloat = 112         // Title + subtitle + padding (increased from 100 to 112 for more space)
        let bottomPadding: CGFloat = 12         // Content bottom padding
        let buttonHeight: CGFloat = selectedMode == .custom ? 68 : 0  // Add Photo button + padding
        let segmentedHeight: CGFloat = 70       // Segmented control + padding
        let safeAreaEstimate: CGFloat = 40      // Safe area bottom estimate
        
        // Debug: Calculate available height for thumbnails - be very aggressive
        let totalFixedHeight = topSpacing + headerHeight + bottomPadding + buttonHeight + segmentedHeight + safeAreaEstimate
        let availableHeight = screenHeight - totalFixedHeight
        
        // Debug: Use almost all available space - min 280, max 500
        // This should fill the space much better
        let thumbnailHeight = max(280, min(500, availableHeight))
        let thumbnailWidth = thumbnailHeight * (5.0 / 7.0) // Portrait aspect ratio (5:7)
        let containerHeight = thumbnailHeight + 8 // Minimal padding
        
        print("📐 Responsive sizing: screen=\(screenHeight), totalFixed=\(totalFixedHeight), available=\(availableHeight), thumbnail=\(thumbnailWidth)×\(thumbnailHeight), container=\(containerHeight)")
        
        return (thumbnailWidth, thumbnailHeight, containerHeight)
    }
    
    /// Debug: Show different UI based on selected tab with responsive sizing
    @ViewBuilder
    private func contentForSelectedMode(screenHeight: CGFloat) -> some View {
        let size = calculateThumbnailSize(for: screenHeight)
        
        switch selectedMode {
        case .defaultImages:
            defaultImagesCarousel(width: size.width, height: size.height, containerHeight: size.containerHeight)
        case .custom:
            customUploadUI(width: size.width, height: size.height, containerHeight: size.containerHeight)
        case .none:
            noneUI(containerHeight: size.containerHeight)
        }
    }
    
    /// Debug: Horizontal scrolling carousel of default background images with responsive sizing
    @ViewBuilder
    private func defaultImagesCarousel(width: CGFloat, height: CGFloat, containerHeight: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(builtInBackgrounds, id: \.self) { imageName in
                    BackgroundThumbnail(
                        imageName: imageName,
                        isSelected: !previewIsCustom && previewImageName == imageName,
                        isCustom: false,
                        width: width,
                        height: height
                    ) {
                        HapticManager.tap()
                        selectBuiltInBackground(imageName)
                    }
                }
            }
            .padding(.horizontal, Theme.cardPadding)
        }
        .frame(height: containerHeight) // Debug: Responsive height based on screen size
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Background images")
        .accessibilityHint("Swipe to browse available background images")
    }
    
    /// Debug: Custom image display area with responsive sizing - shows all custom images
    @ViewBuilder
    private func customUploadUI(width: CGFloat, height: CGFloat, containerHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            let prefs = preferences.first ?? UserPreferences()
            let customImages = prefs.customBackgroundImages
            
            // Debug: Show all custom images in horizontal scroll if any exist
            if !customImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(customImages, id: \.self) { imageName in
                            CustomBackgroundThumbnail(
                                imageName: imageName,
                                isSelected: previewIsCustom && previewImageName == imageName,
                                width: width,
                                height: height,
                                onDelete: {
                                    deleteCustomImage(imageName)
                                }
                            ) {
                                HapticManager.tap()
                                selectCustomBackground(imageName)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.cardPadding)
                }
                .frame(height: containerHeight) // Debug: Responsive height based on screen size
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Custom background images")
                .accessibilityHint("Swipe to browse your custom images")
            } else {
                // Debug: Empty state when no custom images
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: min(48, height * 0.2))) // Scale icon with screen size
                        .foregroundStyle(.white.opacity(0.6))
                        .accessibilityHidden(true)
                    
                    Text("No Custom Images")
                        .font(Theme.headline)
                        .foregroundStyle(Theme.primaryText)
                    
                    Text("Tap 'Add Photo' below to upload your own image")
                        .font(Theme.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(height: containerHeight) // Debug: Responsive height based on screen size
                .padding(.horizontal, Theme.cardPadding)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No custom images. Tap 'Add Photo' below to upload your own image")
                .accessibilityAddTraits(.isStaticText)
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Uploading image")
                .accessibilityAddTraits(.updatesFrequently)
            }
            
            if let error = uploadError {
                Text(error)
                    .font(Theme.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Theme.cardPadding)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }
    
    /// Debug: Empty state for "None" mode with responsive sizing
    @ViewBuilder
    private func noneUI(containerHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.slash")
                .font(.system(size: min(48, containerHeight * 0.2))) // Scale icon with screen size
                .foregroundStyle(.white.opacity(0.6))
                .accessibilityHidden(true)
            
            Text("No Background")
                .font(Theme.headline)
                .foregroundStyle(Theme.primaryText)
            
            Text("Your dashboard will use the default theme color")
                .font(Theme.caption)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.cardPadding)
        .frame(height: containerHeight) // Debug: Responsive height based on screen size
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No background selected. Your dashboard will use the default theme color")
        .accessibilityAddTraits(.isStaticText)
    }
    
    // MARK: - Initialization
    
    /// Debug: Initialize preview state from user preferences
    private func initializeFromPreferences() {
        let prefs = userPrefs
        
        // Set initial mode based on current background state
        if prefs.backgroundImageName == nil {
            // Check if we have custom images - if so, default to custom tab
            if !prefs.customBackgroundImages.isEmpty {
                selectedMode = .custom
            } else {
                selectedMode = .none
            }
        } else if prefs.isCustomBackground {
            selectedMode = .custom
        } else {
            selectedMode = .defaultImages
        }
        
        // Set preview to current background
        previewImageName = prefs.backgroundImageName
        previewIsCustom = prefs.isCustomBackground
        
        print("🖼️ BackgroundSelector: Initialized - mode: \(selectedMode), image: \(previewImageName ?? "nil"), isCustom: \(previewIsCustom), customImages: \(prefs.customBackgroundImages.count)")
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
    
    /// Debug: Select a custom background and save immediately
    private func selectCustomBackground(_ imageName: String) {
        guard let prefs = preferences.first else { return }
        
        // Debug: Update preview with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            previewImageName = imageName
            previewIsCustom = true
        }
        
        // Debug: Save to preferences immediately
        print("🖼️ BackgroundSelector: Changing background to custom image \(imageName)")
        prefs.backgroundImageName = imageName
        prefs.isCustomBackground = true
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
    
    /// Debug: Delete a custom image from the app
    private func deleteCustomImage(_ imageName: String) {
        guard let prefs = preferences.first else { return }
        
        // Debug: Remove from custom images array
        if let index = prefs.customBackgroundImages.firstIndex(of: imageName) {
            prefs.customBackgroundImages.remove(at: index)
        }
        
        // Debug: If this was the current background, clear it
        if prefs.backgroundImageName == imageName && prefs.isCustomBackground {
            previewImageName = nil
            previewIsCustom = false
            prefs.backgroundImageName = nil
            prefs.isCustomBackground = false
            
            // Debug: Post notification to update dashboard
            NotificationCenter.default.post(name: NSNotification.Name("BackgroundImageChanged"), object: nil)
        }
        
        // Debug: Delete file from disk
        deleteCustomBackground(imageName)
        
        // Debug: Save changes
        try? modelContext.save()
        
        print("🖼️ BackgroundSelector: Deleted custom image \(imageName)")
        HapticManager.success()
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
                
                // Debug: Add new image to custom images array (don't delete old ones)
                if !prefs.customBackgroundImages.contains(filename) {
                    prefs.customBackgroundImages.append(filename)
                }
                
                // Update preview to show new custom image
                previewImageName = filename
                previewIsCustom = true
                
                // Debug: Save to preferences immediately - set this as current background
                print("🖼️ BackgroundSelector: Custom image uploaded and added to collection - \(filename)")
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
/// Debug: Portrait thumbnail for carousel (built-in images) - responsive sizing
struct BackgroundThumbnail: View {
    let imageName: String
    let isSelected: Bool
    let isCustom: Bool
    let width: CGFloat
    let height: CGFloat
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Debug: Portrait image thumbnail without border - responsive sizing
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            // Debug: Selection indicator overlay with scaled elements
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: width, height: height)
                    .overlay(
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: min(40, height * 0.14))) // Scale with height
                            .foregroundStyle(Theme.accent)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.5))
                                    .frame(width: min(36, height * 0.13), height: min(36, height * 0.13))
                            )
                            .padding(max(8, height * 0.03)) // Scale padding
                        , alignment: .bottomTrailing
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Background image \(imageName)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select this background")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

// MARK: - Custom Background Thumbnail Component
/// Debug: Portrait thumbnail for custom uploaded images - responsive sizing with delete button
struct CustomBackgroundThumbnail: View {
    let imageName: String
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Debug: Main thumbnail content
            ZStack(alignment: .bottomTrailing) {
                // Debug: Load custom image from document directory with responsive sizing
                if let image = loadCustomImage(imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    // Debug: Fallback if image can't be loaded - responsive sizing
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.cardBackground)
                        .frame(width: width, height: height)
                        .overlay(
                            VStack {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: min(50, height * 0.18))) // Scale with height
                                    .foregroundStyle(Theme.secondaryText)
                                Text("Custom")
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        )
                }
                
                // Debug: Selection indicator overlay with scaled elements
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.clear)
                        .frame(width: width, height: height)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: min(40, height * 0.14))) // Scale with height
                                .foregroundStyle(Theme.accent)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                        .frame(width: min(36, height * 0.13), height: min(36, height * 0.13))
                                )
                                .padding(max(8, height * 0.03)) // Scale padding
                            , alignment: .bottomTrailing
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            // Debug: Delete button in top-right corner
            Button(action: {
                HapticManager.tap()
                onDelete()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: min(32, height * 0.11))) // Scale with height
                    .foregroundStyle(Theme.primaryText)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .frame(width: min(28, height * 0.10), height: min(28, height * 0.10))
                    )
                    .shadow(radius: 4)
            }
            .buttonStyle(.plain)
            .padding(max(8, height * 0.03))
            .accessibilityLabel("Delete custom image")
            .accessibilityHint("Double tap to delete this custom background image")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Custom background image")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
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

