//
//  PasswordUnlockView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/5/24.
//

import SwiftUI

struct PasswordUnlockView: View {
    @EnvironmentObject var passwordManager: PasswordManager
    @EnvironmentObject var themeSettings: ThemeSettings
    @Binding var isLocked: Bool
    @State private var passwordInput = ""
    @State private var showError = false
    @State private var showRecoverySheet = false
    @State private var recoveryCodeInput = ""
    @State private var recoveryError = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Enter Passcode")
                    .font(.title)
                    .padding()
                
                
                PasscodeField(text: $passwordInput, placeholder: "Passcode")
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                
                if showError {
                    Text("Incorrect passcode. Please try again.")
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    if passwordManager.validatePassword(passwordInput) {
                        isLocked = false
                        passwordInput = ""
                        showError = false
                    } else {
                        showError = true
                        passwordInput = ""
                    }
                }) {
                    Text("Unlock")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    // Show the recovery code sheet
                    showRecoverySheet = true
                }) {
                    Text("Forgot Passcode?")
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
            .padding()
            .sheet(isPresented: $showRecoverySheet) {
                recoverySheetContent
            }
            .onAppear {
                passwordInput = ""
                showError = false
            }
            .preferredColorScheme(
                themeSettings.overrideSystemTheme ? themeSettings.selectedTheme : nil
            )
        }
    }
    
    var recoverySheetContent: some View {
        VStack(spacing: 20) {
            Text("Enter Recovery Code")
                .font(.headline)
            
            TextField("Recovery Code", text: $recoveryCodeInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            if recoveryError {
                Text("Invalid recovery code. Please try again.")
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel") {
                    recoveryError = false
                    recoveryCodeInput = ""
                    showRecoverySheet = false
                }
                .padding()
                
                Spacer()
                
                Button("Submit") {
                    if passwordManager.recoverAccount(with: recoveryCodeInput) {
                        // Kevin: Recovery code was valid, passcode removed
                        isLocked = false
                        showRecoverySheet = false
                    } else {
                        // Kevin: Invalid recovery code
                        recoveryError = true
                    }
                    recoveryCodeInput = ""
                }
                .padding()
            }
        }
        .padding()
    }
}

