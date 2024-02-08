//
//  BusDataModel.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 31/1/2024.
//

import Foundation

class BusDataModel {
    var type: String?
    var version: String?
    var generated_timestamp: String?
    var data : [BusData?] = []
     var dataDict : Dictionary <String, BusData> = Dictionary()
    
    init(){
        
    }
    
    init(_ type:String, _ version:String, _ generated_timestamp:String) {
        self.type = type
        self.version = version
        self.generated_timestamp = generated_timestamp
    }
    
    func setData(_ data: [BusData?]){
        self.data = data
    }

    func setVersion_Timestamp(_ type:String, _ version:String, _ generated_timestamp:String) {
        self.type = type
        self.version = version
        self.generated_timestamp = generated_timestamp
    }
    
    var versionString: String {
        return String("version:\(version),type:\(type),generated_timestamp:\(generated_timestamp)")
    }
}
