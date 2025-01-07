//
//  AudioPlayerManager.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/28/24.
//

import AVFoundation
import SwiftUI

// Manages playback of saved audio files
class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentAudioId: Int?
    
    private(set) var audioPlayer: AVAudioPlayer?
    
    // Published properties for playback state
    @Published var currentTime: TimeInterval = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var playbackProgress: Double = 0.0
    @Published var playbackSpeed: Float = 1.0
    
    var onPlaybackComplete: (() -> Void)?
    
    private var updateTimer: Timer?
    
    // MARK: - Playback Control Methods
    
    func prepareAudio(filePath: String, audioId: Int, startPosition: TimeInterval? = nil) {
        // Stop current playback if any
        stop()
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: (filePath)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackSpeed
            
            // Set the start position if provided
            if let position = startPosition {
                audioPlayer?.currentTime = min(position, audioPlayer?.duration ?? 0)
            }
            
            currentAudioId = audioId
            isPlaying = false
            duration = audioPlayer?.duration ?? 0.0
            // Update progress without starting the timer
            updatePlaybackProgress()
        } catch {
            print("Error preparing audio: (error.localizedDescription)")
        }
    }
    
    
    func play(filePath: String, audioId: Int, startPosition: TimeInterval? = nil) {
        
        // Stop current playback if any
        stop()
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file not found at path: \(filePath)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackSpeed
            
            
            // Set the start position if provided
            if let position = startPosition {
                audioPlayer?.currentTime = min(position, audioPlayer?.duration ?? 0)
            }
            audioPlayer?.play()
            
            currentAudioId = audioId
            isPlaying = true
            duration = audioPlayer?.duration ?? 0.0
            startProgressUpdates()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func playPause() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            stopProgressUpdates()
        } else {
            player.play()
            isPlaying = true
            startProgressUpdates()
        }
    }
    
    func stop() {
        // Save bookmark before stopping
        if let currentId = currentAudioId {
            AudioBookmarkManager.shared.saveBookmark(
                audioId: currentId,
                position: audioPlayer?.currentTime ?? 0
            )
        }
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentAudioId = nil
        stopProgressUpdates()
        resetPlaybackState()
    }
    
    // MARK: - Playback Control Methods
    
    func seek(to progress: Double) {
        guard let player = audioPlayer else { return }
        let newTime = progress * player.duration
        player.currentTime = newTime
        updatePlaybackProgress()
    }
    
    func skipForward(seconds: Double = 15) {
        guard let player = audioPlayer else { return }
        let newTime = min(player.currentTime + seconds, player.duration)
        player.currentTime = newTime
        updatePlaybackProgress()
    }
    
    func skipBackward(seconds: Double = 15) {
        guard let player = audioPlayer else { return }
        let newTime = max(player.currentTime - seconds, 0)
        player.currentTime = newTime
        updatePlaybackProgress()
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        audioPlayer?.rate = speed
    }
    
    // MARK: - Private Helper Methods
    
    private func startProgressUpdates() {
        stopProgressUpdates()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }
    
    private func stopProgressUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        currentTime = player.currentTime
        playbackProgress = player.duration > 0 ? player.currentTime / player.duration : 0
    }
    
    private func resetPlaybackState() {
        currentTime = 0
        duration = 0
        playbackProgress = 0
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopProgressUpdates()
        
        onPlaybackComplete?()
        
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "unknown error")")
        stop()
    }
}
