//
//  BusData.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 31/1/2024.
//

import Foundation
protocol BusData: Codable {
    func toStr() -> String
}

