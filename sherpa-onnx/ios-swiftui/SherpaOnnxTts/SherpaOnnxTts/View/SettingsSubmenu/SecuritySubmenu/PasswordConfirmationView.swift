//
//  PasswordConfirmationView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/5/24.
//

import SwiftUI

struct PasswordConfirmationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var passwordManager: PasswordManager
    @State private var currentPassword = ""
    @State private var showError = false
    @EnvironmentObject var themeSettings: ThemeSettings
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Confirm Passcode")) {
                        PasscodeField(text: $currentPassword, placeholder: "Enter Current Passcode")
                    }
                    
                    if showError {
                        Text("Incorrect passcode. Please try again.")
                            .foregroundColor(.red)
                    }
                }
                
                Button(action: {
                    if passwordManager.validatePassword(currentPassword) {
                        passwordManager.removePassword()
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        showError = true
                        currentPassword = ""
                    }
                }) {
                    Text("Remove Password")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Remove Password")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .preferredColorScheme(
                themeSettings.overrideSystemTheme ? themeSettings.selectedTheme : nil
            )
        }
    }
}
