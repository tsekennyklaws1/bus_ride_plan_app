//
//  ViewController.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 3/2/2024.
//

import UIKit
import CoreLocation
import CLTypingLabel
import GoogleMaps
import CoreData

class LandingPageViewController: UIViewController, BusManagerDelegate {
    @IBOutlet weak var Welcome_title: CLTypingLabel!
    @IBOutlet weak var locationLabel: UILabel!
    let locationManager = CLLocationManager()
    var busDataManager = BusDataManager()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var stopList = [StopData]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.busDataManager.delegate = self
        locationManager.delegate = self
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.isHidden = false
        
        self.navigationController?.navigationBar.barTintColor = UIColor(named: "Indigo")
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        self.Welcome_title.text = "歡迎來到九巴遊車河App"
        
        // Do any additional setup after loading the view
        //if !busDataManager.loadBusDataFromLocal() {
        if !busDataManager.loadBusDataFromDB() {
            DispatchQueue.main.async {
                self.busDataManager.fetchAllBusStop()
            }
        }
        
    }

    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        
        if let busRouteData = (busData as? BusRouteDataModel) {
            if busRouteData.data.count > 1 {
                self.busDataManager.setBusRouteDataList(busRouteData.data as! [RouteData])
                //self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localRouteDataPath!,dataToBeSave: busRouteData.data as! [RouteData])
                self.busDataManager.saveBusDataToDB(path: self.busDataManager.localRouteDataPath!,dataToBeSave: busRouteData.data as! [RouteData])
            }
        } else if let busStopData = (busData as? BusStopDataModel) {
            if busStopData.data.count > 1 {
                let stopData = busStopData.data as! [StopData]
                self.busDataManager.setStopNameList(stopData)
                //self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
                self.busDataManager.saveBusDataToDB(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
                /*
                var stopDataToBeSaved = [Stop]()
                stopData.forEach {
                    let stopDataItem = Stop(context: self.context)
                    print("try to insert: \($0.toStr())")
                    stopDataItem.busStop = $0.stop
                    stopDataItem.name_en = $0.name_en
                    stopDataItem.name_tc = $0.name_tc
                    stopDataItem.name_sc = $0.name_sc
                    stopDataItem.stopLat = $0.lat
                    stopDataItem.stopLong = $0.long
                    //stopDataToBeSaved.data_timeStamp = $0.data_timeStamp
                    stopDataToBeSaved.append(stopDataItem)
                    
                }
                self.saveToDB()
                
                loadFromDB()
                */
            }
        }
    }
    
    func didFailWithError(error: Error) {
        print("HomeViewController throws error \(error)")
    }

    
    
    @IBAction func didRouteButtonClickl(_ sender: UIButton) {
        performSegue(withIdentifier: "goToBusRoute", sender: self)
    }
    @IBAction func didStopButtonClick(_ sender: UIButton) {
        performSegue(withIdentifier: "goToBusStops", sender: self)
    }
    
    @IBAction func getGPSCLick(_ sender: Any) {
        locationManager.requestLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "goToBusRoute"{
            let destinationVC = segue.destination as! BusRouteViewController
            destinationVC.busDataManager = self.busDataManager
        } else
        if segue.identifier == "goToBusStops"{
            let destinationVC = segue.destination as! BusStopViewController
            destinationVC.busDataManager = self.busDataManager
        }
    }

}
//MARK:CLLocationManager
extension LandingPageViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let location = locations.last{
            locationManager.stopUpdatingLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            locationLabel.text = "Location data:\n(\(lat),\(lon))"
            DispatchQueue.main.async {
                let geoCoder = GMSGeocoder()
                geoCoder.reverseGeocodeCoordinate((location.coordinate), completionHandler: 
                {
                reverseGeoCodeResponse, error in
                    print(reverseGeoCodeResponse?.results()!)
                })
            }
            /*
            let options = GMSMapViewOptions()
                options.camera = GMSCameraPosition.camera(withLatitude: lat, longitude: lon, zoom: 17.0)
                options.frame = self.view.bounds

            let mapView = GMSMapView(options: options)
                self.view.addSubview(mapView)

                // Creates a marker in the center of the map.
                let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                marker.title = "Kowloon Bay"
                marker.snippet = "Hong Kong"
                marker.map = mapView
            */
            

             
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func saveToDB() {
            do {
                try context.save()
            } catch {
                print("Error saving category \(error)")
            }
            
            //tableView.reloadData()
            
        }
        
    func loadFromDB() {
       
        let request = NSFetchRequest<Stop>(entityName: "Stop")
        print("hello")
      /*
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
       
        if let addtionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, addtionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }*/

        
        do {
         let itemArray = try context.fetch(request)
            print("DB items = \(itemArray)")
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        //tableView.reloadData()
        
    }

}
