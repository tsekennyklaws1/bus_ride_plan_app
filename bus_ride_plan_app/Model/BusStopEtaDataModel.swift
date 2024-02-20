//
//  BusStopRouteDataModel.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 5/2/2024.
//

import Foundation
class BusStopEtaDataModel :BusDataModel {
    
    override init(){
        super.init()
    }
    override init(_ type: String, _ version: String, _ generated_timestamp: String) {
        super.init(type, version, generated_timestamp)
    }
    
    override func setData(_ data: [BusData?]){
        self.data = (data as! [StopEtaData?])
       // _ = self.data.map{self.dataDict.updateValue($0!, forKey: ($0! as! StopRouteData).route)}
    }
    
    var dataString: String {
        var str :String = ""
        for route in data {
            
            str = str + (route?.toStr() ?? "") + "\n"
        }
        return str
    }
    
    var dataStringList: [String]{
        var strList : [String] = []
        for dataElement in data {
            strList.append((dataElement?.toStr())!)
        }
        return strList
    }
}
