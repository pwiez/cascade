//
//  Telemetry.swift
//  Kessler
//
//  Created by Pedro Wiezel on 13/02/26.
//

import Foundation
import Combine

class Telemetry: ObservableObject {
    @Published var stats = SimStats()
}
