//
//  TouchOverlay.swift
//  LineChart
//
//  Created by Will Dale on 29/12/2020.
//

import SwiftUI

/**
 Finds the nearest data point and displays the relevent information.
 */
internal struct MouseOverlay<T>: ViewModifier where T: CTChartData {
    
    @ObservedObject private var chartData: T
    let minDistance: CGFloat
    @State private var mouseLocation: CGPoint = .zero
    
    internal init(
        chartData: T,
        specifier: String,
        formatter: NumberFormatter?,
        unit: TouchUnit,
        minDistance: CGFloat
    ) {
        self.chartData = chartData
        self.minDistance = minDistance
        self.chartData.infoView.touchSpecifier = specifier
        self.chartData.infoView.touchFormatter = formatter
        self.chartData.infoView.touchUnit = unit
    }
    
    internal func body(content: Content) -> some View {
        Group {
            if chartData.isGreaterThanTwo() {
                GeometryReader { geo in
                    ZStack {
                        content

                        if chartData.infoView.isTouchCurrent {
                            chartData.getTouchInteraction(touchLocation: chartData.infoView.touchLocation,
                                                          chartSize: geo.frame(in: .local))
                        }

                        MouseTrackerRepresentable(mouseLocation: $mouseLocation)
                            .onChange(of: mouseLocation) { newLocation in
                                chartData.setTouchInteraction(touchLocation: newLocation, chartSize: geo.frame(in: .local))
                            }
                            .onHover { hovering in
                                if !hovering {
                                    chartData.infoView.isTouchCurrent = false
                                    chartData.infoView.touchOverlayInfo = []
                                }
                            }
                    }
                }
            } else { content }
        }
    }
}

extension View {
    public func mouseOverlay<T: CTChartData>(
        chartData: T,
        specifier: String = "%.0f",
        formatter: NumberFormatter? = nil,
        unit: TouchUnit = .none,
        minDistance: CGFloat = 0
    ) -> some View {
        self.modifier(MouseOverlay(chartData: chartData,
                                   specifier: specifier,
                                   formatter: formatter,
                                   unit: unit,
                                   minDistance: minDistance))
    }
}


// A custom NSView subclass that tracks mouse movement
class MouseTrackerView: NSView {
    // A binding property that holds the mouse location
    var mouseLocation: Binding<CGPoint>
    
    // A designated initializer that takes a binding property as an argument
    init(mouseLocation: Binding<CGPoint>) {
        self.mouseLocation = mouseLocation
        super.init(frame: .zero)
        // Enable mouse tracking for this view
        self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: [.mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil))
    }
    
    // A required initializer for NSView subclasses
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // A method that overrides the default behavior when the mouse moves over this view
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        // Get the mouse location in this view's coordinate system
        let location = self.convert(event.locationInWindow, from: nil)
        // Update the binding property with the new location
        self.mouseLocation.wrappedValue = location
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Update the tracking area with the current bounds of the view
        if let trackingArea = self.trackingAreas.first {
            self.removeTrackingArea(trackingArea)
            self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: [.mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil))
        }
    }
}

// A struct that conforms to NSViewRepresentable and wraps MouseTrackerView
struct MouseTrackerRepresentable: NSViewRepresentable {
    // A binding property that holds the mouse location
    @Binding var mouseLocation: CGPoint
    
    // A method that creates an instance of MouseTrackerView with the given context
    func makeNSView(context: Context) -> MouseTrackerView {
        return MouseTrackerView(mouseLocation: $mouseLocation)
    }
    
    // A method that updates an existing instance of MouseTrackerView with the given context
    func updateNSView(_ nsView: MouseTrackerView, context: Context) {
        // You can update any properties of nsView here if needed
    }
}
