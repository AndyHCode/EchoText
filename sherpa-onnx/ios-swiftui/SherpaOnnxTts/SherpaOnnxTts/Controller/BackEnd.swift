//
//  BackEnd.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 9/25/24.
//  Split off the logic from old ContentView.swift


import AVFoundation
import Foundation

@objcMembers
class TtsLogic: NSObject, ObservableObject, TextParserDelegate, AVAudioPlayerDelegate {
    @Published var text: String = ""
    @Published var showAlert: Bool = false
    @Published var filename: URL = NSURL() as URL
    @Published var audioPlayer: AVAudioPlayer!
    @Published var history: [String] = [] {
        didSet {
            saveHistory()
        }
    }
    @Published var isGenerating: Bool = false
    private var isParsingFinished: Bool = false
    // Ahmad: For mute/unmute
    @Published var isMuted: Bool = false
    
    var currentDocumentId: Int?
    
    private var tts: SherpaOnnxOfflineTtsWrapper?
    var DB: Database?
    var voiceProfileManager: VoiceProfileManager
    var fileDirectory: FileDirectory?
    
    // kevin: true to enable debug logs
    private var isTesting: Bool = true
    
    // kevin: new vars for TTS streaming
    private var textParser: TextParser?
    private var currentUUID: String?
    private var audioChunks: [URL] = []
    @Published var audioQueuePlayer: AVQueuePlayer?
    private var currentSpeakerId: String = "0"
    private var currentSpeed: Double = 1.0
    private var currentPitch: Double = 1.0
    private var playAudioFlag: Bool = true
    private let audioProcessingQueue: OperationQueue = {
        let queue = OperationQueue()
        // kevin: erial execution
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var tts_reserve: SherpaOnnxOfflineTtsWrapper?
    private var currentModel: String
    private let ttsReserveSemaphore = DispatchSemaphore(value: 1)
    
    // Progress tracking - Andy
    @Published var progress: Double? = nil
    // Batch inferecing - Andy
    @Published var isBatchProcessing: Bool = false
    var onConversionComplete: (() -> Void)?
    
    // Computed property to control progress bar visibility - Andy
    var showProgressBar: Bool {
        if let progress = progress {
            return progress < 1.0
        }
        return false
    }
    // Properties for TTS generation control
    private var terminateTtsGeneration: Bool = false
    
    // kevin: init for modules to adjust pitch
    let audioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    let pitchEffect = AVAudioUnitTimePitch()
    
    
    // Ahmad: Moved isPlaying to TtsLogic (fix play/pause button not updating)
    @Published var isPlaying: Bool = false
    
    // New property to track cancellation state - Andy
    @Published var isCancelled: Bool = false
    
    // PDF counter - Andy
    @Published var currentPdfNumber: Int = 0
    @Published var totalPdfs: Int = 0
    
    // kevin: edited to include file dir
    init(DB: Database? = nil, fileDirectory: FileDirectory? = nil, voiceProfileManager: VoiceProfileManager) {
        self.DB = DB
        self.fileDirectory = fileDirectory
        self.voiceProfileManager = voiceProfileManager
        self.tts_reserve = createOfflineTts(model: self.voiceProfileManager.model)
        self.currentModel = self.voiceProfileManager.model
        super.init()
        loadHistory()
    }
    
    // Ahmad: Delegate method called when audio finishes playing (fix play/pause button not updating)
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false  // Update the isPlaying state
        }
    }
    
    
    // Load history from UserDefaults - Andy
    private func loadHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "TtsHistory") as? [String] {
            self.history = savedHistory
        }
    }
    
    // Save history to UserDefaults - Andy
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: "TtsHistory")
    }
    
    // Method to add a new entry to history - Andy
    func addToHistory(text: String) {
        if history.count >= 25 {
            // Remove the oldest entry if we have 25
            history.removeFirst()
        }
        history.append(text)
    }
    
    // kevin: function to generate speech streaming
    func generateSpeechStreaming(playAudioFlag: Bool = true) {
        DispatchQueue.main.async {
            self.isGenerating = true
            // Reset progress bar - Andy
            self.progress = 0.0
        }
        self.isParsingFinished = false
        self.playAudioFlag = playAudioFlag
        let t = self.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if t.isEmpty {
            DispatchQueue.main.async {
                self.showAlert = true
            }
            return
        }
        
        DispatchQueue.main.async {
            self.addToHistory(text: t)
        }
        
        // If currentDocumentId is not set, ensure it's nil
        if self.currentDocumentId == nil {
            self.currentDocumentId = nil
        }
        
        let uuid = UUID().uuidString
        self.currentUUID = uuid
        self.audioChunks = []
        self.currentSpeakerId = "0"
        self.currentSpeed = self.voiceProfileManager.speed
        self.currentPitch = self.voiceProfileManager.pitch
        // kevin: initialize reserve tts
        self.currentModel = self.voiceProfileManager.model
        
        if isTesting {
            print("Starting generateSpeechStreaming with UUID: \(uuid)")
        }
        self.terminateTtsGeneration = false
        
        guard let data = t.data(using: .utf8) else {
            print("Failed to convert text to data")
            return
        }
        let inputStream = InputStream(data: data)
        // kevin: innitialize text parser with the corresponding delegate
        self.textParser = TextParser(inputStream: inputStream)
        self.textParser?.delegate = self
        
        // kevin: start parsing on a background thread
        DispatchQueue.global(qos: .background).async {
            self.textParser?.startParsing()
        }
    }
    
    // kevin: function to stop speech playback and parsing
    func stopSpeech() {
        // kevin: stop audio playback
        self.audioQueuePlayer?.pause()
        audioProcessingQueue.cancelAllOperations()
        if audioProcessingQueue.operations.isEmpty {
            print("stopSpeech: process queue emptied")
        } else {
            print("stopSpeech: failed to empty process queue")
        }
        self.audioQueuePlayer?.removeAllItems()
        self.audioQueuePlayer = nil
        self.audioChunks = []
        self.textParser?.stopParsing()
        self.textParser = nil
        self.terminateTtsGeneration = true
        self.isGenerating = false
        
        self.playAudioFlag = true
        
        // Signal cancellation for batch - Andy
        self.isCancelled = true
        self.isBatchProcessing = false
        self.onConversionComplete = nil
        
        // kevin: destroy and recreate TTS instance
        self.tts = nil
        self.tts_reserve = nil
        self.tts_reserve = createOfflineTts(model: self.voiceProfileManager.model)
        if self.tts_reserve == nil {
            print("stopSpeech: failed to init tts_reserve")
        } else {
            print("stopSpeech: tts_reserve initialized")
        }
        
        self.ttsReserveSemaphore.signal()
        
        // kevin: add audio stiching
        // kevin: stitch.stitch(uuid)
        
        if isTesting {
            print("Speech stopped and resources cleared.")
        }
        // Reset progress to hide progress bar - Andy
        if isBatchProcessing {
            DispatchQueue.main.async {
                self.progress = 1.0
            }
        } else {
            // Reset progress only if not batch processing
            DispatchQueue.main.async {
                self.progress = nil
            }
        }
        
        // Wait briefly to ensure all operations are truly cancelled
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Final check to ensure queue is empty
            if self.audioProcessingQueue.operations.isEmpty {
                print("stopSpeech: process queue emptied")
            } else {
                print("stopSpeech: failed to empty process queue")
                // Force cancel any remaining operations
                self.audioProcessingQueue.cancelAllOperations()
            }
            
            // Reset cancellation state after cleanup is complete
            if !self.isBatchProcessing {
                self.isCancelled = false
            }
        }
        
    }
    // Reset state for batch termination - Andy
    func resetCancelledState() {
        self.isCancelled = false
    }
    
    // kevin: text parser delegate called when a chunk is ready
    func textParser(_ parser: TextParser, didProduceChunk chunk: String) {
        audioProcessingQueue.addOperation {
            // calculate how much chunk needed for processing for progress bar - Andy
            let totalChunks = parser.totalChunks + 1
            let processedChunks = self.audioChunks.count + 1
            DispatchQueue.main.async {
                self.progress = Double(processedChunks) / Double(totalChunks)
            }
            if self.terminateTtsGeneration {
                if self.isTesting {
                    print("Skipping TTS generation for chunk due to termination.")
                }
                return
            }
            // kevin: wait until tts_reserve is initialized
            self.ttsReserveSemaphore.wait()
            // kevin: swap tts instance with tts_reserve
            self.tts = self.tts_reserve
            self.tts_reserve = nil
            
            self.tts_reserve = createOfflineTts(model: self.currentModel)
            self.ttsReserveSemaphore.signal()
            guard let tts = self.tts else {
                if self.isTesting {
                    print("TTS instance is nil.")
                }
                return
            }
            let speed = Float(self.currentSpeed)
            guard let uuid = self.currentUUID else { return }
            
            if self.isTesting {
                print("Received chunk: \(chunk)")
                print("Starting TTS generation for chunk.")
            }
            
            // kevin: pass self as arg to the callback
            let selfPointer = Unmanaged.passUnretained(self).toOpaque()
            
            let audio = tts.generateWithCallbackWithArg(
                text: chunk,
                callback: TtsLogic.ttsCallback,
                arg: selfPointer,
                sid: 0,
                speed: speed
            )
            
            if self.isTesting {
                print("TTS generation completed for chunk.")
            }
            
            if self.terminateTtsGeneration {
                if self.isTesting {
                    print("Terminated during TTS generation, skipping audio enqueue.")
                }
                return
            }
            
            // kevin: destroy current TTS instance after inference
            self.tts = nil
            
            // kevin: save audio to temporary directory
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let chunkNumber = self.audioChunks.count + 1
            let uniqueFilename = "\(uuid)_chunk\(chunkNumber).wav"
            let generatedFilename = tempDirectoryURL.appendingPathComponent(uniqueFilename)
            
            // kevin: check if pitch adjustment is needed
            if self.currentPitch != 1.0 {
                let tempAudioURL = tempDirectoryURL.appendingPathComponent("\(uuid)_temp_chunk\(chunkNumber).wav")
                let saveResult = audio.save(filename: tempAudioURL.path)
                let audioFile: AVAudioFile
                do {
                    audioFile = try AVAudioFile(forReading: tempAudioURL)
                } catch {
                    print("Failed to read audio file: \(error)")
                    return
                }
                
                guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                    print("Failed to create input buffer.")
                    return
                }
                do {
                    try audioFile.read(into: inputBuffer)
                } catch {
                    print("Failed to read audio file into buffer: \(error)")
                    return
                }
                
                let audioEngine = AVAudioEngine()
                let playerNode = AVAudioPlayerNode()
                let pitchEffect = AVAudioUnitTimePitch()
                
                // kevin: convert pitch (0.5~1.5) to AVAudio pitch's cents (+-0~2400)
                let pitchFactor = self.currentPitch
                let pitchInCents = 1200 * log2(pitchFactor)
                pitchEffect.pitch = Float(pitchInCents)
                
                audioEngine.attach(playerNode)
                audioEngine.attach(pitchEffect)
                
                audioEngine.connect(playerNode, to: pitchEffect, format: inputBuffer.format)
                audioEngine.connect(pitchEffect, to: audioEngine.mainMixerNode, format: inputBuffer.format)
                
                let outputFormat = audioEngine.mainMixerNode.outputFormat(forBus: 0)
                let maxFrames: AVAudioFrameCount = 4096
                
                do {
                    try audioEngine.enableManualRenderingMode(.offline, format: outputFormat, maximumFrameCount: maxFrames)
                } catch {
                    print("Failed to enable manual rendering mode: \(error)")
                    return
                }
                
                guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: maxFrames) else {
                    print("Failed to create output buffer.")
                    return
                }
                
                var isPlaying = true
                
                let outputFile: AVAudioFile
                do {
                    outputFile = try AVAudioFile(forWriting: generatedFilename, settings: outputFormat.settings)
                } catch {
                    print("Failed to create output audio file: \(error)")
                    return
                }
                
                playerNode.scheduleBuffer(inputBuffer, at: nil, options: []) {
                    isPlaying = false
                }
                
                do {
                    try audioEngine.start()
                } catch {
                    print("Failed to start audio engine: \(error)")
                    return
                }
                
                playerNode.play()
                
                while isPlaying || audioEngine.manualRenderingSampleTime < inputBuffer.frameLength {
                    do {
                        let status = try audioEngine.renderOffline(maxFrames, to: outputBuffer)
                        switch status {
                        case .success:
                            try outputFile.write(from: outputBuffer)
                        case .insufficientDataFromInputNode:
                            if !isPlaying {
                                break
                            }
                        case .cannotDoInCurrentContext:
                            continue
                        case .error:
                            print("Error during offline rendering")
                            isPlaying = false
                            break
                        @unknown default:
                            fatalError("Unknown render status: \(status)")
                        }
                    } catch {
                        print("Error during offline rendering: \(error)")
                        break
                    }
                }
                
                playerNode.stop()
                audioEngine.stop()
                
                do {
                    try FileManager.default.removeItem(at: tempAudioURL)
                } catch {
                    print("Failed to delete temp audio file: \(error)")
                }
                
                
            } else {
                // kevin: save the audio without pitch adjustment
                let saveResult = audio.save(filename: generatedFilename.path)
                if self.isTesting {
                    print("Audio saved to \(generatedFilename.path), save result: \(saveResult)")
                }
            }
            
            DispatchQueue.main.async {
                self.audioChunks.append(generatedFilename)
                if self.playAudioFlag {
                    self.enqueueAudioChunk(generatedFilename)
                } else {
                    if self.isTesting {
                        print("playAudioFlag is false; skipping enqueue of audio chunk.")
                    }
                }
            }
        }
    }
    
    
    // kevin: static callback function for TTS generation with callback
    static let ttsCallback: @convention(c) (UnsafePointer<Float>?, Int32, UnsafeMutableRawPointer?) -> Int32 = { samplesPointer, n, arg in
        guard let arg = arg else { return 0 }
        let selfInstance = Unmanaged<TtsLogic>.fromOpaque(arg).takeUnretainedValue()
        
        if selfInstance.terminateTtsGeneration {
            if selfInstance.isTesting {
                print("TTS generation terminated by stopSpeech().")
            }
            // stop generation
            return 0
        }
        // continue generation
        return 1
    }
    
    // kevin: delegate called when parsing is finished
    // Modified by Ahmad: Changed current naming logic from using UUID to sequential naming, saving as "Audio 1", "Audio 2" ...
    func textParserDidFinish(_ parser: TextParser, totalChunks: Int) {
        if isTesting {
            print("Text parsing finished. Total chunks: \(totalChunks)")
        }
        self.isParsingFinished = true
        self.checkIfGenerationIsComplete()
        audioProcessingQueue.addOperation {
            DispatchQueue.main.async {
                stitchAudio(uuid: self.currentUUID!) { result in
                    switch result {
                    case .success(let outputURL):
                        print("Audio stitched successfully: \(outputURL)")
                        
                        
                        // kevin: use fileDirectory to construct the file path
                        let dir3 = self.fileDirectory!.audiofilesDirectory.appendingPathComponent("\(self.currentUUID!)_stitched.wav")
                        let relativePath = self.fileDirectory!.relativePath(for: dir3)
                        
                        // Ahmad: Generate a name using the first few words of the text
                        let initialWordsAudioName = self.DB?.generateAudioNameFromText(self.text) ?? "Audio"
                        
                        //Ahmad: Formating date and setting it for the audio metadata
                        let dateGenerated: String = {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MMM/dd/yyyy h:mm:ss a" // Updated format
                            return formatter.string(from: Date())
                        }()
                        
                        
                        // Save text to file if no document is linked
                        var textFilePath = "#"
                        if self.currentDocumentId == nil {
                            // Use FileDirectory to manage paths
                            // Ensure this is properly initialized elsewhere if needed
                            let fileDirectory = FileDirectory()
                            let textFilesDirectory = fileDirectory.documentsDirectory.appendingPathComponent("textfiles", isDirectory: true)
                            
                            // Ensure the directory exists
                            try? FileManager.default.createDirectory(at: textFilesDirectory, withIntermediateDirectories: true, attributes: nil)
                            
                            // Create the text file URL
                            let textFileURL = textFilesDirectory.appendingPathComponent("\(self.currentUUID!).txt")
                            
                            do {
                                // Write the text to the file
                                try self.text.write(to: textFileURL, atomically: true, encoding: .utf8)
                                
                                // Save the relative path instead of the absolute path
                                textFilePath = fileDirectory.relativePath(for: textFileURL)
                                print("Text file saved at: \(textFileURL.path)")
                                
                            } catch {
                                print("Failed to save text to file: \(error)")
                            }
                        }
                        
                        
                        // Modified by Ahmad: Insert the audio into the database using the sequential name
                        self.DB!.insertAudio(
                            name: initialWordsAudioName,
                            filePath: relativePath,
                            dateGenerated: dateGenerated,
                            model: self.currentModel,
                            pitch: self.currentPitch,
                            speed: self.currentSpeed,
                            documentId: self.currentDocumentId,
                            textFilePath: textFilePath
                        )
                        
                        self.currentDocumentId = nil
                        
                        
                        // Andy: Set progress bar to max since it has completed the stitching progress
                        DispatchQueue.main.async {
                            self.onConversionComplete?()
                            // Clear the handler
                            self.onConversionComplete = nil
                            // Set progress to 100%
                            self.progress = 1.0
                        }
                        DispatchQueue.main.async {
                            self.onConversionComplete?()
                            // Clear the handler
                            self.onConversionComplete = nil
                        }
                        
                    case .failure(let error):
                        print("Failed to stitch audio: \(error)")
                    }
                }
            }
            OperationQueue.main.addOperation {
                self.checkIfGenerationIsComplete()
            }
        }
    }
    
    // kevin: delegate called when parsing is terminated
    func textParserDidTerminate(_ parser: TextParser, wordCount: Int) {
        if isTesting {
            print("Text parsing terminated at word count: \(wordCount)")
        }
    }
    
    // keivn: function to enqueue the audio chunk into AVQueuePlayer
    private func enqueueAudioChunk(_ url: URL) {
        if self.terminateTtsGeneration {
            if self.isTesting {
                print("Skipping enqueue of audio chunk due to termination.")
            }
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        
        if self.audioQueuePlayer == nil {
            self.audioQueuePlayer = AVQueuePlayer(items: [playerItem])
            
            // kevin: observer to observe when playback finishes
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
            
            configureAudioSession()
            
            if isTesting {
                print("Initialized AVQueuePlayer and started playback.")
            }
            
            // Ahmad: Set volume based on mute state without stopping playback
            self.audioQueuePlayer?.volume = isMuted ? 0.0 : 1.0
            self.audioQueuePlayer?.play()
            
        } else {
            self.audioQueuePlayer?.insert(playerItem, after: nil)
            if isTesting {
                print("Enqueued new audio chunk into AVQueuePlayer.")
            }
        }
    }
    
    // kevin: selector method called when playback finishes
    // kevin 11/24: moved flag and audio player logic to checkIfGeneartionIsComplete()
    @objc private func playerDidFinishPlaying(notification: Notification) {
        if isTesting {
            print("AVQueuePlayer finished playing an item.")
        }
        
        // kevin: put the played item from the notification
        if let playerItem = notification.object as? AVPlayerItem {
            // kevin: remove the played item from the queue
            self.audioQueuePlayer?.remove(playerItem)
        }
        
        // kevin: check if there are more items to play
        if self.audioQueuePlayer?.items().isEmpty ?? true {
            if isTesting {
                print("No more items in the queue.")
            }
            self.checkIfGenerationIsComplete()
        }
    }
    
    
    // kevin: config audio session for playback
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            if isTesting {
                print("Audio session configured for playback.")
            }
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // Method to play the audio
    func playAudio() {
        if let player = self.audioPlayer {
            player.play()
        } else {
            print("Audio player is not initialized")
        }
    }
    
    // kevin: method to change active model
    func changeModel(to model: String){
        voiceProfileManager.model = model
        if !isGenerating {
            stopSpeech()
        }
    }
    // a clear fuction, might need for batch infercing - Andy
    func reset() {
        // Clear audio related states - Andy
        self.audioQueuePlayer?.removeAllItems()
        self.audioQueuePlayer = nil
        self.audioChunks = []
        
        // Clear parser state - Andy
        self.textParser?.stopParsing()
        self.textParser = nil
        
        // Reset flags - Andy
        self.terminateTtsGeneration = false
        
        // Clear and reinitialize TTS - Andy
        self.tts = nil
        self.tts_reserve = nil
        self.tts_reserve = createOfflineTts(model: self.voiceProfileManager.model)
        
        // Signal semaphore - Andy
        self.ttsReserveSemaphore.signal()
        
        // Reset progress - Andy
        DispatchQueue.main.async {
            self.progress = 0.0
            self.isGenerating = false
        }
    }
    
    // kevin: function to check if generation/inference is completed, and set the cooresponding flags to their correct state
    private func checkIfGenerationIsComplete() {
        if self.isParsingFinished &&
            (self.audioQueuePlayer?.items().isEmpty ?? true) &&
            self.audioProcessingQueue.operationCount == 0 {
            if isTesting {
                print("Generation process is complete.")
            }
            DispatchQueue.main.async {
                self.isGenerating = false
            }
            self.audioQueuePlayer = nil
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
}



func stitchAudio(uuid: String, completion: @escaping (Result<URL, Error>) -> Void) {
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory
    
    do {
        // Get all files in the temp directory - Andy
        let tempFiles = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        
        // Filter files that match the pattern (uuid)_chunk(chunkNumber).wav - Andy
        let audioFiles = tempFiles.filter { url in
            let fileName = url.lastPathComponent
            let fileParts = fileName.split(separator: "_")
            
            // Check if filename has the UUID and matches the chunk format - Andy
            return fileParts.count > 1 && fileParts[0] == uuid && fileName.contains("chunk") && url.pathExtension == "wav"
        }.sorted { file1, file2 in
            // Extract and sort files by chunk number (ascending) - Andy
            let chunkNumber1 = extractChunkNumber(from: file1.lastPathComponent)
            let chunkNumber2 = extractChunkNumber(from: file2.lastPathComponent)
            return (chunkNumber1 ?? 0) < (chunkNumber2 ?? 0)
        }
        
        // Print the list of sorted audio chunk file names - Andy
        print("Audio chunks to be stitched:")
        audioFiles.forEach { print($0.lastPathComponent) }
        
        // Ensure there are audio files to stitch - Andy
        guard !audioFiles.isEmpty else {
            completion(.failure(NSError(domain: "StitchError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio files found to stitch"])))
            return
        }
        
        // Call the combineAudioFiles function to stitch the files together - Andy
        combineAudioFiles(audioFileURLs: audioFiles, outputFileName: "\(uuid)_stitched", completion: completion)
        
    } catch {
        completion(.failure(error))
    }
}

// Function to extract the chunk number using regular expression - Andy
private func extractChunkNumber(from filename: String) -> Int? {
    let pattern = "chunk(\\d+)"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let nsString = filename as NSString
    let results = regex?.matches(in: filename, options: [], range: NSRange(location: 0, length: nsString.length))
    
    if let match = results?.first, let range = Range(match.range(at: 1), in: filename) {
        let chunkNumberString = String(filename[range])
        return Int(chunkNumberString)
    }
    return nil
}


