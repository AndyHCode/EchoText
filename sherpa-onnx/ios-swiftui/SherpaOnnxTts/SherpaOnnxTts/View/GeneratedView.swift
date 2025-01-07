//
//  GeneratedView.swift
//  SherpaOnnxTts
//
//  Created by Ahmad Ghaddar on 9/25/24.
//

import SwiftUI
import AVFoundation


struct GeneratedView: View {
    @StateObject private var audioManager = AudioPlayerManager()
    @StateObject private var fileDirectory = FileDirectory()
    
    @EnvironmentObject var DB: Database
    @State private var audios: [AudioRecord] = []
    @State private var searchText: String = ""
    
    // To track which audio is being edited
    @State private var editingAudioID: Int?
    // To hold the text being edited
    @State private var renameText = ""
    // Track which TextField is focused
    @FocusState private var focusedAudioID: Int?
    
    @State private var showMetadataForAudio: AudioRecord? = nil
    @State private var selectedDocument: DocumentRecord?
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isShareSheetPresented: Bool = false
    @State private var shareItems: [Any] = []
    
    // Track multiple selected audio IDs
    @State private var selectedAudioIDs: Set<Int> = []
    // Toggle multi-selection mode
    @State private var isEditing: Bool = false
    // Track playback controls state
    @State private var isPlaybackExpanded: Bool = false
    // To trigger delete alert
    @State private var showDeleteConfirmation: Bool = false
    // Track audio for single delete
    @State private var deleteAudio: AudioRecord? = nil
    // Track if it's a mass delete
    @State private var isMassDelete: Bool = false
    @State private var sortCriterion: SortCriterion = .dateDescending
    @ObservedObject var filterCriteria = FilterCriteria()
    @StateObject private var playlistManager = PlaylistManager()
    @State private var showPlaylist = false
    @State private var isSearchVisible = false
    
    
    // Filtering
    
    // Control the presentation of the filter sheet
    @State private var showFilterSheet = false
    
    func setupAutoplay() {
        audioManager.onPlaybackComplete = { [weak playlistManager] in
            // Check if autoplay is enabled and playlist is active
            guard let playlistManager = playlistManager,
                  playlistManager.isPlaylistActive &&
                    playlistManager.isAutoplayEnabled else { return }
            
            // Get and play next audio if available
            if let currentAudioId = self.audioManager.currentAudioId,
               let nextAudio = playlistManager.getNextAudio(after: currentAudioId) {
                self.selectAudio(audio: nextAudio)
            }
        }
    }
    
    var filteredAudios: [AudioRecord] {
        var result = audios
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        // Apply filter criteria
        result = result.filter { audio in
            let speedMatch = filterCriteria.speedRange.contains(audio.speed)
            let pitchMatch = filterCriteria.pitchRange.contains(audio.pitch)
            let lengthMatch = filterCriteria.lengthRange.contains(Double(audio.length))
            let favoritesMatch = !filterCriteria.favoritesOnly || audio.isFavorite
            let linkedDocumentsMatch = !filterCriteria.linkedDocumentsOnly || audio.documentId != nil || (!audio.textFilePath.isEmpty && audio.textFilePath != "#")
            
            // Date matching
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy hh:mm:ss a"
            let audioDate = dateFormatter.date(from: audio.dateGenerated) ?? Date.distantPast
            let dateRangeMatch = filterCriteria.dateRange == nil || filterCriteria.dateRange!.contains(audioDate)
            
            // Model matching
            let modelMatch = filterCriteria.model == nil || audio.model == filterCriteria.model
            
            return speedMatch && pitchMatch && lengthMatch && favoritesMatch && linkedDocumentsMatch && dateRangeMatch && modelMatch
        }
        
        // Apply sorting
        result.sort { a, b in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy hh:mm:ss a"
            
            switch sortCriterion {
            case .nameAscending:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .nameDescending:
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
            case .dateAscending:
                let dateA = dateFormatter.date(from: a.dateGenerated) ?? Date.distantPast
                let dateB = dateFormatter.date(from: b.dateGenerated) ?? Date.distantPast
                return dateA < dateB
            case .dateDescending:
                let dateA = dateFormatter.date(from: a.dateGenerated) ?? Date.distantPast
                let dateB = dateFormatter.date(from: b.dateGenerated) ?? Date.distantPast
                return dateA > dateB
            case .durationAscending:
                return a.length < b.length
            case .durationDescending:
                return a.length > b.length
            }
        }
        
        return result
    }
    
    
    func selectAudio(audio: AudioRecord) {
        let fullPath = fileDirectory.fullURL(for: audio.filePath).path
        
        // If user manually selects a non-queued audio, deactivate playlist
        if !playlistManager.isAudioInQueue(audio.id) {
            playlistManager.deactivatePlaylist()
        }
        
        audioManager.play(filePath: fullPath, audioId: audio.id)
    }
    
    func playNextAudio() {
        guard !isEditing else { return }
        
        // Only check playlist if it's active
        if playlistManager.isPlaylistActive,
           let currentAudioId = audioManager.currentAudioId,
           let nextAudio = playlistManager.getNextAudio(after: currentAudioId) {
            selectAudio(audio: nextAudio)
            return
        }
        
        // Default to normal navigation
        guard !filteredAudios.isEmpty else { return }
        
        if let currentIndex = filteredAudios.firstIndex(where: { $0.id == audioManager.currentAudioId }) {
            let nextIndex = currentIndex + 1
            if nextIndex < filteredAudios.count {
                let nextAudio = filteredAudios[nextIndex]
                selectAudio(audio: nextAudio)
            } else {
                let firstAudio = filteredAudios[0]
                selectAudio(audio: firstAudio)
            }
        } else {
            let firstAudio = filteredAudios[0]
            selectAudio(audio: firstAudio)
        }
    }
    
    func playPreviousAudio() {
        guard !isEditing else { return }
        
        // Only check playlist if it's active
        if playlistManager.isPlaylistActive,
           let currentAudioId = audioManager.currentAudioId,
           let previousAudio = playlistManager.getPreviousAudio(before: currentAudioId) {
            selectAudio(audio: previousAudio)
            return
        }
        
        // Default to normal navigation
        guard !filteredAudios.isEmpty else { return }
        
        if let currentIndex = filteredAudios.firstIndex(where: { $0.id == audioManager.currentAudioId }) {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                let prevAudio = filteredAudios[prevIndex]
                selectAudio(audio: prevAudio)
            } else {
                let lastAudio = filteredAudios.last!
                selectAudio(audio: lastAudio)
            }
        } else {
            let lastAudio = filteredAudios.last!
            selectAudio(audio: lastAudio)
        }
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            // Title and count of generated audios
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Left side - Search button and text
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearchVisible.toggle()
                            if !isSearchVisible {
                                searchText = ""
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundColor(.gray)
                                .imageScale(.large)
                            Text("Search")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side items
                    HStack(spacing: 12) {
                        // Show count of filtered items if different from total
                        if filteredAudios.count != audios.count {
                            Text("\(filteredAudios.count) of \(audios.count)")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        
                        // Filter button
                        Button(action: {
                            self.showFilterSheet = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(areFiltersActive() ? .blue : .gray)
                        }
                        .sheet(isPresented: $showFilterSheet) {
                            FilterSortView(sortCriterion: $sortCriterion, filterCriteria: filterCriteria, audios: audios)
                        }
                        
                        // Select/Done Button
                        Button(action: {
                            isEditing.toggle()
                            if !isEditing {
                                selectedAudioIDs.removeAll()
                                isSearchVisible = false
                                searchText = ""
                            }
                        }) {
                            Text(isEditing ? "Done" : "Select")
                                .foregroundColor(.blue)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Expandable Search Bar
                if isSearchVisible {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search Audios", text: $searchText)
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
            
            
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(filteredAudios) { audio in
                            VStack(alignment: .leading, spacing: 8) {
                                // Title and Edit Field
                                
                                HStack {
                                    
                                    // Selection Checkbox
                                    if isEditing {
                                        Button(action: {
                                            toggleSelection(for: audio)
                                        }) {
                                            Image(systemName: selectedAudioIDs.contains(audio.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    // If editing, show TextField, else show Text
                                    if editingAudioID == audio.id {
                                        TextField("Enter new name", text: $renameText, onCommit: {
                                            saveNewName(for: audio)
                                        })
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .focused($focusedAudioID, equals: audio.id)
                                        .onAppear {
                                            // Focus when the field appears
                                            self.focusedAudioID = audio.id
                                        }
                                        .onChange(of: focusedAudioID) { newFocusedID in
                                            // When focus moves away from this text field, save the new name
                                            if newFocusedID != audio.id {
                                                saveNewName(for: audio)
                                            }
                                        }
                                        // Limit the renameText to 25 characters
                                        .onChange(of: renameText) { newValue in
                                            if newValue.count > 25 {
                                                renameText = String(newValue.prefix(25))
                                            }
                                        }
                                        
                                        
                                    } else {
                                        Text(audio.name)
                                            .font(.headline)
                                    }
                                    Spacer()
                                    
                                    
                                }
                                
                                // Length and Model Row
                                HStack(spacing: 10) {
                                    // Duration
                                    HStack(spacing: 2) {
                                        Image(systemName: "clock")
                                        Text(audio.length.formattedTime())
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Model/Voice
                                    HStack(spacing: 2) {
                                        Image(systemName: "waveform")
                                        Text(audio.model)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Date Row
                                HStack {
                                    HStack(spacing: 2) {
                                        Image(systemName: "calendar")
                                        Text(formattedDateDisplay(from: audio.dateGenerated))
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Favorite icon
                                    Button(action: {
                                        toggleFavorite(audio: audio)
                                    }) {
                                        Image(systemName: audio.isFavorite ? "heart.fill" : "heart")
                                            .foregroundColor(.red)
                                            .imageScale(.large)
                                    }
                                    
                                    // Document viewer icon
                                    Button(action: {
                                        presentLinkedDocument(for: audio)
                                    }) {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(
                                                (!audio.textFilePath.isEmpty && audio.textFilePath != "#") ||
                                                (audio.documentId != nil && DB.fetchDocumentById(documentId: audio.documentId!) != nil)
                                                ? .blue
                                                : .gray.opacity(0.5)
                                            )
                                            .imageScale(.large)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .disabled(!(!audio.textFilePath.isEmpty && audio.textFilePath != "#") &&
                                              !(audio.documentId != nil && DB.fetchDocumentById(documentId: audio.documentId!) != nil))
                                }
                                
                            }
                            
                            .padding()
                            .background(
                                self.audioManager.currentAudioId == audio.id ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        self.audioManager.currentAudioId == audio.id ? Color.blue : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            // Makes the entire row tappable
                            .contentShape(Rectangle())
                            // Disable audio playback when in editing mode
                            .onTapGesture {
                                if !isEditing {
                                    self.selectAudio(audio: audio)
                                } else {
                                    toggleSelection(for: audio)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: self.audioManager.currentAudioId)
                            
                            
                            .contextMenu {
                                Button(action: {
                                    startRenaming(audio: audio)
                                }) {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    presentLinkedDocument(for: audio)
                                }) {
                                    Label("View Document", systemImage: "doc.text")
                                }
                                
                                Button(action: {
                                    playlistManager.addToQueue(audio)
                                }) {
                                    Label("Add to Queue", systemImage: "text.badge.plus")
                                }
                                
                                Button(action: {
                                    shareAudio(audio: audio)
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                
                                Button(action: {
                                    self.showMetadataForAudio = audio
                                }) {
                                    Label("More Info", systemImage: "info.circle")
                                }
                                
                                Button(role: .destructive, action: {
                                    self.deleteAudioById(audio: audio)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(
                                (self.audioManager.currentAudioId == audio.id) ? Color.blue.opacity(0.2) : Color.clear
                            )
                        }
                    }
                    .padding()
                }
                
                // Gradient Overlay at the bottom
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color(UIColor.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                // So the gradient doesn't intercept touch events
                .allowsHitTesting(false)
            }
            .sheet(item: $selectedDocument) { document in
                let documentURL = URL(fileURLWithPath: document.filePath)
                if documentURL.pathExtension.lowercased() == "pdf" {
                    PDFViewer(url: documentURL)
                } else if documentURL.pathExtension.lowercased() == "txt" {
                    TextFileViewer(url: documentURL)
                } else {
                    Text("Unsupported file type")
                }
            }
            
            // Mass action buttons for selected audios
            if isEditing {
                HStack {
                    // Select All button
                    Button(action: {
                        if selectedAudioIDs.count == filteredAudios.count {
                            // Deselect all if all are already selected
                            selectedAudioIDs.removeAll()
                        } else {
                            // Select all
                            selectedAudioIDs = Set(filteredAudios.map { $0.id })
                        }
                    }) {
                        Text(selectedAudioIDs.count == filteredAudios.count ? "Deselect All" : "Select All")
                    }
                    .padding()
                    
                    // Delete button
                    Button(action: {
                        massDelete()
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .padding()
                    // Disable if no items selected
                    .disabled(selectedAudioIDs.isEmpty)
                    
                    // Share button
                    Button(action: {
                        massShare()
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                    // Disable if no items selected
                    .disabled(selectedAudioIDs.isEmpty)
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            }
            
            
            Spacer()
            
            if audioManager.currentAudioId != nil && !isEditing {
                PlaybackControlsView(
                    audioManager: audioManager,
                    playlistManager: playlistManager,
                    playNextAudio: playNextAudio,
                    playPreviousAudio: playPreviousAudio,
                    onSelectAudio: selectAudio                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            dismissEditingMode()
        }
        .onAppear {
            self.audios = DB.fetchAllAudios()
            setupAutoplay()
            restoreLastPlayedAudio()
        }
        
        
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            //Save current playback state when app goes to background
            if let currentId = audioManager.currentAudioId {
                AudioBookmarkManager.shared.saveBookmark(
                    audioId: currentId,
                    position: audioManager.currentTime
                )
            }
        }
        
        
        .sheet(item: $showMetadataForAudio) { audio in
            AudioMetadataView(audio: audio)
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ActivityView(activityItems: shareItems)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Name"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showDeleteConfirmation) { [self] in
            Alert(
                title: Text("Delete Confirmation"),
                message: Text(isMassDelete ? "Are you sure you want to delete all selected audio files?" : "Are you sure you want to delete this audio file?"),
                primaryButton: .destructive(Text("Delete")) {
                    if isMassDelete { confirmMassDelete() }
                    else if let audioToDelete = deleteAudio { confirmSingleDelete(audio: audioToDelete) }
                },
                secondaryButton: .cancel()
            )
        }
        
        
    }
    
    func shareAudio(audio: AudioRecord) {
        let tempDir = FileManager.default.temporaryDirectory
        let fullPath = fileDirectory.fullURL(for: audio.filePath)
        let tempFileUrl = tempDir.appendingPathComponent(fullPath.lastPathComponent)
        
        do {
            // Remove any existing file at the temporary location - Andy
            if FileManager.default.fileExists(atPath: tempFileUrl.path) {
                try FileManager.default.removeItem(at: tempFileUrl)
            }
            
            // Copy the file to temporary directory - Andy
            try FileManager.default.copyItem(at: fullPath, to: tempFileUrl)
            
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        try? FileManager.default.removeItem(at: tempFileUrl)
                    }
                }
            }
        } catch {
            print("Error sharing audio: \(error.localizedDescription)")
            alertMessage = "Error sharing audio: \(error.localizedDescription)"
            showAlert = true
        }
    }
    private func restoreLastPlayedAudio() {
        let bookmark = AudioBookmarkManager.shared.getBookmark()
        
        if let audioId = bookmark.audioId,
           let audio = audios.first(where: { $0.id == audioId }) {
            let fullPath = fileDirectory.fullURL(for: audio.filePath).path
            audioManager.prepareAudio(filePath: fullPath, audioId: audioId, startPosition: bookmark.position)
        }
    }
    
    // presentLinkedDocument function
    func presentLinkedDocument(for audio: AudioRecord) {
        if let documentId = audio.documentId {
            if let document = DB.fetchDocumentById(documentId: documentId) {
                // kevin: reconstruct the full file path for the document using relative path
                let fullFilePath = fileDirectory.fullURL(for: document.filePath).path
                // kevin: create a new DocumentRecord with the updated filePath
                let updatedDocument = DocumentRecord(
                    id: document.id,
                    documentName: document.documentName,
                    uploadDate: document.uploadDate,
                    filePath: fullFilePath,
                    fileType: document.fileType
                )
                self.selectedDocument = updatedDocument
            } else {
                print("Document not found for documentId \(documentId)")
                self.alertMessage = "Document not found."
                self.showAlert = true
            }
        } else if !audio.textFilePath.isEmpty && audio.textFilePath != "#" {
            let textFileURL = fileDirectory.fullURL(for: audio.textFilePath)
            if FileManager.default.fileExists(atPath: textFileURL.path) {
                self.selectedDocument = DocumentRecord(
                    id: -1,
                    documentName: "Text Input",
                    uploadDate: "",
                    filePath: textFileURL.path,
                    fileType: "txt"
                )
            } else {
                print("Text file not found at: \(textFileURL.path)")
                self.alertMessage = "Text file not found."
                self.showAlert = true
            }
        } else {
            print("No linked document or text file for this audio.")
            self.alertMessage = "No linked document or text file for this audio."
            self.showAlert = true
        }
    }
    
    
    func dismissEditingMode() {
        if let editingAudioID = editingAudioID,
           let audio = audios.first(where: { $0.id == editingAudioID }) {
            saveNewName(for: audio)
        }
    }
    
    
    
    func deleteAudioById(audio: AudioRecord) {
        // Set the audio to be deleted
        self.deleteAudio = audio
        // This is a single delete
        self.isMassDelete = false
        // Trigger the confirmation alert
        self.showDeleteConfirmation = true
    }
    
    // Start renaming an audio
    func startRenaming(audio: AudioRecord) {
        self.editingAudioID = audio.id
        // Set the current name in the text field
        self.renameText = audio.name
        // Automatically focus on the text field
        self.focusedAudioID = audio.id
    }
    
    // Save the new name and exit editing mode
    func saveNewName(for audio: AudioRecord) {
        // Trim whitespace from the new name
        let trimmedName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure renameText is at most 25 characters
        let truncatedName = String(trimmedName.prefix(25))
        
        // Check if the name is empty
        if truncatedName.isEmpty {
            alertMessage = "Audio name cannot be empty."
            showAlert = true
            // Exit the function without saving
            return
        }
        
        // Check for duplicate names among other audios
        let duplicateNameExists = audios.contains { existingAudio in
            existingAudio.id != audio.id && existingAudio.name == truncatedName
        }
        
        if duplicateNameExists {
            alertMessage = "An audio with this name already exists."
            showAlert = true
            // Exit the function without saving
            return
        }
        
        // Check if the new name is different before saving
        if audio.name != truncatedName {
            DB.updateAudio(
                id: audio.id,
                name: truncatedName,
                filePath: audio.filePath,
                dateGenerated: audio.dateGenerated,
                model: audio.model,
                pitch: audio.pitch,
                speed: audio.speed,
                documentId: audio.documentId,
                textFilePath: audio.textFilePath,
                isFavorite: audio.isFavorite
            )
            
            if let index = audios.firstIndex(where: { $0.id == audio.id }) {
                audios[index].name = truncatedName
            }
        }
        // Exit editing mode
        editingAudioID = nil
    }
    
    
    
    // Function to delete audio from database and file system
    func deleteAudio(at offsets: IndexSet) {
        for index in offsets {
            let audio = audios[index]
            DB.deleteAudio(id: audio.id)
            try? FileManager.default.removeItem(atPath: audio.filePath)
        }
        audios.remove(atOffsets: offsets)
    }
    
    
    
    
    // Toggle selection state for an audio
    func toggleSelection(for audio: AudioRecord) {
        if selectedAudioIDs.contains(audio.id) {
            selectedAudioIDs.remove(audio.id)
        } else {
            selectedAudioIDs.insert(audio.id)
        }
    }
    
    // Mass delete action
    func massDelete() {
        guard !selectedAudioIDs.isEmpty else { return }
        // Set mass delete flag
        self.isMassDelete = true
        // Trigger the confirmation alert
        self.showDeleteConfirmation = true
    }
    
    // Mass share action
    func massShare() {
        let tempDir = FileManager.default.temporaryDirectory
        var tempFiles: [URL] = []
        
        do {
            // Create temporary copies of all selected audio files - Andy
            for audioID in selectedAudioIDs {
                if let audio = audios.first(where: { $0.id == audioID }) {
                    let fullPath = fileDirectory.fullURL(for: audio.filePath)
                    let tempFileUrl = tempDir.appendingPathComponent(fullPath.lastPathComponent)
                    
                    // Remove any existing temp file - Andy
                    if FileManager.default.fileExists(atPath: tempFileUrl.path) {
                        try FileManager.default.removeItem(at: tempFileUrl)
                    }
                    
                    // Copy file to temp directory - Andy
                    if FileManager.default.fileExists(atPath: fullPath.path) {
                        try FileManager.default.copyItem(at: fullPath, to: tempFileUrl)
                        tempFiles.append(tempFileUrl)
                    }
                }
            }
            
            guard !tempFiles.isEmpty else {
                alertMessage = "No audio files available to share."
                showAlert = true
                return
            }
            
            // Create and configure activity view controller - Andy
            let activityVC = UIActivityViewController(
                activityItems: tempFiles,
                applicationActivities: nil
            )
            
            // Present the share sheet - Andy
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = window
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true) {
                    // Clean up temporary files after a delay - Andy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        for tempFile in tempFiles {
                            try? FileManager.default.removeItem(at: tempFile)
                        }
                    }
                }
            }
        } catch {
            print("Error preparing files for sharing: \(error.localizedDescription)")
            alertMessage = "Error preparing files for sharing: \(error.localizedDescription)"
            showAlert = true
            
            // Clean up any temporary files that were created - Andy
            for tempFile in tempFiles {
                try? FileManager.default.removeItem(at: tempFile)
            }
        }
    }
    // Confirmed delete action for a single audio
    func confirmSingleDelete(audio: AudioRecord) {
        // Delete from database
        DB.deleteAudio(id: audio.id)
        
        // Delete audio file
        let fullAudioPath = fileDirectory.fullURL(for: audio.filePath).path
        try? FileManager.default.removeItem(atPath: fullAudioPath)
        
        // Delete linked text file if it exists
        if !audio.textFilePath.isEmpty && audio.textFilePath != "#" {
            let fullTextPath = fileDirectory.fullURL(for: audio.textFilePath).path
            try? FileManager.default.removeItem(atPath: fullTextPath)
        }
        
        // Remove from local array
        audios.removeAll { $0.id == audio.id }
        deleteAudio = nil
    }
    
    // Confirmed delete action for mass delete
    func confirmMassDelete() {
        for audioID in selectedAudioIDs {
            if let audio = audios.first(where: { $0.id == audioID }) {
                // Delete from database
                DB.deleteAudio(id: audio.id)
                
                // Delete audio file
                let fullAudioPath = fileDirectory.fullURL(for: audio.filePath).path
                try? FileManager.default.removeItem(atPath: fullAudioPath)
                
                // Delete linked text file if it exists
                if !audio.textFilePath.isEmpty && audio.textFilePath != "#" {
                    let fullTextPath = fileDirectory.fullURL(for: audio.textFilePath).path
                    try? FileManager.default.removeItem(atPath: fullTextPath)
                }
            }
        }
        audios.removeAll { selectedAudioIDs.contains($0.id) }
        selectedAudioIDs.removeAll()
    }
    
    func toggleFavorite(audio: AudioRecord) {
        // Toggle the favorite status
        let newFavoriteStatus = !audio.isFavorite
        
        let existingTextFilePath = audio.textFilePath.isEmpty ? "#" : audio.textFilePath
        
        
        // Update the database
        DB.updateAudio(
            id: audio.id,
            name: audio.name,
            filePath: audio.filePath,
            dateGenerated: audio.dateGenerated,
            model: audio.model,
            pitch: audio.pitch,
            speed: audio.speed,
            documentId: audio.documentId,
            textFilePath: existingTextFilePath,
            isFavorite: newFavoriteStatus
        )
        
        // Update the local array with a new instance
        if let index = audios.firstIndex(where: { $0.id == audio.id }) {
            let updatedAudio = AudioRecord(
                id: audio.id,
                name: audio.name,
                filePath: audio.filePath,
                dateGenerated: audio.dateGenerated,
                model: audio.model,
                pitch: audio.pitch,
                speed: audio.speed,
                documentId: audio.documentId,
                textFilePath: existingTextFilePath,
                length: audio.length,
                isFavorite: newFavoriteStatus
            )
            audios[index] = updatedAudio
        }
    }
    
    func areFiltersActive() -> Bool {
        return !(searchText.isEmpty &&
                 filterCriteria.speedRange == 0.5...1.5 &&
                 filterCriteria.pitchRange == 0.1...2.0 &&
                 filterCriteria.lengthRange == 0.0...Double.infinity &&
                 filterCriteria.dateRange == nil &&
                 !filterCriteria.favoritesOnly &&
                 !filterCriteria.linkedDocumentsOnly &&
                 filterCriteria.model == nil)
    }
    
    
    func formattedDateDisplay(from dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "MMM/dd/yyyy hh:mm:ss a" // Format of stored date
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            // Fallback to original string if parsing fails
            return dateString
        }
    }
    
    
    
}

