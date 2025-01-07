//
//  SupportView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/4/24.
//  Kevin: This page will include settings for support, e.g. terms of service etc.
import SwiftUI

// Kevin: struct for the support submenu
struct SupportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Kevin: section about the application
                VStack(spacing: 0) {
                    HStack {
                        Text("App Version: 0.0.0")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Kevin: disclaimers/policy section
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        // Kevin: change to the correct view when implemented
                        NavigationLink(destination: EmptyView()) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        Divider()
                        // Kevin: change to the correct view when implemented
                        NavigationLink(destination: EmptyView()) {
                            HStack {
                                Text("Terms of Service")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
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
        .navigationTitle("Support")
    }
}
