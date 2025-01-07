//
//  PDFViewer.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 10/8/24.
//
import SwiftUI
import PDFKit

struct PDFViewer: View {
    var url: URL
    @EnvironmentObject var ttsLogic: TtsLogic
    @State private var showPageSelector = false
    @State private var pageSelection = PDFPageSelection()
    @State private var pdfDocument: PDFDocument?
    @EnvironmentObject var DB: Database
    @StateObject private var fileDirectory = FileDirectory()
    
    var body: some View {
        ZStack {
            PDFKitView(url: url)
            
            // Bottom toolbar overlay - Andy
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        if let _ = PDFDocument(url: url) {
                            showPageSelector = true
                        }
                    }) {
                        Label("Select Pages", systemImage: "text.badge.checkmark")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.9))
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPageSelector) {
            if let document = PDFDocument(url: url) {
                PDFPageSelector(pdfDocument: document, selection: $pageSelection) {
                    generateSpeechFromSelectedPages()
                }
            }
        }
    }
    
    private func generateSpeechFromSelectedPages() {
        guard let pdfDocument = PDFDocument(url: url) else { return }
        
        var selectedPages: Set<Int>
        if pageSelection.selectionMode == .range,
           let start = pageSelection.rangeStart,
           let end = pageSelection.rangeEnd {
            selectedPages = Set(start...end)
        } else {
            selectedPages = pageSelection.selectedPages
        }
        
        // Extract text from selected pages - Andy
        var extractedText = ""
        for pageIndex in selectedPages.sorted() {
            if let page = pdfDocument.page(at: pageIndex) {
                extractedText += (page.string ?? "") + "\n"
            }
        }
        
        if let pdfDocument = PDFDocument(url: url) {
            // Fetch the document record from the database
            if let document = DB.fetchDocumentByFilePath(filePath: fileDirectory.relativePath(for: url)) {
                // Set the currentDocumentId in ttsLogic
                ttsLogic.currentDocumentId = document.id
                print("Set currentDocumentId to \(document.id)")
            } else {
                print("Document not found in database for path: \(url.path)")
                ttsLogic.currentDocumentId = nil
            }
        }
        
        
        // Generate speech from extracted text - Andy
        ttsLogic.text = extractedText
        ttsLogic.generateSpeechStreaming()
    }
}

struct PDFKitView: UIViewRepresentable {
    var url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
    }
}
