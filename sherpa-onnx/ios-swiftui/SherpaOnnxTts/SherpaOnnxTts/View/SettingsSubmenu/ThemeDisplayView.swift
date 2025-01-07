//
//  ThemeDisplayView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/4/24.
//  Kevin: This page will include settings for appearance, theme, and other UI related things, e.g. dark/light mode, text size, etc.
import SwiftUI

// Kevin: struct for the theme & display settings subpage
struct ThemeDisplayView: View {
    @EnvironmentObject var themeSettings: ThemeSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 0) {
                    // Kevin: toggle to override system theme
                    HStack {
                        Toggle(isOn: $themeSettings.overrideSystemTheme) {
                            Text("Override System Theme")
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                    
                    // Kevin: display theme selection if override toggle is on
                    if themeSettings.overrideSystemTheme {
                        Divider()
                        HStack {
                            Text("Select Theme")
                                .foregroundColor(.primary)
                            Spacer()
                            Picker(selection: Binding(
                                get: {
                                    themeSettings.selectedTheme == .dark ? "Dark" : "Light"
                                },
                                set: { value in
                                    themeSettings.selectedTheme = value == "Dark" ? .dark : .light
                                }
                            ), label: Text("")) {
                                Text("Light").tag("Light")
                                Text("Dark").tag("Dark")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
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
        .navigationTitle("Theme & Display")
        .preferredColorScheme(themeSettings.overrideSystemTheme ? themeSettings.selectedTheme : nil)
    }
}
