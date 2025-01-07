//
//  SherpaOnnxTtsApp.swift
//  SherpaOnnxTts
//
//  Created by fangjun on 2023/11/23.
//

import SwiftUI

@main
struct SherpaOnnxTtsApp: App {
    // kevin: create the FileDirectory instance asap on app launch
    @StateObject private var fileDirectory = FileDirectory()
    // kevin: moved the creation of ttsLogic and database instance from content view to here
    @StateObject private var DB: Database
    @StateObject private var ttsLogic: TtsLogic
    @StateObject private var voiceProfileManager: VoiceProfileManager
    // kevin: init to inject used instances into each obj
    
    @StateObject private var passwordManager = PasswordManager()
    @StateObject private var themeSettings = ThemeSettings()
    @State private var isLocked = true
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let fileDirectoryInstance = FileDirectory()
        let dbInstance = Database(fileDirectory: fileDirectoryInstance)
        _DB = StateObject(wrappedValue: dbInstance)
        fileDirectoryInstance.createApplicationSupportDirectories()
        dbInstance.openDatabase()
        dbInstance.createTables()
        let profileManager = VoiceProfileManager(DB: dbInstance)
        _voiceProfileManager = StateObject(wrappedValue: profileManager)
        _ttsLogic = StateObject(wrappedValue: TtsLogic(DB: dbInstance, fileDirectory: fileDirectoryInstance, voiceProfileManager: profileManager))
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if passwordManager.hasPassword && isLocked {
                    PasswordUnlockView(isLocked: $isLocked)
                        .environmentObject(passwordManager)
                        .environmentObject(themeSettings)
                } else {
                    ContentView()
                        .environmentObject(fileDirectory)
                        .environmentObject(DB)
                        .environmentObject(ttsLogic)
                        .environmentObject(voiceProfileManager)
                        .environmentObject(passwordManager)
                        .environmentObject(themeSettings)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if passwordManager.hasPassword {
                switch newPhase {
                case .active:
                    // Do nothing when the app becomes active
                    break
                case .inactive:
                    break
                case .background:
                    // Lock the app when it goes to the background
                    isLocked = true
                    // Reset the justCreatedPassword flag
                    if passwordManager.justCreatedPassword {
                        passwordManager.justCreatedPassword = false
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}
