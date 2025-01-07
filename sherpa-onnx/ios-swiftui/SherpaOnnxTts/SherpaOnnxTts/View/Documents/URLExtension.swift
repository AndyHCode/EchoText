//
//  URLExtension.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 10/8/24.
//
import Foundation

extension URL: Identifiable {
    public var id: String { self.absoluteString }
}
