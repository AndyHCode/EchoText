//
//  RangeSlider.swift
//  SherpaOnnxTts
//
//  Created by Nosh Given on 11/27/24.
//

import SwiftUI


struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    var bounds: ClosedRange<Double>
    var step: Double
    
    var body: some View {
        VStack {
            Slider(value: Binding(
                get: { range.lowerBound },
                set: { newValue in
                    range = newValue...max(newValue, range.upperBound)
                }
            ), in: bounds.lowerBound...bounds.upperBound, step: step)
            Slider(value: Binding(
                get: { range.upperBound },
                set: { newValue in
                    range = min(newValue, range.lowerBound)...newValue
                }
            ), in: bounds.lowerBound...bounds.upperBound, step: step)
        }
    }
}
