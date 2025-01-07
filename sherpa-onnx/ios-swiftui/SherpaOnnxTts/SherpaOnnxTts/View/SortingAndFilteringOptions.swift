//
//  SortingAndFilteringOptions.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/27/24.
//

import Foundation


enum SortCriterion: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case dateDescending = "Date (Newest First)"
    case dateAscending = "Date (Oldest First)"
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case durationAscending = "Duration (Shortest First)"
    case durationDescending = "Duration (Longest First)"
}


class FilterCriteria: ObservableObject {
    @Published var speedRange: ClosedRange<Double> = 0.5...1.5
    @Published var pitchRange: ClosedRange<Double> = 0.1...2.0
    @Published var lengthRange: ClosedRange<Double> = 0.0...Double.infinity
    @Published var dateRange: ClosedRange<Date>? = nil
    @Published var favoritesOnly: Bool = false
    @Published var linkedDocumentsOnly: Bool = false
    @Published var model: String? = nil
}
