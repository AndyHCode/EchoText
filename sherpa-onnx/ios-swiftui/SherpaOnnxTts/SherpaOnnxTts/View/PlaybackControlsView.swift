//
//  PlaybackControlsView.swift
//  SherpaOnnxTts
//
//  Created by Ahmad Ghaddar on 10/9/24.
//

import SwiftUI
import AVFoundation

struct PlaybackControlsView: View {
    @ObservedObject var audioManager: AudioPlayerManager
    @ObservedObject var playlistManager: PlaylistManager
    @State private var showPlaylist = false
    var playNextAudio: () -> Void
    var playPreviousAudio: () -> Void
    var onSelectAudio: (AudioRecord) -> Void
    
    
    
    
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    VStack {
                        HStack {
                            Button(action: {
                                self.showPlaylist = true
                            }) {
                                Image(systemName: "text.badge.plus")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    // Blue when playlist has items
                                    .foregroundColor(playlistManager.queue.isEmpty ? .gray : .blue)
                                
                            }
                            .sheet(isPresented: $showPlaylist) {
                                PlaylistView(
                                    playlistManager: playlistManager,
                                    onSelectAudio: onSelectAudio
                                    
                                )
                            }
                            
                            Spacer(minLength: 40)
                            
                            Button(action: {
                                self.playPreviousAudio()
                            }) {
                                Image(systemName: "backward.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                audioManager.skipBackward()
                            }) {
                                Image(systemName: "gobackward.15")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                audioManager.playPause()
                            }) {
                                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                audioManager.skipForward()
                            }) {
                                Image(systemName: "goforward.15")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                self.playNextAudio()
                            }) {
                                Image(systemName: "forward.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            
                            Spacer()
                            
                            Menu {
                                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                                    Button(action: {
                                        audioManager.setPlaybackSpeed(Float(speed))
                                    }) {
                                        HStack {
                                            Text(formatSpeed(Float(speed)))
                                            if audioManager.playbackSpeed == Float(speed) {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Text(formatSpeed(audioManager.playbackSpeed))
                                    .font(.headline)
                                    .frame(width: 45, height: 25)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        
                        HStack {
                            Text(formatTime(audioManager.currentTime))
                                .font(.caption)
                                .padding(.leading)
                            
                            CustomSliderView(value: .init(
                                get: { audioManager.playbackProgress },
                                set: { audioManager.seek(to: $0) }
                            ))
                            .frame(height: 40)
                            .padding(.horizontal, 5)
                            
                            Text(formatTime(audioManager.duration))
                                .font(.caption)
                                .padding(.trailing)
                        }
                        .padding(.horizontal)
                    }
                )
                .frame(height: 120)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Functions
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

func formatSpeed(_ speed: Float) -> String {
    if speed.truncatingRemainder(dividingBy: 1) == 0 {
        // It's a whole number
        return String(format: "%.0f", speed) + "x"
    } else if (speed * 10).truncatingRemainder(dividingBy: 1) == 0 {
        // One decimal place is enough
        return String(format: "%.1f", speed) + "x"
    } else {
        // Two decimal places
        return String(format: "%.2f", speed) + "x"
    }
}
