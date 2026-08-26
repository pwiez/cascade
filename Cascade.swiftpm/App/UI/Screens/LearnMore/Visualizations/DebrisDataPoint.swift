//
//  DebrisDataPoint.swift
//  Cascade
//

struct DebrisDataPoint: Identifiable {
    var id: Int { year }

    let year: Int
    let count: Int
}

extension DebrisDataPoint {
    static let history: [DebrisDataPoint] = [
        .init(year: 1960, count: 200),
        .init(year: 1965, count: 1_200),
        .init(year: 1970, count: 2_000),
        .init(year: 1975, count: 3_800),
        .init(year: 1980, count: 4_800),
        .init(year: 1985, count: 6_000),
        .init(year: 1990, count: 7_100),
        .init(year: 1995, count: 8_200),
        .init(year: 2000, count: 8_900),
        .init(year: 2005, count: 9_500),
        .init(year: 2007, count: 12_500),
        .init(year: 2009, count: 15_000),
        .init(year: 2012, count: 16_500),
        .init(year: 2015, count: 17_500),
        .init(year: 2018, count: 19_000),
        .init(year: 2020, count: 21_500),
        .init(year: 2021, count: 24_000),
        .init(year: 2022, count: 27_500),
        .init(year: 2023, count: 34_000),
        .init(year: 2024, count: 39_500),
        .init(year: 2025, count: 42_500),
        .init(year: 2026, count: 45_000)
    ]

    static let milestones: [DebrisMilestone] = [
        .init(year: 2007, name: "Fengyun-1C", color: .orange, alignment: .trailing),
        .init(year: 2009, name: "Iridium-Cosmos", color: .red, alignment: .leading)
    ]
}
