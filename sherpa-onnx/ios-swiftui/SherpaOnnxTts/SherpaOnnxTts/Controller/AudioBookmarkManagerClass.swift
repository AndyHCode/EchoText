//
//  AudioBookmarkManagerClass.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/29/24.
//

import Foundation

class AudioBookmarkManager {
    static let shared = AudioBookmarkManager()
    
    private let defaults = UserDefaults.standard
    private let lastPlayedAudioIdKey = "lastPlayedAudioId"
    private let lastPlaybackPositionKey = "lastPlaybackPosition"
    
    func saveBookmark(audioId: Int, position: TimeInterval) {
        defaults.set(audioId, forKey: lastPlayedAudioIdKey)
        defaults.set(position, forKey: lastPlaybackPositionKey)
    }
    
    func getBookmark() -> (audioId: Int?, position: TimeInterval) {
        let audioId = defaults.object(forKey: lastPlayedAudioIdKey) as? Int
        let position = defaults.double(forKey: lastPlaybackPositionKey)
        return (audioId, position)
    }
    
    func clearBookmark() {
        defaults.removeObject(forKey: lastPlayedAudioIdKey)
        defaults.removeObject(forKey: lastPlaybackPositionKey)
    }
}
