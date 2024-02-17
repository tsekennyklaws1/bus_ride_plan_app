//
//  ViewController.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 30/1/2024.
//

import UIKit

class BusRouteViewController: UITableViewController, BusManagerDelegate {

    let defaults = UserDefaults.standard
    var busRoutesCellDisplay : [String] = []
    var routeCellSelected : [Bool] = []
    var selectedCellString : String = ""
    var busDataManager = BusDataManager()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
    
        super.viewDidLoad()
        /*
        //load from device's registry
        if let cachedBusRoute =  defaults.array(forKey: cacheNameForAllRoute) as? [String]{
            self.busRoutes = cachedBusRoute
        }
        */
        
        // Do any additional setup after loading the view.
        self.busDataManager.delegate = self
        if (busDataManager.busRouteDataList.count > 1) {
            self.busRoutesCellDisplay = busDataManager.busRouteDataList.map{$0.1}
            self.routeCellSelected = Array(repeating: false, count: self.busRoutesCellDisplay.count)
        } else if (busRoutesCellDisplay.count < 1){
            self.busDataManager.fetchAllBusRoute()
        }
    }
        
    //MARK - BusDataManager delegate
    
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        if let busRouteData = (busData as? BusRouteDataModel) {
            if busRouteData.data.count > 1 {
                self.busRoutesCellDisplay = (busData as! BusRouteDataModel).dataStringList
                self.routeCellSelected = Array(repeating: false, count: self.busRoutesCellDisplay.count)
                self.busDataManager.setBusRouteDataList(busRouteData.data as! [RouteData])
                //self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localRouteDataPath!,dataToBeSave: busRouteData.data as! [RouteData])
                self.busDataManager.saveBusDataToDB(path: self.busDataManager.localRouteDataPath!,dataToBeSave: busRouteData.data as! [RouteData])
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func didFailWithError(error: Error) {
        print("API failed \(error)")
    }
    
    //MARK: - TableView Datasource Methods
   
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return busRoutesCellDisplay.count
    }
 
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busRouteCells", for: indexPath)
        cell.textLabel?.text = busRoutesCellDisplay[indexPath.row]
        cell.accessoryType = self.routeCellSelected[indexPath.row] ? .detailButton : .none
        return cell
    }
    //MARK - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        self.routeCellSelected[indexPath.row] = !self.routeCellSelected[indexPath.row]
        let selectedRoute = busDataManager.busRouteDataList[indexPath.row]
        let routeParaList = selectedRoute.0.split(separator: ",")
        busDataManager.selectedRoute = (String(routeParaList[0]),String(routeParaList[1]),String(routeParaList[2]))
        self.selectedCellString = busRoutesCellDisplay[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        performSegue(withIdentifier: "goToRouteList", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "goToRouteList"{
            let destinationVC = segue.destination as! RouteListViewController
            destinationVC.busDataManager = self.busDataManager
            destinationVC.HeaderSelected = self.selectedCellString
        }
        
    }

    
}

