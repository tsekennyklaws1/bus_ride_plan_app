//
//  BusRouteStopData.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 3/2/2024.
//

import Foundation
struct BusRouteStopData: BusData , Codable{
    func toStr() -> String {
        return "Version:\(version),Last Modified:\(generated_timestamp)"
    }
    
    let type: String
    let version: String
    let generated_timestamp: String
    var data : [RouteStopData?] = []

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.version = try container.decode(String.self, forKey: .version)
        self.generated_timestamp = try container.decode(String.self, forKey: .generated_timestamp)
        
        do{
            let dataArray = try container.decodeIfPresent([RouteStopData].self, forKey: .data)
            self.data = dataArray!
        } catch{
            let dataDict = try container.decodeIfPresent(RouteStopData.self, forKey: .data)
            let dataDictList = [dataDict]
            self.data = dataDictList
        }
    }
}

struct RouteStopData: BusData , Codable{
    
    let co : String?
    let route : String
    let bound : String
    let service_type : String
    let seq : String
    let stop : String
    let data_timeStamp : String?

    func toStr() -> String {
        return "\(seq). \(route): \(bound=="O" ? "outbound" : "inbound)")  - \(stop)"
    }
}
