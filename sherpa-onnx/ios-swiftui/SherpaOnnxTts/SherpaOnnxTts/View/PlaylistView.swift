//
//  PlaylistView.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/28/24.
//

import SwiftUI

struct PlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var playlistManager: PlaylistManager
    var onSelectAudio: (AudioRecord) -> Void
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                // Autoplay Toggle Section
                Section {
                    Toggle(isOn: $playlistManager.isAutoplayEnabled) {
                        HStack {
                            Image(systemName: "play.circle")
                            Text("Autoplay Next")
                        }
                    }
                }
                
                // Queue Section
                Section {
                    if playlistManager.queue.isEmpty {
                        Text("No audios in queue")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(playlistManager.queue) { audio in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(audio.name)
                                        .font(.headline)
                                    Text(formatDuration(audio.length))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if !editMode.isEditing {
                                    Button(action: {
                                        // Activate playlist when selecting from queue
                                        playlistManager.activatePlaylist()
                                        onSelectAudio(audio)
                                        dismiss()
                                    }) {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.blue)
                                            .imageScale(.large)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: playlistManager.removeFromQueue)
                        .onMove(perform: playlistManager.moveItem)
                    }
                }
            }
            .navigationTitle("Play Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !playlistManager.queue.isEmpty {
                        EditButton()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !playlistManager.queue.isEmpty {
                        Button(action: {
                            playlistManager.clearQueue()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
    }
    
    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
