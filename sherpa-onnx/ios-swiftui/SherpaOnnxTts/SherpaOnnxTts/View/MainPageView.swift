//
//  MainPageView.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 9/25/24.
//
//  Split off the text input page from ContentView.swift

import SwiftUI

struct MainPageView: View {
    //kevin: changed to env object
    @EnvironmentObject var ttsLogic: TtsLogic
    
    // Ahmad: Access the current color scheme (light or dark mode)
    @Environment(\.colorScheme) var colorScheme
    
    // Harsh Bhagat: Define the maximum word limit
    private let maxWordLimit = 10_000 // done by Harsh Bhaga
    // unselect text editor bool - Andy
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            HStack {
                Image(colorScheme == .dark ? "logo_dark" : "logo_light")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("EchoText")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                // counter UI for batch PDF - Andy
                if ttsLogic.isBatchProcessing && ttsLogic.totalPdfs > 0 {
                    Text("PDF \(ttsLogic.currentPdfNumber)/\(ttsLogic.totalPdfs)")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Capsule())
                        .animation(.easeInOut, value: ttsLogic.currentPdfNumber)
                }
                
            }
            .padding(.bottom, 10)
            
            // Instruction Text
            // Modified by Ahmad: Added mute/unmute to main page.
            HStack {
                Text("Please input your text below")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                
                // kevin: word count at bottom right corner
                // Modified by Ahmad: Moved to the top, next instruction text.
                Text("\(ttsLogic.text.split { $0.isWhitespace }.count)/\(maxWordLimit) words")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                
            }
            ZStack {
                // Text Editor for Input with dynamic height
                TextEditor(text: $ttsLogic.text)
                    .focused($isTextEditorFocused)
                    .font(.body)
                    .padding(10)
                    .cornerRadius(20)
                    .frame(maxHeight: 600)
                
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .disableAutocorrection(true)
                    .disabled(ttsLogic.isGenerating || ttsLogic.isBatchProcessing)
                    .opacity(ttsLogic.isGenerating || ttsLogic.isBatchProcessing ? 0.6 : 1.0)
                    .onChange(of: ttsLogic.text) { newText in
                        // Harsh Bhagat: Calculate the current word count
                        let words = newText.split { $0.isWhitespace }
                        let wordCount = words.count
                        
                        if wordCount > maxWordLimit {
                            // Limit text to 10,000 words and prevent excess words from being pasted - done by Harsh Bhagat
                            ttsLogic.text = words.prefix(maxWordLimit).joined(separator: " ")
                            // Show alert - done by Harsh Bhagat
                            ttsLogic.showAlert = true
                        }
                    }
            }
            
            HStack {
                
                Spacer()
                // Mute/Unmute Button
                Button(action: {
                    ttsLogic.isMuted.toggle()
                    ttsLogic.audioQueuePlayer?.volume = ttsLogic.isMuted ? 0.0 : 1.0
                }) {
                    Image(systemName: ttsLogic.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(ttsLogic.isBatchProcessing ? .gray : (ttsLogic.isMuted ? .red : .blue))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(.systemGray5)))
                        .shadow(radius: 3)
                        .opacity(ttsLogic.isBatchProcessing ? 0.6 : 1.0)
                }
                .disabled(ttsLogic.isBatchProcessing)
                
                
                
                Spacer()
                Button(action: {
                    isTextEditorFocused = false
                    // kevin: changed to call streaming tts, and check conditions to switch between then generate and terminate buttons
                    if ttsLogic.isGenerating {
                        ttsLogic.stopSpeech()
                        // Ahmad: Reset play/pause state when generation stops
                        ttsLogic.isPlaying = false
                    } else {
                        DispatchQueue.global(qos: .background).async {
                            ttsLogic.generateSpeechStreaming(playAudioFlag: true)
                            // Ahmad: Set isPlaying to true immediately when generation starts
                            DispatchQueue.main.async {
                                ttsLogic.isPlaying = true}
                        }
                    }
                }) {
                    //Ahmad: New generate button UI
                    Image(systemName: ttsLogic.isGenerating ? "stop.fill" : "mic.fill")
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(ttsLogic.isGenerating ? Color.red : Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                    
                }
                .disabled(ttsLogic.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                // done by Harsh Bhagat
                .alert(isPresented: $ttsLogic.showAlert) {
                    Alert(title: Text("Word Limit Reached"), message: Text("You have reached the maximum word limit of \(maxWordLimit)."))
                }
                Spacer()
                
                // Ahmad: Conditionally display either Clear Text or Play/Pause Button
                if ttsLogic.isGenerating {
                    // Play/Pause Button - appears when generation is active
                    Button(action: {
                        if ttsLogic.isPlaying {
                            ttsLogic.audioQueuePlayer?.pause()
                            ttsLogic.isPlaying = false
                        } else {
                            ttsLogic.audioQueuePlayer?.play()
                            ttsLogic.isPlaying = true
                        }
                    }) {
                        Image(systemName: ttsLogic.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(ttsLogic.isBatchProcessing ? .gray : .blue)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(.systemGray5)))
                            .shadow(radius: 3)
                            .opacity(ttsLogic.isBatchProcessing ? 0.6 : 1.0)
                    }
                    .disabled(ttsLogic.isBatchProcessing)
                } else {
                    // Ahmad: Clear Text Button - only visible when not generating
                    Button(action: {
                        ttsLogic.text = ""
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(ttsLogic.isBatchProcessing ? .gray : (ttsLogic.text.isEmpty ? .gray : .red))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color(.systemGray5)))
                            .shadow(radius: 3)
                            .opacity(ttsLogic.isBatchProcessing ? 0.6 : 1.0)
                    }
                    // Disable if there's no text or during batch processing - Andy
                    .disabled(ttsLogic.text.isEmpty || ttsLogic.isBatchProcessing)
                }
                Spacer()
            }
            .padding(10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.2),
                        Color.blue.opacity(0.4),
                        Color.blue.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .allowsHitTesting(false)
            )
            // Rounded corners for the background
            .cornerRadius(30)
            .padding(.horizontal)
            // Set a fixed height for the button row
            .frame(height: 50)
            
            
            
            // added progress bar - Andy
            ZStack {
                // Invisible ProgressView to reserve space
                ProgressView(value: 0.0)
                    .progressViewStyle(LinearProgressViewStyle())
                // Makes it invisible, but it still takes up space, wont allow UI to shift when progress bar is displayed
                    .opacity(0)
                    .padding(.bottom, 12)
                
                if ttsLogic.showProgressBar {
                    ProgressView(value: ttsLogic.progress ?? 0.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
            }
        }
        // unselect text editor - Andy
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            isTextEditorFocused = false
        }
    }
}
