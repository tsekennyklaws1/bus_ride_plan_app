import Foundation

class BusRouteDataModel :BusDataModel {

   
    override init(){
        super.init()
        
    }
    override init(_ type: String, _ version: String, _ generated_timestamp: String) {
        super.init(type, version, generated_timestamp)
    }
    
    override func setData(_ data: [BusData?]){
        self.data = (data as! [RouteData?])
        _ = self.data.map{self.dataDict.updateValue($0!, forKey: ($0! as! RouteData).route)}
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
        for route in data {
            strList.append((route?.toStr())!)
        }
        return strList
    }
}
