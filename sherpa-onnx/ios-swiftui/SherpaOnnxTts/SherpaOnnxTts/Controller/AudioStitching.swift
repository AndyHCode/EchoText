//  AudioStitching.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 10/19/24.
//
import AVFoundation

// Function to append audio from URL to AVMutableCompositionTrack - Andy
extension AVMutableCompositionTrack {
    func appendAudio(url: URL) async throws {
        let newAsset = AVURLAsset(url: url)
        
        // Load the duration asynchronously - Andy
        let assetDuration = try await newAsset.load(.duration)
        let range = CMTimeRange(start: .zero, duration: assetDuration)
        let end = timeRange.end
        
        // Load the tracks asynchronously - Andy
        let tracks = try await newAsset.loadTracks(withMediaType: .audio)
        
        if let track = tracks.first {
            try insertTimeRange(range, of: track, at: end)
        } else {
            throw NSError(domain: "AudioTrackError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to append audio track"])
        }
    }
}

// Function to combine multiple audio files into a single .wav file - Andy
func combineAudioFiles(audioFileURLs: [URL], outputFileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
    let composition = AVMutableComposition()
    
    // Create an audio track in the composition - Andy
    guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        completion(.failure(NSError(domain: "CompositionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio track in composition"])))
        return
    }
    
    Task {
        do {
            for fileURL in audioFileURLs {
                try await compositionAudioTrack.appendAudio(url: fileURL)
            }
            
            // Use the FileDirectory class to get the path to the "audiofiles" directory - Andy
            let fileDirectory = FileDirectory()
            fileDirectory.createApplicationSupportDirectories()
            
            let fileManager = FileManager.default
            let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let audiofilesDirectory = supportURL.appendingPathComponent("audiofiles", isDirectory: true)
            
            // Prepare the destination URL in the "audiofiles" directory - Andy
            let outputURL = audiofilesDirectory.appendingPathComponent("\(outputFileName).wav")
            
            // Create an export session to save the combined audio file as .wav - Andy
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
                throw NSError(domain: "ExportSessionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
            }
            
            exportSession.outputFileType = .wav
            exportSession.outputURL = outputURL
            
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    completion(.success(outputURL))
                case .failed, .cancelled:
                    if let error = exportSession.error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown export error"])))
                    }
                default:
                    completion(.failure(NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export failed with unknown status"])))
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }
}
