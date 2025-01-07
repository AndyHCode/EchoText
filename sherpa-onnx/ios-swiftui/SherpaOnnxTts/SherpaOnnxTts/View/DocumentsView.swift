//
//  DocumentsView.swift
//  SherpaOnnxTts
//
//  Created by Ahmad Ghaddar on 9/25/24.
//
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct DocumentsView: View {
    private struct PDFMetadata: Identifiable {
        let url: URL
        let document: DocumentRecord
        let size: Int64
        
        var id: String { url.absoluteString }
    }
    @State private var pdfMetadata: [PDFMetadata] = []
    enum SortOption {
        case newest
        case oldest
        case alphabetical
        case reverseAlphabetical
        case biggest
        case smallest
        
        var description: String {
            switch self {
            case .newest: return "Newest"
            case .oldest: return "Oldest"
            case .alphabetical: return "A to Z"
            case .reverseAlphabetical: return "Z to A"
            case .biggest: return "Biggest"
            case .smallest: return "Smallest"
            }
        }
    }
    @State private var currentSort: SortOption = .newest
    @State private var showSortMenu = false
    
    
    @EnvironmentObject var DB: Database
    @EnvironmentObject var ttsLogic: TtsLogic
    @StateObject private var fileDirectory = FileDirectory()
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    // State to store imported PDFs - Andy
    @State private var isBatchProcessing = false
    
    @State private var importedPdfs: [URL] = []
    @State private var showingDocumentPicker = false
    @State private var selectedPdf: URL? = nil
    
    // Search functionality state - Andy
    @State private var searchText = ""
    
    // State for renaming functionality - Andy
    @State private var pdfBeingRenamed: URL? = nil
    @State private var newPdfName = ""
    // State for managing focus on TextField - Andy
    @FocusState private var isRenamingFocused: Bool
    
    // New states for multi-select and batch conversion - Andy
    @State private var isSelectMode = false
    @State private var selectedPdfs: Set<URL> = []
    @State private var conversionQueue: [URL] = []
    @State private var isConverting = false
    
    // New states for delete confirmation - Andy
    @State private var showDeleteConfirmation = false
    @State private var pdfToDelete: URL? = nil
    @State private var showBatchDeleteConfirmation = false
    
    @State private var showSearchBar = false
    
    // Filtered PDFs based on search - Andy
    private var filteredPdfs: [URL] {
        let filtered = searchText.isEmpty ? importedPdfs : importedPdfs.filter { url in
            url.lastPathComponent.lowercased().contains(searchText.lowercased())
        }
        
        return filtered.sorted { first, second in
            let firstMetadata = pdfMetadata.first { $0.url == first }
            let secondMetadata = pdfMetadata.first { $0.url == second }
            
            switch currentSort {
            case .newest:
                return (firstMetadata?.document.uploadDate ?? "") > (secondMetadata?.document.uploadDate ?? "")
            case .oldest:
                return (firstMetadata?.document.uploadDate ?? "") < (secondMetadata?.document.uploadDate ?? "")
            case .alphabetical:
                return first.lastPathComponent.localizedStandardCompare(second.lastPathComponent) == .orderedAscending
            case .reverseAlphabetical:
                return first.lastPathComponent.localizedStandardCompare(second.lastPathComponent) == .orderedDescending
            case .biggest:
                return (firstMetadata?.size ?? 0) > (secondMetadata?.size ?? 0)
            case .smallest:
                return (firstMetadata?.size ?? 0) < (secondMetadata?.size ?? 0)
            }
        }
    }
    var body: some View {
        // Search Bar with Icon - Andy
        VStack(spacing: 0) {
            // Selection mode controls - Andy
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Left side - Search button and text - Andy
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showSearchBar ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                            Text("Search")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side items - Andy
                    HStack(spacing: 12) {
                        // Show count of filtered items if search is active - Andy
                        if !searchText.isEmpty {
                            Text("\(filteredPdfs.count) of \(importedPdfs.count)")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        
                        // Filter button - Andy
                        Menu {
                            ForEach([
                                SortOption.newest,
                                .oldest,
                                .biggest,
                                .smallest,
                                .alphabetical,
                                .reverseAlphabetical
                            ], id: \.self) { option in
                                Button(action: {
                                    currentSort = option
                                }) {
                                    HStack {
                                        Text(option.description)
                                        if currentSort == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.gray)
                        }
                        
                        if isSelectMode {
                            Button(action: {
                                selectedPdfs = Set(filteredPdfs)
                            }) {
                                Text("Select All")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Select/Done Button - Andy
                        Button(action: {
                            isSelectMode.toggle()
                            if !isSelectMode {
                                selectedPdfs.removeAll()
                                showSearchBar = false
                                searchText = ""
                            }
                        }) {
                            Text(isSelectMode ? "Done" : "Select")
                                .foregroundColor(.blue)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Expandable Search Bar - Andy
                if showSearchBar {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search PDFs", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .submitLabel(.search)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color(UIColor.systemBackground))
            
            
            if filteredPdfs.isEmpty {
                VStack {
                    Spacer()
                    Text(importedPdfs.isEmpty ? "No PDFs available" : "No matching PDFs found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredPdfs, id: \.self) { pdfUrl in
                        HStack {
                            if isSelectMode {
                                Image(systemName: selectedPdfs.contains(pdfUrl) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.blue)
                            }
                            
                            if pdfBeingRenamed == pdfUrl {
                                TextField("Enter new name", text: $newPdfName, onCommit: {
                                    renamePdf(pdfUrl: pdfUrl)
                                    pdfBeingRenamed = nil
                                })
                                .focused($isRenamingFocused)
                                .onAppear {
                                    isRenamingFocused = true
                                }
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            } else {
                                // Content stack- Andy
                                VStack(alignment: .leading, spacing: 4) {
                                    // Title - Andy
                                    Text(pdfUrl.lastPathComponent)
                                        .font(.headline)
                                    
                                    if let metadata = pdfMetadata.first(where: { $0.url == pdfUrl }) {
                                        Text(formatFileInfo(uploadDate: metadata.document.uploadDate, size: metadata.size))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                if !isSelectMode {
                                    Button(action: {
                                        selectedPdf = pdfUrl
                                    }) {
                                        Image(systemName: "doc.text.viewfinder")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                        }                        .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelectMode {
                                    if selectedPdfs.contains(pdfUrl) {
                                        selectedPdfs.remove(pdfUrl)
                                    } else {
                                        selectedPdfs.insert(pdfUrl)
                                    }
                                }
                            }
                            .contextMenu {
                                if !isSelectMode {
                                    Button {
                                        generateSpeechFromPdf(pdfUrl: pdfUrl)
                                    } label: {
                                        Label("Generate", systemImage: "waveform")
                                    }
                                    
                                    Button {
                                        newPdfName = pdfUrl.deletingPathExtension().lastPathComponent
                                        pdfBeingRenamed = pdfUrl
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    Button {
                                        sharePdf(url: pdfUrl)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    Button(role: .destructive) {
                                        pdfToDelete = pdfUrl
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            
            Spacer(minLength: 0)
            
            // Import PDF Button - Andy
            if !isSelectMode {
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    Text("Import PDF")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.vertical, 10)
            }
        }
        .navigationTitle("Documents")
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(
                importedPdfs: $importedPdfs,
                fileDirectory: fileDirectory,
                showError: $showError,
                errorMessage: $errorMessage
            ) { url in
                // Refresh the documents list after import - Andy
                loadSavedPdfs()
            }
            .environmentObject(DB)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
        // Single delete confirmation alert - Andy
        .alert("Delete PDF", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                pdfToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let url = pdfToDelete {
                    performDelete(pdfUrl: url)
                }
                pdfToDelete = nil
            }
        } message: {
            if let url = pdfToDelete {
                Text("Are you sure you want to delete '\(url.lastPathComponent)'?")
            }
        }
        // Batch delete confirmation alert - Andy
        .alert("Delete Multiple PDFs", isPresented: $showBatchDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                for pdfUrl in selectedPdfs {
                    performDelete(pdfUrl: pdfUrl)
                }
                selectedPdfs.removeAll()
                isSelectMode = false
            }
        } message: {
            Text("Are you sure you want to delete \(selectedPdfs.count) PDFs?")
        }
        .sheet(item: $selectedPdf) { pdfUrl in
            // View PDF in a PDF viewer - Andy
            PDFViewer(url: pdfUrl)
        }
        .onAppear {
            loadSavedPdfs()
        }
        .simultaneousGesture(TapGesture().onEnded {
            // If user clicks anywhere else, exit rename mode without saving changes - Andy
            pdfBeingRenamed = nil
        }, including: .all)
        .onReceive(ttsLogic.$progress) { progress in
            if progress == 1.0 && isBatchProcessing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    processNextInQueue()
                }
            }
        }
        // Add the new bottom toolbar for selection actions - Andy
        .safeAreaInset(edge: .bottom) {
            if isSelectMode && !selectedPdfs.isEmpty {
                HStack {
                    Spacer()
                    
                    // Delete Button - Andy
                    Button(action: {
                        showBatchDeleteConfirmation = true
                    }) {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .font(.system(size: 20))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Selected count indicator - Andy
                    Text("\(selectedPdfs.count) selected")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Convert Button - Andy
                    Button(action: {
                        startBatchConversion()
                    }) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "waveform")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }
    // Function to rename a PDF - Andy
    private func renamePdf(pdfUrl: URL) {
        let fileManager = FileManager.default
        let newPdfUrl = fileDirectory.documentsDirectory.appendingPathComponent(newPdfName).appendingPathExtension("pdf")
        
        guard !newPdfName.isEmpty, newPdfUrl != pdfUrl else { return }
        
        do {
            // Find the document in the database - Andy
            if let document = DB.fetchAllDocuments().first(where: { document in
                // kevin: Use relative paths for comparison
                let relativePath = fileDirectory.relativePath(for: pdfUrl)
                return document.filePath == relativePath
            }) {
                print("Found document in database: id=\(document.id), name=\(document.documentName)")
                
                // Check if destination already exists - Andy
                if fileManager.fileExists(atPath: newPdfUrl.path) {
                    throw NSError(domain: "", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "A file with this name already exists"])
                }
                
                // Rename the file - Andy
                try fileManager.moveItem(at: pdfUrl, to: newPdfUrl)
                print("File renamed successfully in filesystem")
                
                // kevin: Get the relative path of the new file
                let newRelativePath = fileDirectory.relativePath(for: newPdfUrl)
                
                // Update database - Andy
                DB.updateDocument(
                    id: document.id,
                    documentName: newPdfName + ".pdf",
                    uploadDate: document.uploadDate,
                    filePath: newRelativePath,  // kevin: Use relative path
                    fileType: "pdf"
                )
                
                // Update UI - Andy
                if let index = importedPdfs.firstIndex(of: pdfUrl) {
                    importedPdfs[index] = newPdfUrl
                    loadSavedPdfs()
                    print("UI updated successfully")
                }
            } else {
                print("Document not found in database")
            }
        } catch {
            print("Error renaming PDF: \(error.localizedDescription)")
            // Rename error if user tries to rename a pdf with the same name - Andy
            showError = true
            errorMessage = "Error renaming PDF: \(error.localizedDescription)"
        }
    }
    // Function to save PDF to the app's documents directory - Andy
    private func savePdfToDocuments(url: URL) {
        let fileManager = FileManager.default
        // kevin: Use fileDirectory.documentsDirectory
        let documentsDirectory = fileDirectory.documentsDirectory
        
        let destinationUrl = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        
        // Check if the file already exists - Andy
        if !fileManager.fileExists(atPath: destinationUrl.path) {
            do {
                // Copy the PDF to the documents directory - Andy
                try fileManager.copyItem(at: url, to: destinationUrl)
                // Add the saved PDF URL to the list - Andy
                importedPdfs.append(destinationUrl)
            } catch {
                print("Error saving PDF: \(error.localizedDescription)")
            }
        }
    }
    
    // Function to load saved PDFs from the database - Andy
    private func loadSavedPdfs() {
        print("Loading saved PDFs...")
        
        // Fetch from database - Andy
        let documents = DB.fetchAllDocuments()
        print("Found \(documents.count) documents in database")
        
        // Clear existing metadata - Andy
        pdfMetadata = []
        
        // Convert to URLs and verify files exist, collecting metadata - Andy
        importedPdfs = documents.compactMap { document in
            let url = fileDirectory.fullURL(for: document.filePath)
            let exists = FileManager.default.fileExists(atPath: url.path)
            print("Document path: \(url.path), exists: \(exists)")
            
            if exists {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attributes[.size] as? Int64 {
                    pdfMetadata.append(PDFMetadata(url: url, document: document, size: size))
                }
                return url
            }
            return nil
        }
        
        print("Loaded \(importedPdfs.count) valid PDFs")
    }
    // Function to delete a PDF from the list and documents directory - Andy
    private func deletePdf(pdfUrl: URL) {
        let fileManager = FileManager.default
        do {
            // First find the document in the database - Andy
            if let document = DB.fetchAllDocuments().first(where: { document in
                // kevin: Use relative paths for comparison
                let relativePath = fileDirectory.relativePath(for: pdfUrl)
                return document.filePath == relativePath
            }) {
                // Delete from database - Andy
                DB.deleteDocument(id: document.id)
                // Delete file - Andy
                try fileManager.removeItem(at: pdfUrl)
                // Update UI - Andy
                if let index = importedPdfs.firstIndex(of: pdfUrl) {
                    importedPdfs.remove(at: index)
                }
            }
        } catch {
            print("Error deleting PDF: \(error.localizedDescription)")
        }
    }
    private func performDelete(pdfUrl: URL) {
        let fileManager = FileManager.default
        do {
            if let document = DB.fetchAllDocuments().first(where: { document in
                // kevin: Use relative paths for comparison
                let relativePath = fileDirectory.relativePath(for: pdfUrl)
                return document.filePath == relativePath
            }) {
                DB.deleteDocument(id: document.id)
                try fileManager.removeItem(at: pdfUrl)
                if let index = importedPdfs.firstIndex(of: pdfUrl) {
                    importedPdfs.remove(at: index)
                }
            }
        } catch {
            print("Error deleting PDF: \(error.localizedDescription)")
            showError = true
            errorMessage = "Error deleting PDF: \(error.localizedDescription)"
        }
    }
    
    // Function to generate speech from PDF - Andy
    private func processNextInQueue() {
        guard !isConverting else {
            print("Already processing a PDF, waiting for completion")
            return
        }
        
        if ttsLogic.isCancelled {
            print("Batch conversion cancelled")
            cleanupAfterCancellation()
            return
        }
        
        // Check if queue is empty - Andy
        if conversionQueue.isEmpty {
            print("Batch conversion completed")
            cleanupAfterCompletion()
            return
        }
        
        isConverting = true
        
        // Update current PDF number - Andy
        ttsLogic.currentPdfNumber += 1
        
        // Safely get next PDF - Andy
        // Look at first item without removing - Andy
        let nextPdf = conversionQueue[0]
        print("Processing next PDF in queue: \(nextPdf.lastPathComponent), Remaining: \(conversionQueue.count - 1)")
        
        // Set up completion handler before starting conversion - Andy
        ttsLogic.onConversionComplete = {
            DispatchQueue.main.async {
                print("Completed processing PDF: \(nextPdf.lastPathComponent)")
                
                // Remove the processed PDF from queue - Andy
                if !self.conversionQueue.isEmpty {
                    self.conversionQueue.removeFirst()
                }
                
                // Reset conversion state - Andy
                self.isConverting = false
                
                // Process next PDF after a short delay to ensure cleanup - Andy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !self.conversionQueue.isEmpty && !self.ttsLogic.isCancelled {
                        self.processNextInQueue()
                    } else {
                        // If queue is empty or processing was cancelled, cleanup - Andy
                        if self.ttsLogic.isCancelled {
                            self.cleanupAfterCancellation()
                        } else {
                            self.cleanupAfterCompletion()
                        }
                    }
                }
            }
        }
        
        // Ensure clean state before starting new conversion - Andy
        ttsLogic.reset()
        generateSpeechFromPdf(pdfUrl: nextPdf, playAudio: false)
    }
    
    private func generateSpeechFromPdf(pdfUrl: URL, playAudio: Bool = true) {
        if let pdfDocument = PDFDocument(url: pdfUrl) {
            // Fetch the document record from the database - Andy
            if let document = DB.fetchDocumentByFilePath(filePath: fileDirectory.relativePath(for: pdfUrl)) {
                // Set the currentDocumentId in ttsLogic - Andy
                ttsLogic.currentDocumentId = document.id
                print("Set currentDocumentId to \(document.id)")
            } else {
                print("Document not found in database for path: \(pdfUrl.path)")
                ttsLogic.currentDocumentId = nil
            }
            
            let pageCount = pdfDocument.pageCount
            var extractedText = ""
            for pageIndex in 0..<pageCount {
                if let page = pdfDocument.page(at: pageIndex) {
                    extractedText += page.string ?? ""
                }
            }
            print("Starting conversion for PDF: \(pdfUrl.lastPathComponent)")
            ttsLogic.text = extractedText
            ttsLogic.generateSpeechStreaming(playAudioFlag: playAudio)
        }
    }
    
    private func startBatchConversion() {
        print("Starting batch conversion with \(selectedPdfs.count) PDFs")
        ttsLogic.resetCancelledState()
        conversionQueue = Array(selectedPdfs).sorted { $0.lastPathComponent < $1.lastPathComponent }
        isBatchProcessing = true
        isConverting = false
        ttsLogic.isBatchProcessing = true
        // Set total PDFs - Andy
        ttsLogic.totalPdfs = selectedPdfs.count
        // Reset current PDF number - Andy
        ttsLogic.currentPdfNumber = 0
        isSelectMode = false
        selectedPdfs.removeAll()
        
        // Only start if we have items in the queue - Andy
        if !conversionQueue.isEmpty {
            ttsLogic.reset()
            processNextInQueue()
        }
    }
    private func cleanupAfterCancellation() {
        print("Cleaning up after cancellation")
        conversionQueue.removeAll()
        isConverting = false
        isBatchProcessing = false
        ttsLogic.isBatchProcessing = false
        ttsLogic.stopSpeech()
        ttsLogic.isGenerating = false
        ttsLogic.isPlaying = false
        ttsLogic.resetCancelledState()
        ttsLogic.currentPdfNumber = 0
        ttsLogic.totalPdfs = 0
    }
    
    private func cleanupAfterCompletion() {
        print("Cleaning up after completion")
        isConverting = false
        isBatchProcessing = false
        ttsLogic.isBatchProcessing = false
        ttsLogic.currentPdfNumber = 0
        ttsLogic.totalPdfs = 0
        DispatchQueue.main.async {
            self.ttsLogic.stopSpeech()
            self.ttsLogic.isGenerating = false
            self.ttsLogic.isPlaying = false
        }
    }
    private func checkBatchCompletion() {
        if conversionQueue.isEmpty {
            print("Batch conversion completed")
            isConverting = false
            isBatchProcessing = false
            ttsLogic.isBatchProcessing = false
            DispatchQueue.main.async {
                ttsLogic.stopSpeech()
                ttsLogic.isGenerating = false
                ttsLogic.isPlaying = false
            }
            print("All states reset after batch completion")
        } else {
            processNextInQueue()
        }
    }
    private func sharePdf(url: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFileUrl = tempDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            // Remove any existing file at the temporary location - Andy
            if FileManager.default.fileExists(atPath: tempFileUrl.path) {
                try FileManager.default.removeItem(at: tempFileUrl)
            }
            
            // Copy the file to temporary directory - Andy
            try FileManager.default.copyItem(at: url, to: tempFileUrl)
            
            // Share the temporary file - Andy
            let activityVC = UIActivityViewController(
                activityItems: [tempFileUrl],
                applicationActivities: nil
            )
            
            // Get the window scene for presentation - Andy
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = window
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true) {
                    // Clean up the temporary file after sharing - Andy
                    // delayed if the share operation is still in progress - Andy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        try? FileManager.default.removeItem(at: tempFileUrl)
                    }
                }
            }
        } catch {
            print("Error sharing PDF: \(error.localizedDescription)")
        }
    }
    private func formatFileInfo(uploadDate: String, size: Int64) -> String {
        let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        return "\(uploadDate) · \(sizeString)"
    }
}
