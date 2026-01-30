import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager

    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Logo / Title
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.split.3x3")
                        .font(.system(size: 60))
                        .foregroundStyle(DesignSystem.Colors.primary)

                    Text("Tables")
                        .font(.system(size: 36, weight: .bold))

                    Text("Collaborate on decisions together")
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.mutedText)
                }

                Spacer()

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))

                    if isSignUp {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .autocorrectionDisabled()
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))

                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .autocorrectionDisabled()
                            .padding()
                            .background(DesignSystem.Colors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    }

                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await authenticate()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && firstName.isEmpty))

                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            firstName = ""
                            lastName = ""
                            errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
                .padding(.horizontal, DesignSystem.Padding.screen)

                Spacer()
            }
            .background(DesignSystem.Colors.screenBackground)
        }
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                // Create display name from first/last name
                let displayName = lastName.isEmpty ? firstName : "\(firstName) \(lastName)"
                try await supabaseManager.signUp(email: email, password: password, displayName: displayName, firstName: firstName, lastName: lastName.isEmpty ? nil : lastName)
            } else {
                try await supabaseManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(SupabaseManager())
}
