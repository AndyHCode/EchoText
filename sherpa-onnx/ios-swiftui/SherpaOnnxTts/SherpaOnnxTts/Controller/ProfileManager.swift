//
//  ProfileManager.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/25/24.
// kevin: file that manages profile related logic
import Combine
import SwiftUI

class VoiceProfileManager: ObservableObject {
    @Published var id: Int32
    @Published var profileName: String
    @Published var pitch: Double
    @Published var speed: Double
    @Published var model: String
    
    var DB: Database
    private var cancellables = Set<AnyCancellable>()
    
    init(DB: Database) {
        self.DB = DB
        
        // kevin: load current profile from NSUserdefault or create a default one
        if let savedProfileName = UserDefaults.standard.string(forKey: "currentVoiceProfileName"),
           let profile = DB.loadProfile(profileName: savedProfileName) {
            print("Loading profile: \(savedProfileName)")
            self.id = profile.id
            self.profileName = profile.profileName
            self.pitch = profile.pitch
            self.speed = profile.speed
            self.model = profile.model
        } else {
            // kevin: create a default profile
            print("Creating default profile")
            self.profileName = "Default"
            self.pitch = 1.0
            self.speed = 1.0
            self.model = "amy"
            // kevin: save the default profile to the database
            // let defaultProfile = Profile(id: 0, profileName: self.profileName, pitch: self.pitch, speed: self.speed, model: self.model)
            let defaultProfile = Profile(id: 0, profileName: "Default", pitch: Double(1.0), speed: Double(1.0), model: "amy")
            if let id = DB.saveProfile(defaultProfile) {
                self.id = id
            } else {
                fatalError("Failed to save default profile.")
            }
            UserDefaults.standard.set(self.profileName, forKey: "currentVoiceProfileName")
        }
        setupObservers()
    }
    
    // kevin: observers that updates the database when any of the published vars for a profile changes
    private func setupObservers() {
        Publishers.CombineLatest3($pitch, $speed, $model)
            .sink { [weak self] pitch, speed, model in
                guard let self = self else { return }
                let profile = Profile(id: self.id, profileName: self.profileName, pitch: pitch, speed: speed, model: model)
                self.DB.updateProfile(profile)
            }
            .store(in: &cancellables)
        
        $profileName
            .sink { [weak self] profileName in
                guard let self = self else { return }
                UserDefaults.standard.set(profileName, forKey: "currentVoiceProfileName")
                if let newProfile = self.DB.loadProfile(profileName: profileName) {
                    self.pitch = newProfile.pitch
                    self.speed = newProfile.speed
                    self.model = newProfile.model
                } else {
                }
            }
            .store(in: &cancellables)
    }
    
    // kevin: saves the current profile
    private func saveCurrentProfile() {
        let profile = Profile(id: self.id, profileName: self.profileName, pitch: self.pitch, speed: self.speed, model: self.model)
        DB.updateProfile(profile)
    }
    
    // kevin: function to switch the current active profile
    func switchToProfile(named profileName: String) {
        // kevin: save any changes before switching
        self.saveCurrentProfile()
        
        // kevin: load new profile from DB
        if let newProfile = DB.loadProfile(profileName: profileName) {
            // kevin: temporarily remove observers to prevent unwanted updates
            cancellables.removeAll()
            
            self.id = newProfile.id
            self.profileName = newProfile.profileName
            self.pitch = newProfile.pitch
            self.speed = newProfile.speed
            self.model = newProfile.model
            
            setupObservers()
            
            // kevin: save the current profile name to UserDefaults
            UserDefaults.standard.set(profileName, forKey: "currentVoiceProfileName")
        } else {
            print("Profile '\(profileName)' not found. Switching to default profile.")
            if profileName != "Default" {
                switchToProfile(named: "Default")
            }
        }
    }
    
    // kevin: adds a new profile with the given name.
    func addProfile(named newProfileName: String) -> Bool {
        guard !newProfileName.isEmpty else { return false }
        if newProfileName == "Default" {
            print("Cannot use 'Default' as a profile name.")
            return false
        }
        if DB.loadProfile(profileName: newProfileName) != nil {
            print("Profile name '\(newProfileName)' already exists.")
            return false
        }
        let newProfile = Profile(id: 0, profileName: newProfileName, pitch: 1.0, speed: 1.0, model: "amy")
        if let id = DB.saveProfile(newProfile) {
            // Switch to the new profile
            self.switchToProfile(named: newProfileName)
            return true
        } else {
            print("Failed to save new profile.")
            return false
        }
    }
    
    // kevin: renames an existing profile.
    func renameProfile(from oldName: String, to newName: String) -> Bool {
        guard !newName.isEmpty else { return false }
        if newName == "Default" {
            print("Cannot rename to 'Default'.")
            return false
        }
        if DB.loadProfile(profileName: newName) != nil {
            print("Profile name '\(newName)' already exists.")
            return false
        }
        if DB.renameProfile(oldName: oldName, newName: newName) {
            if self.profileName == oldName {
                self.profileName = newName
                UserDefaults.standard.set(newName, forKey: "currentVoiceProfileName")
            }
            return true
        } else {
            print("Failed to rename profile.")
            return false
        }
    }
    
    // kevin: deletes a profile with the given name.
    func deleteProfile(named profileName: String) -> Bool {
        if profileName == "Default" {
            print("Cannot delete the default profile.")
            return false
        }
        if DB.deleteProfile(profileName: profileName) {
            if self.profileName == profileName {
                self.switchToProfile(named: "Default")
            }
            return true
        } else {
            print("Failed to delete profile.")
            return false
        }
    }
    
}

