//
//  BusStopRouteEtaData.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 6/2/2024.
//

import Foundation
struct BusEtaDetailData: BusData, Codable{
func toStr() -> String {
    return "Version:\(version),Last Modified:\(generated_timestamp)"
}

let type: String
let version: String
let generated_timestamp: String
var data : [EtaDetailData?] = []

init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.type = try container.decode(String.self, forKey: .type)
    self.version = try container.decode(String.self, forKey: .version)
    self.generated_timestamp = try container.decode(String.self, forKey: .generated_timestamp)
    
    do{
        let dataArray = try container.decodeIfPresent([EtaDetailData].self, forKey: .data)
        self.data = dataArray!
    } catch{
        let dataDict = try container.decodeIfPresent(EtaDetailData.self, forKey: .data)
        let dataDictList = [dataDict]
        self.data = dataDictList
    }
}
}

struct EtaDetailData: BusData , Codable{
    
    let co : String?
    let route : String
    let dir : String
    let service_type : Int
    let seq : Int
    let stop : String?
    let dest_en : String
    let dest_tc : String
    let dest_sc : String
    let eta_seq : Int?
    let eta : String?
    let rmk_en : String?
    let rmk_tc : String?
    let rmk_sc : String?
    let data_timeStamp : String?
    
    func toStr() -> String {
        
        var eta_rmk_str = ""
        if eta != nil{
            let etaTime = Calendar.current.dateComponents([.hour, .minute, .second], from:Date() ,to:ISO8601DateFormatter().date(from: eta!)! )
            eta_rmk_str = "\n\t\(etaTime.hour!) hr \(etaTime.minute!) min \(etaTime.second!) sec"
        }
        if rmk_tc != "" {
            eta_rmk_str += " - \(rmk_tc!)"
        }
        return "\(route): \(dir=="O" ? "從" : "到") \(dest_tc) \(dir=="O" ? "出發" : "總站")  \(eta_rmk_str)"
    }
}
