//
//  DebrisChart.swift
//  Cascade
//
//  Created by Pedro Wiezel on 19/02/26.
//

import SwiftUI
import Charts

struct DebrisDataPoint: Identifiable {
    let id = UUID()
    let year: Int
    let count: Int
    let annotation: String?
}

struct DebrisChart: View {
    let data: [DebrisDataPoint] = [
        .init(year: 1960, count: 200, annotation: nil),
        .init(year: 1965, count: 1200, annotation: nil),
        .init(year: 1970, count: 2000, annotation: nil),
        .init(year: 1975, count: 3800, annotation: nil),
        .init(year: 1980, count: 4800, annotation: nil),
        .init(year: 1985, count: 6000, annotation: nil),
        .init(year: 1990, count: 7100, annotation: nil),
        .init(year: 1995, count: 8200, annotation: nil),
        .init(year: 2000, count: 8900, annotation: nil),
        .init(year: 2005, count: 9500, annotation: nil),
        .init(year: 2007, count: 12500, annotation: "Fengyun-1C ASAT"),
        .init(year: 2009, count: 15000, annotation: "Iridium-Cosmos"),
        .init(year: 2012, count: 16500, annotation: nil),
        .init(year: 2015, count: 17500, annotation: nil),
        .init(year: 2018, count: 19000, annotation: nil),
        .init(year: 2020, count: 21500, annotation: nil),
        .init(year: 2021, count: 24000, annotation: "Cosmos 1408 ASAT"),
        .init(year: 2022, count: 27500, annotation: nil),
        .init(year: 2023, count: 34000, annotation: nil),
        .init(year: 2024, count: 39500, annotation: nil),
        .init(year: 2025, count: 42500, annotation: nil),
        .init(year: 2026, count: 45000, annotation: "Current")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Evolution of cataloged objects in Earth orbit")
                    .font(.headline).foregroundStyle(.primary)
                Text("Objects larger than 10 cm tracked by space surveillance networks, 1960–2026.")
                    .font(.caption).foregroundStyle(DesignTokens.mutedText)
                    .lineSpacing(3)
            }
            .padding(.bottom, 32)
            
            Chart {
                ForEach(data) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.30), Color.blue.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(Color.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
                
                
                RuleMark(x: .value("Event", 2007))
                    .foregroundStyle(.orange.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Fengyun-1C")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(DesignTokens.iconBackgroundOpacity))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                
                RuleMark(x: .value("Event", 2009))
                    .foregroundStyle(.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Iridium-Cosmos")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(DesignTokens.iconBackgroundOpacity))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
            }
            .chartXScale(domain: 1960...2026)
            .chartYScale(domain: 0...36000)
            .chartXAxis {
                AxisMarks(values: stride(from: 1960, through: 2026, by: 10).map { $0 }) { value in
                    AxisGridLine().foregroundStyle(DesignTokens.cardBorder)
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text("'\(intVal % 100, specifier: "%02d")")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(DesignTokens.dimText)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: stride(from: 0, through: 46000, by: 5000).map { $0 }) { value in
                    AxisGridLine().foregroundStyle(DesignTokens.cardBorder)
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(intValue >= 1000 ? "\(intValue / 1000)k" : "\(intValue)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(DesignTokens.dimText)
                        }
                    }
                }
            }
            .frame(height: 300)
            .accessibilityLabel("Line chart showing growth of tracked orbital objects from a few hundred in 1960 to over 45,000 in 2026, with sharp increases after the 2007 Fengyun-1C test and 2009 Iridium-Cosmos collision.")
        }
    }
}
