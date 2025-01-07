import XCTest
@testable import SherpaOnnxTts

class TextParserTests: XCTestCase {
    func testBasicParsing() {
        let parsingExpectation = expectation(description: "Parsing should complete")
        
        let sampleText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque sit amet accumsan tortor. \
        Suspendisse potenti. Sed vulputate, ligula eget mollis auctor, sapien orci aliquam enim, \
        id varius quam elit eu turpis. Nulla facilisi. Donec vitae tortor sit amet odio fermentum \
        bibendum. Curabitur at lacus ac velit ornare lobortis.
        """
        
        guard let data = sampleText.data(using: .utf8) else {
            XCTFail("Failed to encode sample text")
            return
        }
        let inputStream = InputStream(data: data)
        
        let parser = TextParser(inputStream: inputStream)
        let delegate = TestParserDelegate(expectation: parsingExpectation)
        parser.delegate = delegate
        
        parser.startParsing()
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        let expectedChunks = [
            "Lorem ipsum dolor sit amet,",
            """
            consectetur adipiscing elit. Quisque sit amet accumsan tortor. Suspendisse potenti. \
            Sed vulputate, ligula eget mollis auctor, sapien orci aliquam enim, id varius quam \
            elit eu turpis.
            """,
            """
            Nulla facilisi. Donec vitae tortor sit amet odio fermentum bibendum. Curabitur at \
            lacus ac velit ornare lobortis.
            """
        ].map { $0.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
        
        XCTAssertEqual(delegate.chunks.count, expectedChunks.count, "Number of chunks does not match expected count")
        
        for (index, chunk) in delegate.chunks.enumerated() {
            let expectedChunk = expectedChunks[index]
            XCTAssertEqual(chunk, expectedChunk, "Chunk \(index + 1) does not match expected output")
        }
    }
}

class TestParserDelegate: TextParserDelegate {
    let expectation: XCTestExpectation
    var chunks: [String] = []
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func textParser(_ parser: TextParser, didProduceChunk chunk: String) {
        chunks.append(chunk)
    }
    
    func textParserDidFinish(_ parser: TextParser, totalChunks: Int) {
        expectation.fulfill()
    }
    
    func textParserDidTerminate(_ parser: TextParser, wordCount: Int) {
        // kevin: not used
    }
}
