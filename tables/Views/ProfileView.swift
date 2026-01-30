import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false
    @State private var isEditingProfile = false
    @State private var editedFirstName = ""
    @State private var editedLastName = ""
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.15))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(initials)
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(DesignSystem.Colors.primary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(supabaseManager.currentFullName ?? supabaseManager.currentDisplayName ?? "User")
                                .font(.headline)
                            Text(supabaseManager.currentUserEmail ?? "")
                                .font(.subheadline)
                                .foregroundStyle(DesignSystem.Colors.mutedText)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button {
                        editedFirstName = supabaseManager.currentFirstName ?? ""
                        editedLastName = supabaseManager.currentLastName ?? ""
                        isEditingProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            await signOut()
                        }
                    } label: {
                        HStack {
                            if isSigningOut {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                            Text("Sign Out")
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                NavigationStack {
                    Form {
                        Section("Name") {
                            TextField("First Name", text: $editedFirstName)
                            TextField("Last Name", text: $editedLastName)
                        }

                        if let saveError {
                            Section {
                                Text(saveError)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .navigationTitle("Edit Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isEditingProfile = false
                                saveError = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                Task {
                                    await saveProfile()
                                }
                            }
                            .disabled(editedFirstName.isEmpty || isSaving)
                        }
                    }
                }
            }
        }
    }

    private var initials: String {
        // Use first letter of first name + first letter of last name if available
        if let first = supabaseManager.currentFirstName, !first.isEmpty {
            let firstInitial = String(first.prefix(1)).uppercased()
            if let last = supabaseManager.currentLastName, !last.isEmpty {
                let lastInitial = String(last.prefix(1)).uppercased()
                return firstInitial + lastInitial
            }
            return firstInitial
        }

        // Fall back to display name or email
        let name = supabaseManager.currentDisplayName ?? supabaseManager.currentUserEmail ?? "U"
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func signOut() async {
        isSigningOut = true
        do {
            try await supabaseManager.signOut()
            dismiss()
        } catch {
            // Handle error
        }
        isSigningOut = false
    }

    private func saveProfile() async {
        isSaving = true
        saveError = nil

        do {
            try await supabaseManager.updateProfile(firstName: editedFirstName, lastName: editedLastName)
            isEditingProfile = false
        } catch {
            saveError = error.localizedDescription
        }

        isSaving = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(SupabaseManager())
}
