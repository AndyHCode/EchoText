//
//  ModelRow.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/28/24.
//

import SwiftUI

struct ModelRow: View {
    @ObservedObject var modelItem: ModelItem
    var performRenameModel: (ModelItem) -> Void
    var deleteModel: (ModelItem) -> Void
    
    var body: some View {
        HStack {
            ZStack {
                TextField("Model Name", text: $modelItem.name, onCommit: {
                    performRenameModel(modelItem)
                })
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.leading)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }
            .contentShape(Rectangle())
            
            Spacer()
            
            Button(action: {
                print("pressed")
                deleteModel(modelItem)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing)
        }
        .padding(.vertical, 10)
    }
}

