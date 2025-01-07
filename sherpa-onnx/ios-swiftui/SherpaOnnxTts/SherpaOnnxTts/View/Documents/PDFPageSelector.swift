//
//  PDFPageSelector.swift
//  SherpaOnnxTts
//
//  Created by Andy Huang on 11/9/24.
//
import SwiftUI
import PDFKit

struct PDFPageSelector: View {
    let pdfDocument: PDFDocument
    @Binding var selection: PDFPageSelection
    let onGenerate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isExpanded: Bool = false
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    // Computed properties
    private var isValidSelection: Bool {
        if selection.selectionMode == .range {
            return selection.rangeStart != nil && selection.rangeEnd != nil
        } else {
            return !selection.selectedPages.isEmpty
        }
    }
    
    private var pageRangeText: String {
        if selection.selectionMode == .range {
            if let start = selection.rangeStart, let end = selection.rangeEnd {
                return "\(start + 1)-\(end + 1)"
            }
            return "Select Range"
        } else {
            if selection.selectedPages.isEmpty {
                return "Select Pages"
            }
            let count = selection.selectedPages.count
            return count == 1 ? "1 page" : "\(count) pages"
        }
    }
    
    private var selectedPagesDescription: String {
        if selection.selectionMode == .range {
            if let start = selection.rangeStart, let end = selection.rangeEnd {
                let count = end - start + 1
                return "\(count) pages (Pages \(start + 1)-\(end + 1))"
            }
            return "No pages selected"
        } else {
            let count = selection.selectedPages.count
            if count == 0 {
                return "No pages selected"
            } else if count == 1 {
                return "1 page"
            } else {
                return "\(count) pages"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Pages")
                        Spacer()
                        Text(pageRangeText)
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                    
                    if isExpanded {
                        Picker("Selection Mode", selection: $selection.selectionMode) {
                            Text("Range").tag(PDFPageSelection.SelectionMode.range)
                            Text("Individual").tag(PDFPageSelection.SelectionMode.individual)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 8)
                        
                        if selection.selectionMode == .range {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("From")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("", selection: $selection.rangeStart.animation()) {
                                        Text("--").tag(Optional<Int>.none)
                                        ForEach(0..<pdfDocument.pageCount, id: \.self) { page in
                                            Text("\(page + 1)").tag(Optional(page))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("To")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("", selection: $selection.rangeEnd.animation()) {
                                        Text("--").tag(Optional<Int>.none)
                                        ForEach(0..<pdfDocument.pageCount, id: \.self) { page in
                                            if let start = selection.rangeStart, page >= start {
                                                Text("\(page + 1)").tag(Optional(page))
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .disabled(selection.rangeStart == nil)
                                }
                            }
                            .padding(.top, 4)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 8) {
                                    ForEach(0..<pdfDocument.pageCount, id: \.self) { pageIndex in
                                        PageSelectionCard(
                                            pageNumber: pageIndex + 1,
                                            isSelected: selection.selectedPages.contains(pageIndex),
                                            onTap: {
                                                if selection.selectedPages.contains(pageIndex) {
                                                    selection.selectedPages.remove(pageIndex)
                                                } else {
                                                    selection.selectedPages.insert(pageIndex)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .frame(height: 280)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Document")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(pdfDocument.pageCount) Pages")
                    }
                    
                    if !selection.selectedPages.isEmpty || (selection.rangeStart != nil && selection.rangeEnd != nil) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Selected")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(selectedPagesDescription)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        if selection.selectionMode == .range,
                           let start = selection.rangeStart,
                           let end = selection.rangeEnd {
                            selection.selectedPages = Set(start...end)
                        }
                        onGenerate()
                        dismiss()
                    }
                    .disabled(!isValidSelection)
                }
            }
        }
    }
}

struct PageSelectionCard: View {
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                        .frame(height: 60)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    } else {
                        Text("\(pageNumber)")
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
