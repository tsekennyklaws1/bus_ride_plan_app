import Foundation

struct BusRouteData: BusData , Codable{
    func toStr() -> String {
        return "Version:\(version),Last Modified:\(generated_timestamp)"
    }
    
    let type: String
    let version: String
    let generated_timestamp: String
    var data : [RouteData?] = []
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.version = try container.decode(String.self, forKey: .version)
        self.generated_timestamp = try container.decode(String.self, forKey: .generated_timestamp)
        
        do{
            let dataArray = try container.decodeIfPresent([RouteData].self, forKey: .data)
            self.data = dataArray!
        } catch{
            let dataDict = try container.decodeIfPresent(RouteData.self, forKey: .data)
            let dataDictList = [dataDict]
            self.data = dataDictList
        }
    }
}

struct RouteData: BusData, Codable {
    let co : String?
    let route: String
    let bound: String
    let service_type: String
    let orig_en: String
    let orig_tc: String
    let orig_sc: String
    let dest_en : String
    let dest_tc : String
    let dest_sc : String
    let data_timeStamp : String?
    
    func toStr() -> String {
        return "\(route) - \(orig_tc)->\(dest_tc)"
    }
}

