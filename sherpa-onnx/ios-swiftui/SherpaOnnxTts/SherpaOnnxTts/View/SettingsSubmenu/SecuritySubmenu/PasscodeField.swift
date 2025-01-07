//
//  PasscodeField.swift
//  SherpaOnnxTts
//
//  Created by kevin Xing on 11/6/24.
//

import SwiftUI

struct PasscodeField: View {
    @Binding var text: String
    var placeholder: String = "Enter Passcode"
    @State private var isSecure: Bool = true
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .onReceive(text.publisher.collect()) {
                        self.text = String($0.prefix(6))
                    }
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .onReceive(text.publisher.collect()) {
                        self.text = String($0.prefix(6))
                    }
            }
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: self.isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
    }
}
