//
//  DebrisChart.swift
//  Cascade
//
//  Created by Pedro Wiezel on 18/02/26.
//

import SwiftUI
import Charts

struct DebrisChart: View {
    struct DebrisDataPoint: Identifiable {
        let id = UUID()
        let year: Int
        let count: Int
        let annotation: String?
    }
    
    let data: [DebrisDataPoint] = [
        .init(year: 1960, count: 200, annotation: nil),
        .init(year: 1965, count: 600, annotation: nil),
        .init(year: 1970, count: 1800, annotation: nil),
        .init(year: 1975, count: 3400, annotation: nil),
        .init(year: 1980, count: 5000, annotation: nil),
        .init(year: 1985, count: 6200, annotation: nil),
        .init(year: 1990, count: 7500, annotation: nil),
        .init(year: 1995, count: 8500, annotation: nil),
        .init(year: 2000, count: 9700, annotation: nil),
        .init(year: 2005, count: 10500, annotation: nil),
        .init(year: 2007, count: 13500, annotation: "Fengyun-1C ASAT"),
        .init(year: 2009, count: 16000, annotation: "Iridium-Cosmos"),
        .init(year: 2012, count: 17000, annotation: nil),
        .init(year: 2015, count: 18000, annotation: nil),
        .init(year: 2018, count: 20000, annotation: nil),
        .init(year: 2020, count: 23000, annotation: nil),
        .init(year: 2022, count: 27000, annotation: nil),
        .init(year: 2024, count: 32000, annotation: nil)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Cataloged Objects in Earth Orbit")
                    .font(.headline).foregroundStyle(.white)
                Text("Objects larger than 10 cm tracked by space surveillance networks, 1960–2024.")
                    .font(.caption).foregroundStyle(.gray)
                    .lineSpacing(3)
            }
            .padding(.bottom, 16)
            
            Chart {
                ForEach(data) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.25), Color.cyan.opacity(0.02)],
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
                            .background(.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
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
                            .background(.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
            }
            .chartXScale(domain: 1960...2026)
            .chartYScale(domain: 0...36000)
            .chartXAxis {
                AxisMarks(values: stride(from: 1960, through: 2024, by: 10).map { $0 }) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text("'\(intVal % 100, specifier: "%02d")")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: stride(from: 0, through: 35000, by: 5000).map { $0 }) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.06))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(intValue >= 1000 ? "\(intValue / 1000)k" : "\(intValue)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .frame(height: 260)
            .accessibilityLabel("Line chart showing growth of tracked orbital objects from about 200 in 1960 to over 32,000 in 2024, with sharp increases after the 2007 Fengyun-1C test and 2009 Iridium-Cosmos collision.")
        }
    }
}