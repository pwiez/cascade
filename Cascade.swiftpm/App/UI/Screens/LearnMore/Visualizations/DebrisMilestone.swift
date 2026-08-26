//
//  DebrisMilestone.swift
//  Cascade
//
//  Created by Pedro Wiezel on 26/08/26.
//

import SwiftUI

struct DebrisMilestone: Identifiable {
    var id: Int { year }

    let year: Int
    let name: String
    let color: Color

    let alignment: Alignment
}
