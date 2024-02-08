//
//  BusStopDataModel.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 31/1/2024.
//

import Foundation
class BusStopDataModel : BusDataModel {

   
    override init(){
        super.init()
    }
    
    override init(_ type: String, _ version: String, _ generated_timestamp: String) {
        super.init(type, version, generated_timestamp)
    }
    
    override func setData(_ data: [BusData?]){
        self.data = data as! [StopData?]
        data.forEach{
            self.dataDict.updateValue($0!, forKey: ($0! as! StopData).stop)
        }
    }
    
    var dataString: String {
        var str :String = ""
        for route in data {
            str += (route?.toStr() ?? "") + "\n"
        }
        return str
    }
    
    var dataStringList: [(String,String)]{
        var strList : [(String,String)] = []
        for stop in data {
            strList.append((stop as! StopData).toBusStop())
        }
        return strList
    }
    
    

}
