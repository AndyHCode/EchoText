//
//  ModelItem.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/28/24.
//

import Foundation
import SwiftUI

class ModelItem: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    var originalName: String
    
    init(name: String) {
        self.name = name
        self.originalName = name
    }
}
