import Foundation
import SQLite3
import AVFoundation

class Database: ObservableObject {
    var db: OpaquePointer?
    // kevin: changed to a passed var and optional
    var fileDirectory: FileDirectory?
    
    // Initialize the database
    // kevin: edited to include fileDirectory
    init(fileDirectory: FileDirectory) {
        self.fileDirectory = fileDirectory
        
        
        openDatabase()
        createTables()
        
    }
    func deleteDatabase() {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let databaseURL = supportURL.appendingPathComponent("database/audios.sqlite")
        
        do {
            // Remove the database file
            try FileManager.default.removeItem(at: databaseURL)
            print("Database deleted successfully")
        } catch {
            print("Error deleting database: \(error.localizedDescription)")
        }
    }
    
    // Open the SQLite database
    func openDatabase() {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let databaseURL = supportURL.appendingPathComponent("database/audios.sqlite")
        print("Database path: \(databaseURL.path)")
        
        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    // Create necessary tables
    func createTables() {
        // Create Audios table if it doesn't exist
        createAudiosTable()
        
        // Create ModelProfiles table if it doesn't exist
        createModelProfilesTable()
        
        // Create Document table if it doesn't exist
        createDocumentTable()
    }
    
    // Create the Audios table
    private func createAudiosTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS Audios(
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT,
        FilePath TEXT,
        DateGenerated TEXT,
        Model TEXT,
        Pitch REAL,
        Speed REAL,
        DocumentId INTEGER,
        TextFilePath TEXT,
        Length INTEGER, -- New column for audio length in seconds
        IsFavorite INTEGER DEFAULT 0,
        FOREIGN KEY(DocumentId) REFERENCES Documents(Id)  -- Foreign key constraint
        );
        """
        executeCreateTableStatement(createTableString)
    }
    
    // Create the ModelProfiles table
    private func createModelProfilesTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS ModelProfiles(
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        ProfileName TEXT,
        Pitch REAL,
        Speed REAL,
        Model TEXT);
        """
        executeCreateTableStatement(createTableString)
    }
    
    // Create the Document table
    private func createDocumentTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS Documents(
        Id INTEGER PRIMARY KEY AUTOINCREMENT,
        DocumentName TEXT,
        UploadDate TEXT,
        FilePath TEXT,
        FileType TEXT);
        """
        executeCreateTableStatement(createTableString)
    }
    
    // General function to execute create table statements
    private func executeCreateTableStatement(_ createTableString: String) {
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Table created.")
            } else {
                print("Table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    // Ahmad: Generate Name Using Initial Words from User Text // Modified by Ahmad: 11/13/24. Changed limit and formatting.
    func generateAudioNameFromText(_ text: String, maxCharLimit: Int = 25) -> String {
        // Remove excessive spaces and newlines, then trim whitespace
        let trimmedText = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split into words and start building the name
        var result = ""
        
        for word in trimmedText.split(separator: " ") {
            let wordString = String(word) // Ensure `word` is a `String`
            
            let potentialResult = result.isEmpty ? wordString : result + " " + wordString
            
            // Check if adding the next word exceeds maxCharLimit
            if potentialResult.count > maxCharLimit {
                // If adding the full word exceeds the limit, truncate it and add "..."
                let remainingChars = maxCharLimit - result.count
                if remainingChars > 0 {
                    result += " " + String(wordString.prefix(remainingChars)) + "..."
                }
                break
            } else {
                result = potentialResult
            }
        }
        
        return result
    }
    
    
    
    
    // Insert a new audio record
    func insertAudio(
        name: String,
        filePath: String,
        dateGenerated: String,
        model: String,
        pitch: Double,
        speed: Double,
        documentId: Int?,
        textFilePath: String?,
        isFavorite: Bool = false
    ) {
        
        getAudioLength(from: filePath) { [weak self] length in
            guard let self = self else { return }
            let audioLength = length ?? 1
            
            let insertStatementString = """
            INSERT INTO Audios (Name, FilePath, DateGenerated, Model, Pitch, Speed, DocumentId, TextFilePath, Length, IsFavorite)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            let values: [Any?] = [
                name,
                filePath,
                dateGenerated,
                model,
                pitch,
                speed,
                documentId,
                textFilePath ?? "",
                audioLength,
                isFavorite ? 1 : 0
            ]
            self.executeInsertStatement(insertStatementString, values: values)
            print("Inserted audio with length: \(audioLength) seconds")
        }
    }
    
    
    // Insert a new document record
    func insertDocument(documentName: String, uploadDate: String, filePath: String, fileType: String) {
        let insertStatementString = "INSERT INTO Documents (DocumentName, UploadDate, FilePath, FileType) VALUES (?, ?, ?, ?);"
        executeInsertStatement(insertStatementString, values: [documentName, uploadDate, filePath, fileType])
    }
    
    // Execute insert statements
    private func executeInsertStatement(_ statement: String, values: [Any?]) {
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, statement, -1, &insertStatement, nil) == SQLITE_OK {
            for (index, value) in values.enumerated() {
                let position = Int32(index + 1)
                if let strValue = value as? String {
                    sqlite3_bind_text(insertStatement, position, (strValue as NSString).utf8String, -1, nil)
                } else if let doubleValue = value as? Double {
                    sqlite3_bind_double(insertStatement, position, doubleValue)
                } else if let intValue = value as? Int {
                    sqlite3_bind_int(insertStatement, position, Int32(intValue))
                } else if value == nil {
                    sqlite3_bind_null(insertStatement, position)
                } else {
                    print("Unsupported data type for binding at position \(position)")
                }
            }
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    // Fetch all audio records from the "Audios" table
    // Returns an array of AudioRecord objects representing all stored audio records
    // Fetch all audio records from the "Audios" table
    func fetchAllAudios() -> [AudioRecord] {
        var queryStatement: OpaquePointer?
        let queryStatementString = """
        SELECT Id, Name, FilePath, DateGenerated, Model, Pitch, Speed, DocumentId, TextFilePath, Length, IsFavorite
        FROM Audios;
        """
        var audios: [AudioRecord] = []
        
        // Prepare the SQL statement for fetching all records
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            // Loop through the results and create AudioRecord objects
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                
                // Safely convert each column to String or handle it as nil (in case of null value)
                let name = sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) } ?? ""
                var filePath = sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) } ?? ""
                if let decodedFilePath = filePath.removingPercentEncoding {
                    filePath = decodedFilePath
                }
                let dateGenerated = sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) } ?? ""
                let model = sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) } ?? ""
                print("databaseFetchalladuios: \(filePath)")
                
                // Extract double values for pitch and speed
                let pitch = sqlite3_column_double(queryStatement, 5)
                let speed = sqlite3_column_double(queryStatement, 6)
                
                var documentId: Int? = nil
                if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
                    documentId = Int(sqlite3_column_int(queryStatement, 7))
                }
                
                // Handle potential null for text file path
                let textFilePath = sqlite3_column_text(queryStatement, 8).flatMap { String(cString: $0) } ?? ""
                
                let length = Int(sqlite3_column_int(queryStatement, 9)) // Fetch the length
                let isFavorite = sqlite3_column_int(queryStatement, 10) == 1
                
                
                // Create an AudioRecord object and append it to the array
                let audio = AudioRecord(
                    id: id,
                    name: name,
                    filePath: filePath,
                    dateGenerated: dateGenerated,
                    model: model,
                    pitch: pitch,
                    speed: speed,
                    documentId: documentId,
                    textFilePath: textFilePath,
                    length: length,
                    isFavorite: isFavorite
                )
                audios.append(audio)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("SELECT statement could not be prepared. Error: \(errorMessage)")
        }
        
        // Finalize the statement to clean up resources
        sqlite3_finalize(queryStatement)
        return audios
    }
    // Returns the total number of audio records stored in the database
    func countAudios() -> Int {
        let queryStatementString = "SELECT COUNT(*) FROM Audios;"
        var queryStatement: OpaquePointer?
        var count: Int = 0
        
        // Prepare the SQL statement for counting rows
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            // Execute the SQL statement and retrieve the result
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(queryStatement, 0)) // Get the count from the first column
                print("Audio count retrieved: \(count)") // Log the count for debugging purposes
            } else {
                print("Could not retrieve count.") // Log an error if the count can't be retrieved
            }
        } else {
            print("COUNT statement could not be prepared. Error: \(String(cString: sqlite3_errmsg(db)!))") // Log an error if the statement can't be prepared
        }
        
        // Finalize the statement to clean up resources
        sqlite3_finalize(queryStatement)
        return count
    }
    // Delete an audio record by Id
    func deleteAudio(id: Int) {
        let deleteStatementString = "DELETE FROM Audios WHERE Id = ?;"
        executeDeleteStatement(deleteStatementString, id: id)
    }
    
    func fetchDocumentByFilePath(filePath: String) -> DocumentRecord? {
        let queryStatementString = "SELECT Id, DocumentName, UploadDate, FilePath, FileType FROM Documents WHERE FilePath = ?;"
        var queryStatement: OpaquePointer?
        var document: DocumentRecord?
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (filePath as NSString).utf8String, -1, nil)
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let documentName = sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) } ?? ""
                let uploadDate = sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) } ?? ""
                let filePath = sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) } ?? ""
                let fileType = sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) } ?? ""
                
                document = DocumentRecord(
                    id: id,
                    documentName: documentName,
                    uploadDate: uploadDate,
                    filePath: filePath,
                    fileType: fileType
                )
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("SELECT statement could not be prepared. Error: \(errorMessage)")
        }
        sqlite3_finalize(queryStatement)
        return document
    }
    
    func fetchDocumentById(documentId: Int) -> DocumentRecord? {
        let queryStatementString = "SELECT Id, DocumentName, UploadDate, FilePath, FileType FROM Documents WHERE Id = ?;"
        var queryStatement: OpaquePointer?
        var document: DocumentRecord?
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(documentId))
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let documentName = sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) } ?? ""
                let uploadDate = sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) } ?? ""
                let filePath = sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) } ?? ""
                let fileType = sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) } ?? ""
                
                document = DocumentRecord(
                    id: id,
                    documentName: documentName,
                    uploadDate: uploadDate,
                    filePath: filePath,
                    fileType: fileType
                )
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("SELECT statement could not be prepared. Error: \(errorMessage)")
        }
        sqlite3_finalize(queryStatement)
        return document
    }
    
    // Delete a document record by Id
    func deleteDocument(id: Int) {
        let deleteStatementString = "DELETE FROM Documents WHERE Id = ?;"
        executeDeleteStatement(deleteStatementString, id: id)
    }
    
    // Execute delete statements
    private func executeDeleteStatement(_ statement: String, id: Int) {
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, statement, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteStatement, 1, Int32(id))
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared.")
        }
        sqlite3_finalize(deleteStatement)
    }
    
    // Update an audio record by Id
    func updateAudio(
        id: Int,
        name: String,
        filePath: String,
        dateGenerated: String,
        model: String,
        pitch: Double,
        speed: Double,
        documentId: Int?,
        textFilePath: String?,
        isFavorite: Bool
    ) {
        let updateStatementString = """
            UPDATE Audios SET Name = ?, FilePath = ?, DateGenerated = ?, Model = ?, Pitch = ?, Speed = ?, DocumentId = ?, TextFilePath = ?, IsFavorite = ? WHERE Id = ?;
            """
        var updateStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, (filePath as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 3, (dateGenerated as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 4, (model as NSString).utf8String, -1, nil)
            sqlite3_bind_double(updateStatement, 5, pitch)
            sqlite3_bind_double(updateStatement, 6, speed)
            if let documentId = documentId {
                sqlite3_bind_int(updateStatement, 7, Int32(documentId))
            } else {
                sqlite3_bind_null(updateStatement, 7)
            }
            if let textPath = textFilePath {
                sqlite3_bind_text(updateStatement, 8, (textPath as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_text(updateStatement, 8, "#", -1, nil)
            }
            sqlite3_bind_int(updateStatement, 9, isFavorite ? 1 : 0)
            sqlite3_bind_int(updateStatement, 10, Int32(id))
            
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared.")
        }
        sqlite3_finalize(updateStatement)
    }
    
    // Update a document record by Id
    func updateDocument(id: Int, documentName: String, uploadDate: String, filePath: String, fileType: String) {
        let updateStatementString = """
            UPDATE Documents
            SET DocumentName = ?,
                UploadDate = ?,
                FilePath = ?,
                FileType = ?
            WHERE Id = ?;
        """
        
        var updateStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (documentName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, (uploadDate as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 3, (filePath as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 4, (fileType as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 5, Int32(id))
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated document in database")
            } else {
                if let errmsg = sqlite3_errmsg(db) {
                    print("Error updating document: \(String(cString: errmsg))")
                }
            }
        } else {
            if let errmsg = sqlite3_errmsg(db) {
                print("Error preparing update statement: \(String(cString: errmsg))")
            }
        }
        
        sqlite3_finalize(updateStatement)
    }
    // Link an audio record with a document
    func linkAudioToDocument(audioId: Int, documentId: Int) {
        let updateStatementString = "UPDATE Audios SET DocumentId = ? WHERE Id = ?;"
        var updateStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(updateStatement, 1, Int32(documentId))
            sqlite3_bind_int(updateStatement, 2, Int32(audioId))
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully linked audio to document.")
            } else {
                print("Could not link audio to document.")
            }
        } else {
            print("LINK statement could not be prepared.")
        }
        sqlite3_finalize(updateStatement)
    }
    
    // Search for records in both Audios and Document tables based on a keyword
    func searchRecords(keyword: String) -> ([AudioRecord], [DocumentRecord]) {
        var audioRecords: [AudioRecord] = []
        var documentRecords: [DocumentRecord] = []
        
        // Search in Audios
        let audioQuery = "SELECT Id, Name, Text, FilePath, DateGenerated, Model, Pitch, Speed, DocumentId, TextFilePath, Length FROM Audios WHERE Name LIKE ?;"
        if let queryStatement = prepareQueryStatement(audioQuery, keyword: "%\(keyword)%") {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let name = sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) } ?? ""
                let filePath = sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) } ?? ""
                let dateGenerated = sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) } ?? ""
                let model = sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) } ?? ""
                let pitch = sqlite3_column_double(queryStatement, 5)
                let speed = sqlite3_column_double(queryStatement, 6)
                var documentId: Int? = nil
                if sqlite3_column_type(queryStatement, 7) != SQLITE_NULL {
                    documentId = Int(sqlite3_column_int(queryStatement, 7))
                }
                let textFilePath = sqlite3_column_text(queryStatement, 8).flatMap { String(cString: $0) } ?? ""
                let length = Int(sqlite3_column_int(queryStatement, 9))
                let isFavorite = sqlite3_column_int(queryStatement, 10) == 1 // New line
                
                
                
                let audio = AudioRecord(id: id, name: name,filePath: filePath, dateGenerated: dateGenerated,model: model, pitch: pitch, speed: speed, documentId: documentId, textFilePath: textFilePath, length: length, isFavorite: isFavorite)
                audioRecords.append(audio)
            }
            sqlite3_finalize(queryStatement)
        }
        
        // Search in Document
        let documentQuery = "SELECT Id, DocumentName, UploadDate, FilePath, FileType FROM Document WHERE DocumentName LIKE ?;"
        if let queryStatement = prepareQueryStatement(documentQuery, keyword: "%\(keyword)%") { // Added wildcards
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let documentName = String(cString: sqlite3_column_text(queryStatement, 1)!)
                let uploadDate = String(cString: sqlite3_column_text(queryStatement, 2)!)
                let filePath = String(cString: sqlite3_column_text(queryStatement, 3)!)
                let fileType = String(cString: sqlite3_column_text(queryStatement, 4)!)
                
                // Adjusted to include uploadDate and fileType
                let document = DocumentRecord(id: id, documentName: documentName, uploadDate: uploadDate, filePath: filePath, fileType: fileType)
                documentRecords.append(document)
            }
            sqlite3_finalize(queryStatement)
        }
        
        return (audioRecords, documentRecords)
    }
    // Prepare a query statement with keyword
    private func prepareQueryStatement(_ query: String, keyword: String) -> OpaquePointer? {
        var queryStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (keyword as NSString).utf8String, -1, nil)
            return queryStatement
        } else {
            print("QUERY statement could not be prepared.")
            return nil
        }
    }
    
    // kevin: function to add a profile to the database
    func saveProfile(_ profile: Profile) -> Int32? {
        let insertStatementString = """
        INSERT INTO ModelProfiles (ProfileName, Pitch, Speed, Model) VALUES (?, ?, ?, ?);
        """
        
        var insertStatement: OpaquePointer?
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (profile.profileName as NSString).utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 2, profile.pitch)
            sqlite3_bind_double(insertStatement, 3, profile.speed)
            sqlite3_bind_text(insertStatement, 4, (profile.model as NSString).utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                let rowID = sqlite3_last_insert_rowid(db)
                print("Successfully inserted profile with id \(rowID).")
                return Int32(rowID)
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not insert profile. Error: \(errorMessage)")
                return nil
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("INSERT statement could not be prepared. Error: \(errorMessage)")
            return nil
        }
    }
    
    // kevin: function to update profile
    func updateProfile(_ profile: Profile) {
        let updateStatementString = """
        UPDATE ModelProfiles SET Pitch = ?, Speed = ?, Model = ? WHERE Id = ?;
        """
        
        var updateStatement: OpaquePointer?
        defer {
            sqlite3_finalize(updateStatement)
        }
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_double(updateStatement, 1, profile.pitch)
            sqlite3_bind_double(updateStatement, 2, profile.speed)
            sqlite3_bind_text(updateStatement, 3, (profile.model as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 4, profile.id)
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated profile with id \(profile.id).")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not update profile. Error: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("UPDATE statement could not be prepared. Error: \(errorMessage)")
        }
    }
    
    // kevin: function to load a profile
    func loadProfile(profileName: String) -> Profile? {
        let queryStatementString = """
        SELECT Id, ProfileName, Pitch, Speed, Model FROM ModelProfiles WHERE ProfileName = ?;
        """
        
        var queryStatement: OpaquePointer?
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        var profile: Profile?
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (profileName as NSString).utf8String, -1, nil)
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                guard
                    let profileNameCStr = sqlite3_column_text(queryStatement, 1),
                    let modelCStr = sqlite3_column_text(queryStatement, 4)
                else {
                    print("Failed to retrieve profile data.")
                    return nil
                }
                let profileName = String(cString: profileNameCStr)
                let pitch = sqlite3_column_double(queryStatement, 2)
                let speed = sqlite3_column_double(queryStatement, 3)
                let model = String(cString: modelCStr)
                
                profile = Profile(id: id, profileName: profileName, pitch: pitch, speed: speed, model: model)
                print("Successfully loaded profile: \(profileName)")
            } else {
                print("Profile not found.")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SELECT statement could not be prepared. Error: \(errorMessage)")
        }
        
        return profile
    }
    
    // kevin: function to fetch all profile data
    func fetchAllProfiles() -> [Profile] {
        var profiles: [Profile] = []
        let queryStatementString = """
        SELECT Id, ProfileName, Pitch, Speed, Model FROM ModelProfiles;
        """
        var queryStatement: OpaquePointer?
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                guard
                    let profileNameCStr = sqlite3_column_text(queryStatement, 1),
                    let modelCStr = sqlite3_column_text(queryStatement, 4)
                else {
                    print("Failed to retrieve profile data.")
                    continue
                }
                let profileName = String(cString: profileNameCStr)
                let pitch = sqlite3_column_double(queryStatement, 2)
                let speed = sqlite3_column_double(queryStatement, 3)
                let model = String(cString: modelCStr)
                
                let profile = Profile(id: id, profileName: profileName, pitch: pitch, speed: speed, model: model)
                profiles.append(profile)
            }
            print("Successfully retrieved all profiles.")
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("SELECT statement could not be prepared. Error: \(errorMessage)")
        }
        
        return profiles
    }
    
    // kevin: fuction to rename a profile
    func renameProfile(oldName: String, newName: String) -> Bool {
        let updateStatementString = "UPDATE ModelProfiles SET ProfileName = ? WHERE ProfileName = ?;"
        var updateStatement: OpaquePointer?
        defer {
            sqlite3_finalize(updateStatement)
        }
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (newName as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, (oldName as NSString).utf8String, -1, nil)
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully renamed profile.")
                return true
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not rename profile. Error: \(errorMessage)")
                return false
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("UPDATE statement could not be prepared. Error: \(errorMessage)")
            return false
        }
    }
    
    // kevin: function to delete a profile
    func deleteProfile(profileName: String) -> Bool {
        let deleteStatementString = "DELETE FROM ModelProfiles WHERE ProfileName = ?;"
        var deleteStatement: OpaquePointer?
        defer {
            sqlite3_finalize(deleteStatement)
        }
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, (profileName as NSString).utf8String, -1, nil)
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted profile.")
                return true
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Could not delete profile. Error: \(errorMessage)")
                return false
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("DELETE statement could not be prepared. Error: \(errorMessage)")
            return false
        }
    }
    
    //modified fetchAllDocuments - Andy
    func fetchAllDocuments() -> [DocumentRecord] {
        var documents: [DocumentRecord] = []
        let queryStatementString = "SELECT Id, DocumentName, UploadDate, FilePath, FileType FROM Documents;"
        var queryStatement: OpaquePointer?
        
        print("Attempting to fetch documents from database")
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(queryStatement, 0))
                let documentName = sqlite3_column_text(queryStatement, 1).flatMap { String(cString: $0) } ?? ""
                let uploadDate = sqlite3_column_text(queryStatement, 2).flatMap { String(cString: $0) } ?? ""
                var filePath = sqlite3_column_text(queryStatement, 3).flatMap { String(cString: $0) } ?? ""
                let fileType = sqlite3_column_text(queryStatement, 4).flatMap { String(cString: $0) } ?? ""
                
                print("Found document: id=\(id), name=\(documentName), path=\(filePath)")
                
                let document = DocumentRecord(
                    id: id,
                    documentName: documentName,
                    uploadDate: uploadDate,
                    filePath: filePath,
                    fileType: fileType
                )
                documents.append(document)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db)!)
            print("Error fetching documents: \(errorMessage)")
        }
        
        sqlite3_finalize(queryStatement)
        print("Total documents fetched: \(documents.count)")
        return documents
    }
    //Ahmad: function to get audio length
    func getAudioLength(from filePath: String, completion: @escaping (Int?) -> Void) {
        // Resolve the full URL using FileDirectory
        let fileDirectory = FileDirectory() // Ensure this is properly initialized
        let url = fileDirectory.fullURL(for: filePath)
        
        // Check if the file exists at the resolved URL
        if !FileManager.default.fileExists(atPath: url.path) {
            print("File does not exist at: \(url.path)")
            completion(nil)
            return
        }
        
        // Load the AVAsset and calculate the duration
        let asset = AVAsset(url: url)
        
        Task {
            do {
                // Load the duration asynchronously
                let duration = try await asset.load(.duration)
                let durationInSeconds = CMTimeGetSeconds(duration)
                // Round up the duration and ensure a minimum of 1 second
                let length = max(1, Int(ceil(durationInSeconds)))
                
                // Debug statement to print the audio length
                print("Audio Length: \(length) seconds")
                
                // Return the length using the completion handler
                completion(length)
            } catch {
                print("Failed to load duration with error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
}
