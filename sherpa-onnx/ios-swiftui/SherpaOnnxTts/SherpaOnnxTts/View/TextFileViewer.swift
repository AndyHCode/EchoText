//
//  TextFileViewer.swift
//  SherpaOnnxTts
//
//  Created by Ahmad Ghaddar on 11/11/24.
//

import SwiftUI

struct TextFileViewer: View {
    let url: URL
    @State private var textContent: String = ""
    
    var body: some View {
        ScrollView {
            Text(textContent)
                .padding()
        }
        .onAppear {
            loadTextContent()
        }
    }
    
    private func loadTextContent() {
        do {
            textContent = try String(contentsOf: url)
        } catch {
            textContent = "Failed to load text content: \(error.localizedDescription)"
        }
    }
}
