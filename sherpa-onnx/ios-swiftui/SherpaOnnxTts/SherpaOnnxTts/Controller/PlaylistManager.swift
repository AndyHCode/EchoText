//
//  PlaylistManager.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/28/24.
//

import SwiftUI

class PlaylistManager: ObservableObject {
    @Published var queue: [AudioRecord] = []
    @Published var isPlaylistActive: Bool = false
    // Add autoplay state, default to true
    @Published var isAutoplayEnabled: Bool = true
    
    
    func addToQueue(_ audio: AudioRecord) {
        guard !queue.contains(where: { $0.id == audio.id }) else { return }
        queue.append(audio)
        // Activate playlist when adding new items
        isPlaylistActive = true
    }
    
    func removeFromQueue(at offsets: IndexSet) {
        queue.remove(atOffsets: offsets)
        if queue.isEmpty {
            isPlaylistActive = false
        }
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
    }
    
    func clearQueue() {
        queue.removeAll()
        isPlaylistActive = false
    }
    
    func activatePlaylist() {
        if !queue.isEmpty {
            isPlaylistActive = true
        }
    }
    
    func deactivatePlaylist() {
        isPlaylistActive = false
    }
    
    func getNextAudio(after currentAudioId: Int) -> AudioRecord? {
        guard isPlaylistActive else { return nil }
        
        if let currentIndex = queue.firstIndex(where: { $0.id == currentAudioId }) {
            let nextIndex = currentIndex + 1
            if nextIndex < queue.count {
                return queue[nextIndex]
            }
            // Loop back to beginning
            return queue.first
        }
        return queue.first
    }
    
    func getPreviousAudio(before currentAudioId: Int) -> AudioRecord? {
        guard isPlaylistActive else { return nil }
        
        if let currentIndex = queue.firstIndex(where: { $0.id == currentAudioId }) {
            let previousIndex = currentIndex - 1
            if previousIndex >= 0 {
                return queue[previousIndex]
            }
            // Loop back to end
            return queue.last
        }
        return queue.last
    }
    
    func isAudioInQueue(_ audioId: Int) -> Bool {
        return queue.contains(where: { $0.id == audioId })
    }
    
    func toggleAutoplay() {
        isAutoplayEnabled.toggle()
    }
}
