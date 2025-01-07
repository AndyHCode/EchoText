//
//  SecurityView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/4/24.
//  Kevin: This page will include settings for security, e.g. password, encryption, etc.
//  Kevin: struct for the security settings page
import SwiftUI

struct SecurityView: View {
    // @State private var hasPassword = false  // kevin: local flag, tie to security logic when implemented
    @EnvironmentObject var passwordManager: PasswordManager
    @State private var showPasswordSetup = false
    @State private var showPasswordConfirmation = false  // New state variable
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 0) {
                    if passwordManager.hasPassword{
                        // kevin: show "Change Password" and "Remove Password" buttons if has password
                        VStack(spacing: 0) {
                            // "Change Password" Button
                            Button(action: {
                                showPasswordSetup = true
                            }) {
                                HStack {
                                    Text("Change Passcode")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                            }
                            
                            Divider()
                            
                            // "Remove Password" Button
                            Button(action: {
                                showPasswordConfirmation = true
                            }) {
                                HStack {
                                    Text("Remove Passcode")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    } else {
                        // Kevin: show "Add Password" button if no password
                        Button(action: {
                            // Kevin: placeholder action to add password
                            showPasswordSetup = true
                        }) {
                            HStack {
                                Text("Add Passcode")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.top, 32)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Security")
        .sheet(isPresented: $showPasswordSetup) {
            PasswordSetupView()
        }
        .sheet(isPresented: $showPasswordConfirmation) {
            PasswordConfirmationView()
        }
    }
}
