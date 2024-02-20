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
    
    var dataStringList: [(String,String)]{
        var strList : [(String,String)] = []
        let routeData = (data as! [RouteData])
        for route in routeData{
            strList.append( ( "\(route.route),\(route.bound),\(route.service_type)" ,"\(route.route) - \(route.orig_tc)->\(route.dest_tc)") )
        }
        return strList
    }
}
