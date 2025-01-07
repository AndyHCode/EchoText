//
//  FilterSortView.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/27/24.
//


import SwiftUI
import Foundation


struct FilterSortView: View {
    @Binding var sortCriterion: SortCriterion
    @ObservedObject var filterCriteria: FilterCriteria
    var audios: [AudioRecord]
    @Environment(\.presentationMode) var presentationMode
    
    
    // State for collapsible sections
    @State private var showSpeedSlider: Bool = false
    @State private var showPitchSlider: Bool = false
    @State private var showLengthSlider: Bool = false
    
    // For date pickers
    @State private var selectedStartDate: Date = Date()
    @State private var selectedEndDate: Date = Date()
    @State private var isDateRangeEnabled: Bool = false
    
    
    
    var availableModels: [String] {
        let models = Set(audios.map { $0.model })
        return Array(models).sorted()
    }
    
    
    
    
    var body: some View {
        NavigationView {
            Form {
                // Sorting Section
                
                Picker("Sort By", selection: $sortCriterion) {
                    ForEach(SortCriterion.allCases) { criterion in
                        Text(criterion.rawValue).tag(criterion)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                
                // Filtering Section
                Section(header: Text("Filter By")) {
                    // Collapsible Speed Range
                    collapsibleFilter(title: "Speed", iconName: "speedometer", isExpanded: $showSpeedSlider) {
                        speedSlider
                    }
                    
                    // Collapsible Pitch Range
                    collapsibleFilter(title: "Pitch", iconName: "waveform", isExpanded: $showPitchSlider) {
                        pitchSlider
                    }
                    
                    // Collapsible Length Range
                    collapsibleFilter(title: "Length", iconName: "clock", isExpanded: $showLengthSlider) {
                        lengthSlider
                    }
                    
                    
                    // Favorites Only
                    Toggle("Favorites Only", isOn: $filterCriteria.favoritesOnly)
                    
                    // Linked Documents Only
                    Toggle("Linked Documents Only", isOn: $filterCriteria.linkedDocumentsOnly)
                    
                    
                    // Date Range Filter
                    Toggle("Filter by Date Range", isOn: $isDateRangeEnabled)
                        .onChange(of: isDateRangeEnabled) { newValue in
                            if newValue {
                                // Ensure dates are valid
                                if selectedStartDate > selectedEndDate {
                                    selectedEndDate = selectedStartDate
                                }
                                filterCriteria.dateRange = selectedStartDate...selectedEndDate
                            } else {
                                filterCriteria.dateRange = nil
                            }
                        }
                    
                    if isDateRangeEnabled {
                        let today = Date()
                        
                        // Start Date Picker
                        DatePicker("Start Date", selection: $selectedStartDate, in: ...min(selectedEndDate, today), displayedComponents: .date)
                            .onChange(of: selectedStartDate) { newStartDate in
                                if newStartDate > selectedEndDate {
                                    selectedEndDate = newStartDate
                                }
                                filterCriteria.dateRange = selectedStartDate...selectedEndDate
                            }
                        
                        // End Date Picker
                        DatePicker("End Date", selection: $selectedEndDate, in: max(selectedStartDate, Date.distantPast)...today, displayedComponents: .date)
                            .onChange(of: selectedEndDate) { newEndDate in
                                if newEndDate < selectedStartDate {
                                    selectedStartDate = newEndDate
                                }
                                filterCriteria.dateRange = selectedStartDate...selectedEndDate
                            }
                    }
                }
                
                
                // Voice Model (Placeholder)
                Picker("Voice Model", selection: $filterCriteria.model) {
                    Text("All").tag(nil as String?)
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            
            .navigationBarTitle("Sort and Filter", displayMode: .inline)
            .navigationBarItems(leading: Button("Reset") {
                resetFilters()
            }, trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Speed Slider Content
    private var speedSlider: some View {
        VStack(alignment: .leading) {
            Text("Range: \(filterCriteria.speedRange.lowerBound, specifier: "%.1f") - \(filterCriteria.speedRange.upperBound, specifier: "%.1f")")
            RangeSliderView(
                selection: Binding(
                    get: { CGFloat(filterCriteria.speedRange.lowerBound)...CGFloat(filterCriteria.speedRange.upperBound) },
                    set: { filterCriteria.speedRange = Double($0.lowerBound)...Double($0.upperBound) }
                ),
                range: 0.5...1.5
            )
        }
    }
    
    // Pitch Slider Content
    private var pitchSlider: some View {
        VStack(alignment: .leading) {
            Text("Range: \(filterCriteria.pitchRange.lowerBound, specifier: "%.1f") - \(filterCriteria.pitchRange.upperBound, specifier: "%.1f")")
            RangeSliderView(
                selection: Binding(
                    get: { CGFloat(filterCriteria.pitchRange.lowerBound)...CGFloat(filterCriteria.pitchRange.upperBound) },
                    set: { filterCriteria.pitchRange = Double($0.lowerBound)...Double($0.upperBound) }
                ),
                range: 0.1...2.0
            )
        }
    }
    
    // Length Slider Content
    private var lengthSlider: some View {
        VStack(alignment: .leading) {
            Text("Range: \(lowerBoundTime) - \(upperBoundTime)")
            RangeSliderView(
                selection: Binding(
                    get: { CGFloat(filterCriteria.lengthRange.lowerBound)...CGFloat(filterCriteria.lengthRange.upperBound) },
                    set: { filterCriteria.lengthRange = Double($0.lowerBound)...Double($0.upperBound) }
                ),
                range: CGFloat(0)...CGFloat(maximumAudioLength())
            )
        }
    }
    
    private func collapsibleFilter<Content: View>(
        title: String,
        iconName: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
                // Add spacing between title and slider content
                .padding(.top)
        } label: {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
        }
    }
    
    
    func resetFilters() {
        filterCriteria.speedRange = 0.5...1.5
        filterCriteria.pitchRange = 0.1...2.0
        filterCriteria.lengthRange = 0.0...maximumAudioLength()
        filterCriteria.dateRange = nil
        filterCriteria.favoritesOnly = false
        filterCriteria.linkedDocumentsOnly = false
        filterCriteria.model = nil
        sortCriterion = .dateDescending
        showSpeedSlider = false
        showPitchSlider = false
        showLengthSlider = false
        isDateRangeEnabled = false
        selectedStartDate = Date()
        selectedEndDate = Date()
    }
    
    
    // Helper Methods
    var lowerBoundTime: String {
        Int(filterCriteria.lengthRange.lowerBound).formattedTime()
    }
    
    var upperBoundTime: String {
        filterCriteria.lengthRange.upperBound.isFinite ?
        Int(filterCriteria.lengthRange.upperBound).formattedTime() : "Max"
    }
    
    func maximumAudioLength() -> Double {
        let maxLength = audios.map { Double($0.length) }.max() ?? 1000.0
        return min(maxLength, Double(Int.max))
    }
    
    
}
