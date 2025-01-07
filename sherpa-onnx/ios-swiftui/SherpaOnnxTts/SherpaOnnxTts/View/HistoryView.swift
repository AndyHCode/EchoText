//
//  HistoryView.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 9/25/24.
//
// This is the history section. As of right now it only save the last 25 tts text
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var ttsLogic: TtsLogic
    @State private var historyCount: Int = 0
    @State private var showingClearAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and Count with Clear All button
            HStack {
                Text("Text History")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingClearAlert = true
                }) {
                    Text("Clear All")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
                Text("\(ttsLogic.history.count)/25")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // List of Text History - Andy
            List {
                // Iterate over the history without reversing the original array - Andy
                ForEach(ttsLogic.history.indices.reversed(), id: \.self) { index in
                    let entry = ttsLogic.history[index]
                    HStack {
                        // Text with ellipsis if too long
                        Text(entry)
                            .font(.headline)
                            .lineLimit(1) // Limit to 1 line for better UI - Andy
                            .truncationMode(.tail)
                        
                        Spacer()
                        
                        // Copy Button - Andy
                        Button(action: {
                            copyToClipboard(text: entry)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            copyToClipboard(text: entry)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button(role: .destructive) {
                            ttsLogic.history.remove(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    // Convert the indices from the reversed list to the original list - Andy
                    let originalIndices = indexSet.map { ttsLogic.history.count - 1 - $0 }
                    // Sort in descending order to avoid index shifting issues - Andy
                    for index in originalIndices.sorted(by: >) {
                        ttsLogic.history.remove(at: index)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Text History")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear All History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                ttsLogic.history.removeAll()
            }
        } message: {
            Text("Are you sure you want to clear all history? This cannot be undone.")
        }
        .onAppear {
            self.historyCount = ttsLogic.history.count
        }
    }
    
    // Function to copy the text to clipboard - Andy
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        print("Copied to clipboard: \(text)")
    }
}
