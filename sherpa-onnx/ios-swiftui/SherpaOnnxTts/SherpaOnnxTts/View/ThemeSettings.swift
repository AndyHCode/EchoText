//
//  ThemeSettings.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/12/24.
//  Kevin: store current them settings in NSUserdefaults for the application

import SwiftUI

class ThemeSettings: ObservableObject {
    @Published var overrideSystemTheme: Bool {
        didSet {
            UserDefaults.standard.set(overrideSystemTheme, forKey: "overrideSystemTheme")
            applyTheme()
        }
    }
    
    @Published var selectedTheme: ColorScheme? {
        didSet {
            if let theme = selectedTheme {
                UserDefaults.standard.set(theme == .dark ? "dark" : "light", forKey: "selectedTheme")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedTheme")
            }
            applyTheme()
        }
    }
    
    init() {
        // Kevin: load settings from NSUserdefault
        self.overrideSystemTheme = UserDefaults.standard.bool(forKey: "overrideSystemTheme")
        
        if let themeString = UserDefaults.standard.string(forKey: "selectedTheme") {
            self.selectedTheme = themeString == "dark" ? .dark : .light
        } else {
            self.selectedTheme = nil
        }
    }
    
    // Kevin: function to reload/apply theme
    func applyTheme() {
        objectWillChange.send()
    }
}

