//
//  ViewController.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 3/2/2024.
//

import UIKit
import CoreLocation
import CLTypingLabel

class LandingPageViewController: UIViewController, BusManagerDelegate {
    @IBOutlet weak var Welcome_title: CLTypingLabel!
    @IBOutlet weak var locationLabel: UILabel!
    let locationManager = CLLocationManager()
    var busDataManager = BusDataManager()
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
        if !busDataManager.loadBusDataFromLocal() {
            DispatchQueue.main.async {
                self.busDataManager.fetchAllBusStop()
            }
        }
    }

    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        
        if let busRouteData = (busData as? BusRouteDataModel) {
            if busRouteData.data.count > 1 {
                self.busDataManager.setBusRouteDataList(busRouteData.data as! [RouteData])
                self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localRouteDataPath!,dataToBeSave: busRouteData.data as! [RouteData])
            }
        } else if let busStopData = (busData as? BusStopDataModel) {
            if busStopData.data.count > 1 {
                self.busDataManager.setStopNameList(busStopData.data as! [StopData])
                self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
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
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
