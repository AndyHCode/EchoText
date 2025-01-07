// Struct for ModelProfiles table
struct Profile : Identifiable{
    var id: Int32
    var profileName: String
    var pitch: Double
    var speed: Double
    var model: String
}

struct AudioRecord : Identifiable{
    let id: Int
    var name: String
    let filePath: String
    let dateGenerated: String
    let model: String
    let pitch: Double
    let speed: Double
    // Ahmad: Optional, since not all audios may be linked to a document
    var documentId: Int?
    let textFilePath: String
    // Ahmad: New field to store the length in seconds
    let length: Int
    var isFavorite: Bool
}

struct DocumentRecord : Identifiable{
    let id: Int
    let documentName: String
    let uploadDate: String
    let filePath: String
    let fileType: String
}
