// ContentView.swift
// SwiftUI view for text-to-speech
//
//  Edited by kevin Xing on 9/25/24.
//  Relocated UI elements and logic to their respective files.
//  This new ContentView will only manage tabs and shared objects currently
import SwiftUI

struct ContentView: View {
    // Ahmad: Reformated @StateObject code for DB and ttsLogic. Added init() and customized tab bar appearance.
    // kevin: removed @stateObject and instead using new @envrionmentobject

    //  kevin: inside views that need the objects, use the following code as refernce:
    // @EnvironmentObject var DB: Database
    // @EnvironmentObject var ttsLogic: TtsLogic
    
    @EnvironmentObject var themeSettings: ThemeSettings
    
    init() {
        // Customize the tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemGray6
        
        // Apply the appearance to the UITabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        
        // For iOS 15 and later, also set the scrollEdgeAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    var body: some View {
        TabView {
            // tab for the mainpage, which handles text inputs and copy-paste
            // pass the instance to MainPageView
            MainPageView()
                .tabItem {
                    Label("Main", systemImage: "house")
                }
            
            // Ahmad: Tab for the Generated page
            GeneratedView()
                .tabItem {
                    Label("Generated", systemImage: "music.note.list")
                }
            // Ahmad: Tab for the Documents page
            DocumentsView()
                .tabItem {
                    Label("Documents", systemImage: "doc")
                }
            HistoryView()
                .tabItem {
                    Label("Text History", systemImage: "clock.fill")
                }
            // tab for settings page
            // pass the instance to SettingsView
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(
            themeSettings.overrideSystemTheme ? themeSettings.selectedTheme : nil
        )
    }
}
