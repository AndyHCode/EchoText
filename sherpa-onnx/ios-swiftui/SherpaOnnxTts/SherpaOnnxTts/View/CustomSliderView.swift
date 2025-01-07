import SwiftUI

struct CustomSliderView: View {
    // Represents playback progress (0.0 to 1.0)
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    // Callback for value changes
    var onValueChanged: ((Double) -> Void)? = nil
    
    // State to track if the thumb is being dragged
    @State private var isDragging: Bool = false
    
    // Geometry properties
    let sliderHeight: CGFloat = 4
    let thumbSize: CGFloat = 12
    let thumbExpandedSize: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width - thumbSize
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: sliderHeight)
                
                // Filled Track with Gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * sliderWidth, height: sliderHeight)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? thumbExpandedSize : thumbSize,
                           height: isDragging ? thumbExpandedSize : thumbSize)
                    .shadow(radius: isDragging ? 4 : 2)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * sliderWidth - (thumbSize / 2))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { valueDrag in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDragging = true
                                }
                                // Calculate the new value based on drag location
                                let location = valueDrag.location.x
                                let newValue = min(max(Double(location / sliderWidth) * (range.upperBound - range.lowerBound) + range.lowerBound, range.lowerBound), range.upperBound)
                                self.value = newValue
                                // Notify parent view
                                onValueChanged?(newValue)
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isDragging = false
                                }
                            }
                    )
            }
            .frame(height: thumbExpandedSize)
        }
        .frame(height: thumbExpandedSize)
    }
}


