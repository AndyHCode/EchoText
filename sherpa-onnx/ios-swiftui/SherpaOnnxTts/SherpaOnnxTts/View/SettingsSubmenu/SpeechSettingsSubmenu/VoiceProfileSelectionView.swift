//
//  VoiceProfileSelectionView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/28/24.
//

import SwiftUI

struct VoiceProfileSelectionView: View {
    @EnvironmentObject var voiceProfileManager: VoiceProfileManager
    @EnvironmentObject var database: Database
    
    @State private var profiles: [Profile] = []
    
    @State private var showAddProfileAlert = false
    @State private var newProfileName = ""
    @State private var showRenameProfileAlert = false
    @State private var renameProfileName = ""
    @State private var profileToRename: Profile?
    @State private var profileToDelete: Profile?
    @State private var showDeleteConfirmation = false
    
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    var body: some View {
        List {
            ForEach(profiles, id: \.profileName) { profile in
                HStack {
                    Text(profile.profileName)
                    Spacer()
                    if profile.profileName == voiceProfileManager.profileName {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    voiceProfileManager.switchToProfile(named: profile.profileName)
                }
                .contextMenu {
                    if profile.profileName != "Default" {
                        Button("Rename") {
                            profileToRename = profile
                            renameProfileName = profile.profileName
                            showRenameProfileAlert = true
                        }
                        Button("Delete", role: .destructive) {
                            profileToDelete = profile
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Voice Profile")
        .navigationBarItems(trailing:
                                Button(action: {
            showAddProfileAlert = true
        }) {
            Image(systemName: "plus")
        }
        )
        .onAppear {
            self.profiles = self.database.fetchAllProfiles()
        }
        .alert("Add New Profile", isPresented: $showAddProfileAlert, actions: {
            TextField("Profile Name", text: $newProfileName)
            Button("Add") {
                addProfile()
            }
            Button("Cancel", role: .cancel) {}
        })
        .alert("Rename Profile", isPresented: $showRenameProfileAlert, actions: {
            TextField("New Profile Name", text: $renameProfileName)
            Button("Rename") {
                renameProfile()
            }
            Button("Cancel", role: .cancel) {}
        })
        .alert("Delete Profile", isPresented: $showDeleteConfirmation, actions: {
            Button("Delete", role: .destructive) {
                deleteProfile()
            }
            Button("Cancel", role: .cancel) {}
        }, message: {
            Text("Are you sure you want to delete the profile \"\(profileToDelete?.profileName ?? "")\"?")
        })
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }
    
    private func addProfile() {
        let success = voiceProfileManager.addProfile(named: newProfileName)
        if success {
            voiceProfileManager.switchToProfile(named: newProfileName)
            self.profiles = self.database.fetchAllProfiles()
            newProfileName = ""
        } else {
            errorMessage = "Failed to add profile. Please try a different name."
            showErrorAlert = true
            newProfileName = ""
        }
    }
    
    private func renameProfile() {
        guard let profile = profileToRename else { return }
        let success = voiceProfileManager.renameProfile(from: profile.profileName, to: renameProfileName)
        if success {
            if voiceProfileManager.profileName == profile.profileName {
                voiceProfileManager.profileName = renameProfileName
            }
            self.profiles = self.database.fetchAllProfiles()
            renameProfileName = ""
            profileToRename = nil
        } else {
            errorMessage = "Failed to rename profile. The name might already be in use."
            showErrorAlert = true
            renameProfileName = ""
        }
    }
    
    private func deleteProfile() {
        guard let profile = profileToDelete else { return }
        let success = voiceProfileManager.deleteProfile(named: profile.profileName)
        if success {
            if voiceProfileManager.profileName == profile.profileName {
                voiceProfileManager.switchToProfile(named: "Default")
            }
            self.profiles = self.database.fetchAllProfiles()
            profileToDelete = nil
        } else {
            errorMessage = "Failed to delete profile."
            showErrorAlert = true
        }
    }
}
