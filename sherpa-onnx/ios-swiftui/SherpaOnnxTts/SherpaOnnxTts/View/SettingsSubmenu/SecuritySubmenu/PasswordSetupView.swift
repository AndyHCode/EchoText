//
//  PasswordSetupView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/5/24.
//

import SwiftUI

struct PasswordSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var passwordManager: PasswordManager
    @EnvironmentObject var themeSettings: ThemeSettings
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var hasAttemptedSave = false
    @State private var showRecoveryAlert = false
    @State private var recoveryCode: String?
    @State private var initialHasPassword = false
    
    var body: some View {
        NavigationView {
            Form {
                if initialHasPassword {
                    Section(header: Text("Current Passcode")) {
                        PasscodeField(text: $currentPassword, placeholder: "Enter Current Passcode")
                    }
                }
                
                Section(header: Text("New Passcode")) {
                    PasscodeField(text: $newPassword, placeholder: "Enter New Passcode")
                        .onChange(of: newPassword) { _ in
                            validateAndUpdateError()
                        }
                    PasscodeField(text: $confirmPassword, placeholder: "Confirm New Passcode")
                        .onChange(of: confirmPassword) { _ in
                            validateAndUpdateError()
                        }
                }
                
                Section {
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else {
                        Text("Passcode must be 4 to 6 digits.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(initialHasPassword ? "Change Passcode" : "Add Passcode")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    savePassword()
                }
            )
            .alert(isPresented: $showRecoveryAlert) {
                Alert(
                    title: Text("Recovery Code"),
                    message: Text("Your recovery code is \(recoveryCode ?? "N/A"). Please store it securely."),
                    dismissButton: .default(Text("OK"), action: {
                        // kevin: update PasswordManager after showing the recovery code
                        passwordManager.finalizeNewPassword(newPassword)
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            }
            .onAppear {
                // kevin: store the initial state of hasPassword when the view appears
                self.initialHasPassword = passwordManager.hasPassword
            }
            .preferredColorScheme(
                themeSettings.overrideSystemTheme ? themeSettings.selectedTheme : nil
            )
        }
    }
    
    func validateAndUpdateError() {
        // kevin: only update error message if the user has attempted to save
        if hasAttemptedSave {
            validateInputs()
        }
    }
    
    func validateInputs() {
        // kevin: reset error message
        errorMessage = ""
        showError = false
        
        // kevin: jf the user has a passcode, validate the current password
        if initialHasPassword && hasAttemptedSave {
            if currentPassword.isEmpty {
                errorMessage = "Current passcode cannot be empty."
                showError = true
                return
            }
            if !passwordManager.validatePassword(currentPassword) {
                errorMessage = "Current passcode is incorrect."
                showError = true
                return
            }
        }
        
        // kevin: validate new passcode
        guard !newPassword.isEmpty else {
            errorMessage = "New passcode cannot be empty."
            showError = true
            return
        }
        
        // kevin: validate passcode format (4-6 digits)
        let passcodeRegex = "^[0-9]{4,6}$"
        let passcodePredicate = NSPredicate(format: "SELF MATCHES %@", passcodeRegex)
        if !passcodePredicate.evaluate(with: newPassword) {
            errorMessage = "Passcode must be 4 to 6 digits."
            showError = true
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Passcodes do not match."
            showError = true
            return
        }
    }
    
    func savePassword() {
        hasAttemptedSave = true
        
        validateInputs()
        
        // kevin: ff there is an error, prevent saving
        if showError {
            return
        }
        
        // kevin: generate a temporary recovery code
        let code = passwordManager.generateTemporaryRecoveryCode(for: newPassword)
        if let code = code {
            self.recoveryCode = code
            self.showRecoveryAlert = true
        } else {
            // kevin: in case something went wrong, simply dismiss
            presentationMode.wrappedValue.dismiss()
        }
    }
}
