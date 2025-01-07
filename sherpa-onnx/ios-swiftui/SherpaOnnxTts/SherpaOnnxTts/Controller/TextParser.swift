//
//  TextParsing.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 10/13/24.
//  kevin: contains the class that parses text to enable streaming TTS
//  kevin: use streaming-text reading for fast response time and low ram usage

//  kevin:
//  rules:
//    - first chunk: first comma/period or first 50 words if none found
//    - second chunk: up to 100 words ending at comma or period if possible
//    - third and above chunk: up to 300 words ending at comma or period if possible
import Foundation

// kevin: delegate to interact with other modules
protocol TextParserDelegate: AnyObject {
    func textParser(_ parser: TextParser, didProduceChunk chunk: String)
    func textParserDidFinish(_ parser: TextParser, totalChunks: Int)
    func textParserDidTerminate(_ parser: TextParser, wordCount: Int)
}


class TextParser {
    // kevin: using weak var as a weak reference to prevent reference cycles (de-allocates the delegate automatically when TextParser obj is out of scope)
    weak var delegate: TextParserDelegate?
    private var inputStream: InputStream
    private var terminateFlag = false
    // kevin: (set) access control so it can be read but cannot be modified by other entities
    private(set) var totalChunks = 0
    private(set) var totalWordCount = 0
    
    // kevin: initialize with input stream
    init(inputStream: InputStream) {
        self.inputStream = inputStream
    }
    
    // kevin: function to start parsing on a global background thread
    func startParsing() {
        DispatchQueue.global(qos: .background).async {
            self.parse()
        }
    }
    
    // kevin: terminate parsing
    func stopParsing() {
        terminateFlag = true
    }
    
    // kevin: main parsing functions
    private func parse() {
        inputStream.open()
        // kevin: defer code is execute before function exits. closes input stream and return progress in terms of total words parsed and total chunk number
        defer {
            inputStream.close()
            if terminateFlag {
                DispatchQueue.main.async {
                    self.delegate?.textParserDidTerminate(self, wordCount: self.totalWordCount)
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.textParserDidFinish(self, totalChunks: self.totalChunks)
                }
            }
        }
        
        // stream-parsing parameters
        // buffersize in bytes
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var leftoverData = Data()
        var currentChunk = ""
        var currentChunkWords = 0
        var maxWordsInChunk = 50
        var chunkSizes = [50, 100]
        var chunkIndex = 0
        
        // kevin: while loop to read buffers and convert data into string
        while !terminateFlag && inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                print("TextParser: Error reading from input stream")
                break
            } else if bytesRead == 0 {
                // kevin: no bytes left in next buffer window
                break
            } else {
                // kevin: detect bytes in next buffer window, continue with parsing
                // kevin: combine leftover data from last buffer with current buffer
                let data = leftoverData + Data(bytes: buffer, count: bytesRead)
                // kevin: attenot to convert bytes data into string
                guard let text = String(data: data, encoding: .utf8) else {
                    // kevin: error if failed to convert bytes into string
                    print("TextParser: Encoding error")
                    break
                }
                
                let validDataLength = text.utf8.count
                // kevin: find valid utf8 characters in data
                let validaData = data.subdata(in: 0..<validDataLength)
                leftoverData = data.subdata(in: validDataLength..<data.count)
                
                // kevin: process the text
                // kevin: split the text into words
                let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                for word in words where !word.isEmpty {
                    if terminateFlag {
                        break
                    }
                    
                    currentChunk += word + " "
                    currentChunkWords += 1
                    totalWordCount += 1
                    
                    // kevin: check for commas or period
                    if word.contains(".") || word.contains("!") || word.contains("?") {
                        if chunkIndex == 0 || currentChunkWords >= maxWordsInChunk {
                            emitChunk(chunk: currentChunk.trimmingCharacters(in: .whitespaces))
                            currentChunk = ""
                            currentChunkWords = 0
                            totalChunks += 1
                            chunkIndex += 1
                            maxWordsInChunk = chunkSizes.count > chunkIndex ? chunkSizes[chunkIndex] : 300
                        }
                    } else if currentChunkWords >= maxWordsInChunk {
                        // kevin: end of chunk due to max words without comma or period
                        emitChunk(chunk: currentChunk.trimmingCharacters(in: .whitespaces))
                        currentChunk = ""
                        currentChunkWords = 0
                        totalChunks += 1
                        chunkIndex += 1
                        maxWordsInChunk = chunkSizes.count > chunkIndex ? chunkSizes[chunkIndex] : 300
                    }
                }
            }
        }
        
        // kevin: emit the last chunk if any
        if !currentChunk.isEmpty && !terminateFlag {
            emitChunk(chunk: currentChunk.trimmingCharacters(in: .whitespaces))
            totalChunks += 1
        }
    }
    
    // kevin: helper function to emit a chunk
    private func emitChunk(chunk: String) {
        DispatchQueue.main.async {
            self.delegate?.textParser(self, didProduceChunk: chunk)
        }
    }
}


// kevin: console logger delegate to log outputs for testing
class ConsoleLogger: TextParserDelegate{
    func textParser(_ parser: TextParser, didProduceChunk chunk: String) {
        print("Chunk: \(chunk)")
    }
    
    func textParserDidFinish(_ parser: TextParser, totalChunks: Int) {
        print("Finished parsing \(totalChunks) chunks.")
    }
    
    func textParserDidTerminate(_ parser: TextParser, wordCount: Int) {
        print("Parsing terminated after \(wordCount) words.")
    }
}
