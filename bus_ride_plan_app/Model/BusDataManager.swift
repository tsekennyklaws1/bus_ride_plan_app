import Foundation
import UIKit
import CoreLocation
import CoreData

protocol BusManagerDelegate {
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel)
    func didFailWithError(error: Error)
}

class BusDataManager {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var currentLocation : (lat : CLLocationDegrees, lon : CLLocationDegrees)?
    
    let busRouteURL = "https://data.etabus.gov.hk/v1/transport/kmb"
    var busRouteDataList = [(String, String)]()// "route,bound,service_type": "toStr"

    var bustStopsName : Dictionary <String, String> = Dictionary()
    var nearestBusStop = [(String,String)]()

    var busRouteStopList : [String] = []
    var routeStopDict : Dictionary <String, [(String,String)]> = Dictionary()

    var busStopEtaList = [(routeStr: String, cellStr: String)]()
    var stopEtaDict : Dictionary <String, [String]> = Dictionary()
    
    var busEtaDetailList = [String]()
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
                if (busDataModel_init is BusRouteDataModel){
                    let decodedData = try decoder.decode(BusRouteData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusRouteDataModel).setData(data)
                } else if (busDataModel_init is BusStopDataModel){
                    let decodedData = try decoder.decode(BusStopData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusStopDataModel).setData(data)
                } else if (busDataModel_init is BusRouteStopDataModel){
                    let decodedData = try decoder.decode(BusRouteStopData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusRouteStopDataModel).setData(data)
                } else if (busDataModel_init is BusStopEtaDataModel){
                    let decodedData = try decoder.decode(BusStopEtaData.self, from: busData)
                    let version = decodedData.version
                    let type = decodedData.type
                    let generated_timestamp = decodedData.generated_timestamp
                    let data = decodedData.data
                    busDataModel_init.setVersion_Timestamp(type,version,generated_timestamp)
                    (busDataModel_init as! BusStopEtaDataModel).setData(data)
                } else if (busDataModel_init is BusEtaDetailDataModel){
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
        }/*
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
        }*/
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

    func loadBusDataFromDB()-> Bool{
        var busRouteLoaded : Bool = false
        var busStopLoaded : Bool = false
        do {
            let request = NSFetchRequest<Route>(entityName: "Route")
            let itemArray = try context.fetch(request)
            self.busRouteDataList = itemArray.map{(String("\($0.route),\($0.bound == "O" ? "outbound" : "inbound"),\($0.service_type)"),$0.toStr!)}
            busRouteLoaded = true
        } catch {
            print("Error fetching Routedata from context \(error)")
        }
        do{
            let request = NSFetchRequest<Stop>(entityName: "Stop")
            let itemArray = try context.fetch(request)
            itemArray.forEach{self.bustStopsName.updateValue($0.name_tc!, forKey: $0.stop!)}
            busStopLoaded = true
       } catch {
           print("Error fetching Stopdata from context \(error)")
       }
        return busRouteLoaded && busStopLoaded
    }
    
    
    func saveBusDataToDB(path : URL, dataToBeSave : [BusData]){
       
        switch path {
        case localRouteDataPath:
            var dataToBeInsert = [Route]()
            (dataToBeSave as! [RouteData]).forEach {
                let dataItem = Route(context: self.context)
                print("try to insert: \($0.toStr())")
                dataItem.route = $0.route
                dataItem.bound = $0.bound
                dataItem.dest_en = $0.dest_en
                dataItem.dest_tc = $0.dest_tc
                dataItem.dest_sc = $0.dest_sc
                dataItem.orig_en = $0.orig_en
                dataItem.orig_tc = $0.orig_tc
                dataItem.orig_sc = $0.orig_sc
                dataItem.co = $0.co
                dataItem.service_type = $0.service_type
                dataItem.toStr = $0.toStr()
                dataToBeInsert.append(dataItem)
            }
            saveToDB()
        case localStopDataPath:
            
            var dataToBeInsert = [Stop]()
            (dataToBeSave as! [StopData]).forEach {
                let dataItem = Stop(context: self.context)
                print("try to insert: \($0.toStr())")
                dataItem.stop = $0.stop
                dataItem.name_en = $0.name_en
                dataItem.name_tc = $0.name_tc
                dataItem.name_sc = $0.name_sc
                dataItem.lat = Double($0.lat) ?? 0.0
                dataItem.long = Double($0.long) ?? 0.0
                dataItem.toStr = $0.toStr()
                dataToBeInsert.append(dataItem)
            }
            saveToDB()
                
           // case localRouteStopDataPath:
           //     let data = try encoder.encode(dataToBeSave as! [RouteStopData])
           //     try data.write(to: localRouteStopDataPath!)
        default:
            print("No data saved")
        }
    }
    
    func saveToDB() {
        do {
            try context.save()
        } catch {
            print("Error during saving  \(error)")
        }
    }
    
    func setLocation(lat : CLLocationDegrees, lon : CLLocationDegrees) {
        self.currentLocation = (lat,lon)
    }
    func searchNearestBusStop() {
        let request : NSFetchRequest<Stop> = Stop.fetchRequest()
        let lat = currentLocation?.lat
        let lon = currentLocation?.lon
        if ((lat != nil) && (lon != nil)){
            let predicate_lat = NSPredicate(format: "lat > %@ AND lat < %@", argumentArray: [ lat!.magnitude-0.002,lat!.magnitude+0.002])
            let predicate_lon = NSPredicate(format: "long > %@ AND long < %@", argumentArray: [lon!.magnitude-0.002,lon!.magnitude+0.002])
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate_lat,predicate_lon])
            request.sortDescriptors = [NSSortDescriptor(key: "lat", ascending: true)]
            request.predicate = compoundPredicate
            do {
                let stopDBArray = try context.fetch(request)
                self.nearestBusStop = stopDBArray.map{( (String($0.stop!)),(String($0.name_tc!)) )}
                
            } catch {
                print("Error fetching data from context \(error)")
            }
        }
    }
}

