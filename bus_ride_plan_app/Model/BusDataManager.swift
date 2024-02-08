import Foundation
import CoreLocation

protocol BusManagerDelegate {
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel)
    func didFailWithError(error: Error)
}

class BusDataManager {
    let busRouteURL = "https://data.etabus.gov.hk/v1/transport/kmb"
    var busRouteDataList :  [(String, String)] = []// "route,bound,service_type": "toStr"

    var bustStopsName : Dictionary <String, String> = Dictionary()

    var busRouteStopList : [String] = []
    var routeStopDict : Dictionary <String, [(String,String)]> = Dictionary()

    var busStopEtaList : [(routeStr: String, cellStr: String)] = []
    var stopEtaDict : Dictionary <String, [String]> = Dictionary()
    
    var busEtaDetailList : [String] = []
    var etaDetailDict : Dictionary <String, [String]> = Dictionary()
    
    var selectedRoute : (route: String, bound: String, service_type: String)?// = ("1A","O","1")
    var selectedStopCode : String = ""

    var delegate: BusManagerDelegate?
    let localRouteDataPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("busRouteData.plist")
    let localStopDataPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("busStopData.plist")
    let localRouteStopDataPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("busRouteStopData.plist")
    
    func setBusRouteDataList (_ busRouteDataList: [RouteData]){
        self.busRouteDataList = busRouteDataList.map{(String("\($0.route),\($0.bound == "O" ? "outbound" : "inbound"),\($0.service_type)"),$0.toStr())}
    }
    
    func setStopNameList (_ stopDataList: [StopData]){
        stopDataList.forEach{self.bustStopsName.updateValue($0.name_tc, forKey: $0.stop)}
    }
    
    func setAllRouteStopList (_ busAllRouteStopList: [RouteStopData]){
        self.busRouteStopList = busAllRouteStopList.map{ String("\($0.route)-\(self.getBusStopName(busCode: $0.stop))") }
    }
    
    func setStopEtaList(_ stopEtaList: [StopEtaData]){
        self.busStopEtaList = stopEtaList.map{($0.toRoute() ,$0.toStr())}
    }
    
    func setEtaDetailList(_ etaDetailList: [EtaDetailData]){
        self.busEtaDetailList = etaDetailList.map{$0.toStr()}
    }
    
    func setSelectedRoute(route :String, direction : String, serviceType: String){
        self.selectedRoute = (route, direction, serviceType)
    }
    
    func setSelectedStop(stop : String){
        self.selectedStopCode = stop
    }
    
    func getBusStopName(busCode : String) -> String{
        return String(self.bustStopsName[busCode] ?? "")
    }
    
    func fetchAllBusRoute() {
        let urlString = "\(busRouteURL)/route"
        performRequest(with: urlString, busDataModel_init: BusRouteDataModel())
    }
    
    func fetchBusRoute(route: String,direction: String, service_type: String){
        let urlString = "\(busRouteURL)/route/\(route)/\(direction == "O" ? "outbound" : "inbound")/\(service_type)"
        performRequest(with: urlString, busDataModel_init: BusRouteDataModel())
    }
    
    func fetchAllBusStop() {
        let urlString = "\(busRouteURL)/stop"
        performRequest(with: urlString, busDataModel_init: BusStopDataModel())
    }
    
    func fetchNearestBusStop(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let urlString = "\(busRouteURL)&lat=\(latitude)&lon=\(longitude)"
        performRequest(with: urlString, busDataModel_init: BusStopDataModel())
    }
    
    func fetchRouteStops(){
        let urlString = "\(busRouteURL)/route-stop"
        performRequest(with: urlString, busDataModel_init: BusRouteStopDataModel())
    }
    
    func fetchRouteStops(route: String,direction: String, service_type: String){
        let urlString = "\(busRouteURL)/route-stop/\(route)/\(direction)/\(service_type)"
        performRequest(with: urlString, busDataModel_init: BusRouteStopDataModel())
    }
    func fetchStopsRoute_eta(stopCode: String){
        let urlString = "\(busRouteURL)/stop-eta/\(stopCode)"
        performRequest(with: urlString, busDataModel_init: BusStopEtaDataModel())
    }
    func fetchStopsRoute_etaDetail(stopCode: String,route: String, service_type: String){
        let urlString = "\(busRouteURL)/eta/\(stopCode)/\(route)/\(service_type)"
        performRequest(with: urlString, busDataModel_init: BusEtaDetailDataModel())
    }
    
    func fetchSelectedRouteStops()
    {
        let urlString = "\(busRouteURL)/route-stop/\(selectedRoute!.route)/\(selectedRoute!.bound == "O" ? "outbound" : "inbound")/\(selectedRoute!.service_type)"
        performRequest(with: urlString, busDataModel_init: BusRouteStopDataModel())
    }
    
    func performRequest(with urlString: String, busDataModel_init: BusDataModel!) {
        print("urlString = \(urlString)")
        if let url = URL(string: urlString) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url)
            { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {
                    print("API triggerred successfully : url=\(url)\n \(safeData)")
                    if let dataModel = self.parseJSON(safeData, busDataModel_init){
                        if ((dataModel as? BusRouteDataModel) != nil) {
                            self.delegate?.didUpdateBusData(self, busData: dataModel as! BusRouteDataModel)
                        } else if ((dataModel as? BusStopDataModel) != nil) {
                            self.delegate?.didUpdateBusData(self, busData: dataModel as! BusStopDataModel)
                        } else if ((dataModel as? BusRouteStopDataModel) != nil) {
                            self.delegate?.didUpdateBusData(self, busData: dataModel as! BusRouteStopDataModel)
                        } else if ((dataModel as? BusStopEtaDataModel) != nil) {
                            self.delegate?.didUpdateBusData(self, busData: dataModel as! BusStopEtaDataModel)
                        } else if ((dataModel as? BusEtaDetailDataModel) != nil) {
                            self.delegate?.didUpdateBusData(self, busData: dataModel as! BusEtaDetailDataModel)
                        }
                    }
                }
            }
                task.resume()
        }
    }
    func parseJSON(_ busData: Data,_ busDataModel_init: BusDataModel) -> BusDataModel? {
        let decoder = JSONDecoder()
            do {
                if ((busDataModel_init as? BusRouteDataModel) != nil){
                    let decodedData = try decoder.decode(BusRouteData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusRouteDataModel).setData(data)
                } else if ((busDataModel_init as? BusStopDataModel) != nil){
                    let decodedData = try decoder.decode(BusStopData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusStopDataModel).setData(data)
                } else if ((busDataModel_init as? BusRouteStopDataModel) != nil){
                    let decodedData = try decoder.decode(BusRouteStopData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusRouteStopDataModel).setData(data)
                } else if ((busDataModel_init as? BusStopEtaDataModel) != nil){
                    let decodedData = try decoder.decode(BusStopEtaData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusStopEtaDataModel).setData(data)
                } else if ((busDataModel_init as? BusEtaDetailDataModel) != nil){
                    let decodedData = try decoder.decode(BusEtaDetailData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusEtaDetailDataModel).setData(data)
                }
            } catch {
                delegate?.didFailWithError(error: error)
                return nil
            }
        return busDataModel_init
    }
    
    func loadBusDataFromLocal()-> Bool{
        var busRouteLoaded : Bool = false
        var busStopLoaded : Bool = false
        if let data = try? Data(contentsOf: localRouteDataPath!){
            let decoder = PropertyListDecoder()
            do{
                let retrievedList = try decoder.decode([RouteData].self, from: data)
                self.busRouteDataList = retrievedList.map{(String("\($0.route),\($0.bound == "O" ? "outbound" : "inbound"),\($0.service_type)"),$0.toStr())}
                busRouteLoaded = true
            } catch {
                print("Error decoding BusRouteDataList, \(error)")
            }
        }
        if let data = try? Data(contentsOf: localStopDataPath!){
            let decoder = PropertyListDecoder()
            do{
                let retrievedList = try decoder.decode([StopData].self, from: data)
                 retrievedList.forEach{self.bustStopsName.updateValue($0.toStr(), forKey: $0.stop)}
                busStopLoaded = true
            } catch {
                print("Error decoding BusStopDataList, \(error)")
            }
        }
        if let data = try? Data(contentsOf: localRouteStopDataPath!){
            let decoder = PropertyListDecoder()
            do{
                let retrievedList = try decoder.decode([RouteStopData].self, from: data)
                self.busRouteStopList  = 
                retrievedList.map{(String(self.getBusStopName(busCode: $0.stop)))}
                let keysAndValues = retrievedList.map { ($0.route, [($0.stop, self.getBusStopName(busCode: $0.stop))]) }
                self.routeStopDict = Dictionary(keysAndValues, uniquingKeysWith: { $0 + $1 })
            } catch {
                print("Error decoding BusStopDataList, \(error)")
            }
        }
        return busRouteLoaded && busStopLoaded
    }
    
    func saveBusDataToLocal(path : URL, dataToBeSave : [BusData]){
        let encoder = PropertyListEncoder()
        do{
            switch path {
            case localRouteDataPath:
                let data = try encoder.encode(dataToBeSave as! [RouteData])
                try data.write(to: localRouteDataPath!)
            case localStopDataPath:
                let data = try encoder.encode(dataToBeSave as! [StopData])
                try data.write(to: localStopDataPath!)
            case localRouteStopDataPath:
                let data = try encoder.encode(dataToBeSave as! [RouteStopData])
                try data.write(to: localRouteStopDataPath!)
            default:
                print("No data saved")
            }
            
        }
        catch{
            print("Error encoding item array, \(error)")
        }
    }
}

