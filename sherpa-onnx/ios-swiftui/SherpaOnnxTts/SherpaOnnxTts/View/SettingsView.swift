//
//  SettingsView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 9/25/24.
//

import SwiftUI

// Kevin: struct containing the settings page UI elements
struct SettingsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                // Kevin: first group of settings for things that might be used more in a VStack. (Speech Settings, Theme & Display), more can be added.
                VStack(spacing: 32) {
                    VStack(spacing: 0) {
                        // Kevin: a submenu styled link to the speech settings submenu page
                        NavigationLink(destination: SpeechSettingsView()) {
                            HStack {
                                Text("Speech Settings")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        Divider()
                        // Kevin: a submenu styled link to the theme and display submenu page
                        NavigationLink(destination: ThemeDisplayView()) {
                            HStack {
                                Text("Theme & Display")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Kevin: second group, less frequency to be accessed (Security, Advanced, Support) more can be added
                    VStack(spacing: 0) {
                        // Kevin: a submenu styled link to the security submenu page
                        NavigationLink(destination: SecurityView()) {
                            HStack {
                                Text("Security")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        Divider()
                        // Kevin: a submenu styled link to the security submenu page
                        NavigationLink(destination: AdvancedView()) {
                            HStack {
                                Text("Advanced")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        Divider()
                        // Kevin: a submenu styled link to the support submenu page
                        NavigationLink(destination: SupportView()) {
                            HStack {
                                Text("Support")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.top, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
        }
    }
}
