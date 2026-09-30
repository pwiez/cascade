//
//  ColorAssertions.swift
//  CascadeEngineTests
//

import Testing
import UIKit

@MainActor
func expectColor(_ color: UIColor, red: CGFloat, green: CGFloat, blue: CGFloat,
                 alpha: CGFloat = 1, sourceLocation: SourceLocation = #_sourceLocation) throws {
    // RealityKit can return an equivalent color in a different color space.
    let space = try #require(CGColorSpace(name: CGColorSpace.sRGB), sourceLocation: sourceLocation)
    let converted = try #require(
        color.cgColor.converted(to: space, intent: .defaultIntent, options: nil),
        sourceLocation: sourceLocation
    )
    let components = try #require(converted.components, sourceLocation: sourceLocation)
    try #require(components.count == 4, sourceLocation: sourceLocation)

    #expect(abs(components[0] - red) < 0.0001, "Unexpected red component", sourceLocation: sourceLocation)
    #expect(abs(components[1] - green) < 0.0001, "Unexpected green component", sourceLocation: sourceLocation)
    #expect(abs(components[2] - blue) < 0.0001, "Unexpected blue component", sourceLocation: sourceLocation)
    #expect(abs(components[3] - alpha) < 0.0001, "Unexpected alpha component", sourceLocation: sourceLocation)
}
