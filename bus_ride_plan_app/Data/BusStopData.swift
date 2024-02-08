//
//  BusStopData.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 31/1/2024.
//

import Foundation
struct BusStopData: BusData , Codable{
    func toStr() -> String {
        return "Version:\(version),Last Modified:\(generated_timestamp)"
    }
    
    let type: String
    let version: String
    let generated_timestamp: String
    var data : [StopData?] = []

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.version = try container.decode(String.self, forKey: .version)
        self.generated_timestamp = try container.decode(String.self, forKey: .generated_timestamp)
        
        do{
            let dataArray = try container.decodeIfPresent([StopData].self, forKey: .data)
            self.data = dataArray!
        } catch{
            let dataDict = try container.decodeIfPresent(StopData.self, forKey: .data)
            let dataDictList = [dataDict]
            self.data = dataDictList
        }
    }
}

struct StopData: BusData , Codable{
    let stop : String
    let name_en: String
    let name_tc: String
    let name_sc: String
    let lat : String
    let long : String
    let data_timeStamp : String?

    func toStr() -> String {
        return name_tc
    }
    
    func toBusStop() -> (String,String){
        return (stop,name_tc)
    }
}
