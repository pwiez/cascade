//
//  DebrisChart.swift
//  Cascade
//
//  Created by Pedro Wiezel on 19/02/26.
//

import Charts
import SwiftUI

/// Growth of catalogued orbital objects since 1960, with the two events that
/// most visibly bent the curve marked.
struct DebrisChart: View {
    private let yearRange = 1960...2026
    private let countRange = 0...48_000

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Evolution of cataloged objects in Earth orbit")
                    .font(.headline)
                Text("Objects larger than 10 cm tracked by space surveillance networks, 1960–2026.")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.mutedText)
                    .lineSpacing(3)
            }
            .padding(.bottom, 32)

            chart
                .frame(height: 300)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Line chart showing growth of tracked orbital objects from a few hundred in 1960 to over 45,000 in 2026, with sharp increases after the 2007 Fengyun-1C test and the 2009 Iridium-Cosmos collision.")
        }
    }

    private var chart: some View {
        Chart {
            ForEach(DebrisDataPoint.history) { point in
                AreaMark(x: .value("Year", point.year), y: .value("Count", point.count))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignTokens.signal.opacity(0.28), DesignTokens.signal.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Year", point.year), y: .value("Count", point.count))
                    .foregroundStyle(DesignTokens.signal)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
            }

            ForEach(DebrisDataPoint.milestones) { milestone in
                RuleMark(x: .value("Event", milestone.year))
                    .foregroundStyle(milestone.color.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: milestone.alignment) {
                        Text(milestone.name)
                            .font(.caption.bold())
                            .foregroundStyle(milestone.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                milestone.color.opacity(DesignTokens.iconBackgroundOpacity),
                                in: .rect(cornerRadius: 6)
                            )
                    }
            }
        }
        .chartXScale(domain: yearRange)
        .chartYScale(domain: countRange)
        .chartXAxis {
            AxisMarks(values: Array(stride(from: yearRange.lowerBound, through: yearRange.upperBound, by: 10))) { value in
                AxisGridLine().foregroundStyle(DesignTokens.hairline)
                AxisValueLabel {
                    if let year = value.as(Int.self) {
                        // Two-digit years: "'60", "'70". Padded through a format
                        // style rather than a printf specifier.
                        Text("'" + (year % 100).formatted(.number.precision(.integerLength(2))))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(DesignTokens.dimText)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: Array(stride(from: countRange.lowerBound, through: countRange.upperBound, by: 8_000))) { value in
                AxisGridLine().foregroundStyle(DesignTokens.hairline)
                AxisValueLabel {
                    if let count = value.as(Int.self) {
                        Text(count >= 1_000 ? "\(count / 1_000)k" : "\(count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(DesignTokens.dimText)
                    }
                }
            }
        }
    }
}
