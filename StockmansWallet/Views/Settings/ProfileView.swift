//
//  ProfileView.swift
//  StockmansWallet
//
//  Farmer Profile - Personal information and credentials
//  Debug: Displays and allows editing of user profile information
//

import SwiftUI
import SwiftData
import PhotosUI

// Debug: Profile view for farmer/user information
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferences]
    
    @State private var isEditing = false
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var role: UserRole?
    @State private var twoFactorEnabled = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    
    private var userPrefs: UserPreferences {
        preferences.first ?? UserPreferences()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                // Debug: Profile header with avatar placeholder
                VStack(spacing: 16) {
                    // Avatar circle with photo picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            // Avatar image or initials
                            ZStack {
                                Circle()
                                    .fill(Theme.accent.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                if let profileImage {
                                    // Display uploaded photo
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else if let first = userPrefs.firstName?.first,
                                          let last = userPrefs.lastName?.first {
                                    // Display initials
                                    Text("\(String(first))\(String(last))")
                                        .font(.system(size: 36, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                } else {
                                    // Default person icon
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            
                            // Edit badge
                            ZStack {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: -2, y: -2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change profile photo")
                    .padding(.top, 20)
                    
                    // Name display
                    if let firstName = userPrefs.firstName,
                       let lastName = userPrefs.lastName {
                        Text("\(firstName) \(lastName)")
                            .font(Theme.title)
                            .foregroundStyle(Theme.primaryText)
                    } else {
                        Text("Set up your profile")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    
                    if let userRole = userPrefs.userRole {
                        Text(userRole.rawValue)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                
                // Debug: Personal Information section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundStyle(Theme.accent)
                        Text("Personal Information")
                            .font(Theme.headline)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        Button {
                            HapticManager.tap()
                            isEditing = true
                        } label: {
                            Text("Edit")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    
                    Divider()
                        .background(Theme.separator)
                    
                    ProfileInfoRow(
                        icon: "person.fill",
                        label: "First Name",
                        value: userPrefs.firstName ?? "Not set"
                    )
                    
                    ProfileInfoRow(
                        icon: "person.fill",
                        label: "Last Name",
                        value: userPrefs.lastName ?? "Not set"
                    )
                    
                    ProfileInfoRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: userPrefs.email ?? "Not set"
                    )
                    
                    ProfileInfoRow(
                        icon: "briefcase.fill",
                        label: "Role",
                        value: userPrefs.userRole?.rawValue ?? "Not set"
                    )
                }
                .padding(Theme.cardPadding)
                .cardStyle()
                .padding(.horizontal)
            }
            .padding(.bottom, 100)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isEditing) {
            EditProfileView(userPrefs: userPrefs)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                await loadPhoto(from: newValue)
            }
        }
        .onAppear {
            loadProfileData()
            loadExistingPhoto()
        }
    }
    
    // Debug: Load profile data into state
    private func loadProfileData() {
        firstName = userPrefs.firstName ?? ""
        lastName = userPrefs.lastName ?? ""
        email = userPrefs.email ?? ""
        role = userPrefs.userRole
        twoFactorEnabled = userPrefs.twoFactorEnabled
    }
    
    // Debug: Load existing profile photo if available
    private func loadExistingPhoto() {
        guard let photoData = userPrefs.profilePhotoData,
              let uiImage = UIImage(data: photoData) else {
            profileImage = nil
            return
        }
        profileImage = Image(uiImage: uiImage)
    }
    
    // Debug: Load photo from PhotosPicker selection
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // Load the image data
            guard let imageData = try await item.loadTransferable(type: Data.self) else { return }
            
            // Compress the image to a reasonable size
            guard let uiImage = UIImage(data: imageData) else { return }
            let compressedData = compressImage(uiImage)
            
            // Update the model
            await MainActor.run {
                userPrefs.profilePhotoData = compressedData
                try? modelContext.save()
                loadExistingPhoto()
                HapticManager.success()
            }
        } catch {
            print("Error loading photo: \(error)")
            await MainActor.run {
                HapticManager.error()
            }
        }
    }
    
    // Debug: Compress image to reduce storage size
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize to max 512x512 while maintaining aspect ratio
        let maxSize: CGFloat = 512
        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Compress to JPEG with 0.8 quality
        return resizedImage?.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Profile Info Row
// Debug: Reusable row for displaying profile information
struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
                Text(value)
                    .font(Theme.body)
                    .foregroundStyle(Theme.primaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Connection Status Row
// Debug: Shows connection status for external services
struct ConnectionStatusRow: View {
    let icon: String
    let name: String
    let isConnected: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(name)
                .font(Theme.body)
                .foregroundStyle(Theme.primaryText)
            
            Spacer()
            
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Theme.positiveChange : Theme.secondaryText.opacity(0.3))
                    .frame(width: 8, height: 8)
                Text(isConnected ? "Connected" : "Not connected")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

// MARK: - Edit Profile View
// Debug: Sheet for editing profile information
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let userPrefs: UserPreferences
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var selectedRole: UserRole?
    
    init(userPrefs: UserPreferences) {
        self.userPrefs = userPrefs
        _firstName = State(initialValue: userPrefs.firstName ?? "")
        _lastName = State(initialValue: userPrefs.lastName ?? "")
        _email = State(initialValue: userPrefs.email ?? "")
        _selectedRole = State(initialValue: userPrefs.userRole)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Details") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .listRowBackground(Theme.cardBackground)
                
                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        Text("Select a role...").tag(nil as UserRole?)
                        ForEach(UserRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role as UserRole?)
                        }
                    }
                }
                .listRowBackground(Theme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.success()
                        saveChanges()
                        dismiss()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
    
    // Debug: Save changes to UserPreferences
    private func saveChanges() {
        userPrefs.firstName = firstName.isEmpty ? nil : firstName
        userPrefs.lastName = lastName.isEmpty ? nil : lastName
        userPrefs.email = email.isEmpty ? nil : email
        userPrefs.userRole = selectedRole
        
        try? modelContext.save()
    }
}

