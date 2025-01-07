//
//  AudioMetadataView.swift
//  SherpaOnnxTts
//
//  Created by Ahmad Ghaddar on 11/5/24.
//

import SwiftUI

struct AudioMetadataView: View {
    let audio: AudioRecord
    @EnvironmentObject var DB: Database
    @Environment(\.presentationMode) var presentationMode
    
    
    @State private var documentName: String? = nil
    
    var body: some View {
        NavigationView {
            List {
                
                HStack {
                    Text("Date & Time")
                    Spacer()
                    Text(audio.dateGenerated)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Name")
                    Spacer()
                    Text(audio.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Length")
                    Spacer()
                    Text(audio.length.formattedTime())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Model")
                    Spacer()
                    Text(audio.model)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Speed")
                    Spacer()
                    Text("\(audio.speed.formattedString)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Pitch")
                    Spacer()
                    Text("\(audio.pitch.formattedString)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Document")
                    Spacer()
                    if let documentName = documentName {
                        Text(documentName)
                            .foregroundColor(.secondary)
                    } else {
                        Text("None")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Favorite")
                    Spacer()
                    Text(audio.isFavorite ? "Yes" : "No")
                        .foregroundColor(.secondary)
                }
                
                
                
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("More Info", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let documentId = audio.documentId {
                    // Fetch the document name
                    if let document = DB.fetchDocumentById(documentId: documentId) {
                        self.documentName = document.documentName
                    } else {
                        self.documentName = "Unknown Document"
                    }
                }
            }
        }
    }
}

// Extension to format seconds to hh:mm:ss
extension Int {
    func formattedTime() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
    }
}

extension Double {
    var formattedString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        // Maximum of 1 decimal place
        formatter.maximumFractionDigits = 1
        // No minimum decimal places (to remove trailing zeros)
        formatter.minimumFractionDigits = 0
        // Ensure at least one integer digit
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

