//
//  PDFPageSelection.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 11/9/24.
//
import Foundation

struct PDFPageSelection {
    var selectedPages: Set<Int> = []
    var selectionMode: SelectionMode = .individual
    var rangeStart: Int?
    var rangeEnd: Int?
    
    enum SelectionMode {
        case individual
        case range
    }
}
