//
//  RouteListViewController.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 3/2/2024.
//

import UIKit

class RouteListViewController: UITableViewController , BusManagerDelegate{
    var routeStopListDict : [String:[(stopCode: String,stopName: String)]] = [:]
    var routeStopList :[String] = []
    var routeStopItemSelected : [Bool] = []
    var HeaderSelected : String = ""
    var busDataManager = BusDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.busDataManager.delegate = self
        
        let selectedRoute = busDataManager.selectedRoute
        if (selectedRoute?.route != nil && selectedRoute?.service_type != nil && selectedRoute?.bound != nil ) {
            self.busDataManager.fetchRouteStops(route: selectedRoute!.route, direction: selectedRoute!.bound, service_type: selectedRoute!.service_type)
        }
         else if (routeStopList.count < 1){
                self.busDataManager.fetchRouteStops()
        } 
        if (busDataManager.busRouteStopList.count > 1) {
            //use the busRouteData from BusDataManager covert to [STring]
            self.routeStopList = busDataManager.busRouteStopList
            self.routeStopItemSelected = Array(repeating: false, count: self.routeStopList.count)
            self.routeStopListDict = busDataManager.routeStopDict
        }
    }

    // MARK: - BusManager Delegate
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        if let busRouteStopData = (busData as? BusRouteStopDataModel) {
            if busRouteStopData.data.count > 1 {
                let data = busRouteStopData.data as! [RouteStopData]
                self.routeStopList = data.map{(String(busDataManager.bustStopsName[$0.stop] ?? "")) }
                self.busDataManager.setAllRouteStopList(data)
                self.routeStopItemSelected = Array(repeating: false, count: self.routeStopList.count)
                let keysAndValues = data.map { ($0.route, [($0.stop, busDataManager.getBusStopName(busCode: $0.stop)) ]) }
                let newDict = Dictionary(keysAndValues, uniquingKeysWith: { $0 + $1 })
                busDataManager.routeStopDict = newDict
                routeStopListDict = newDict
                //self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localRouteStopDataPath!,dataToBeSave: data)
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didFailWithError(error: Error) {
        print("API failed \(error)")
    }
    // MARK: - TableView Datasource Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return routeStopListDict.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return routeStopList.count
    }


    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        view.backgroundColor =  UIColor.lightGray
        let lbl = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.width - 15, height: 30))
        lbl.font = UIFont.boldSystemFont(ofSize: 20)
        let keys = Array(routeStopListDict.keys)
        let values = routeStopListDict.values.first
        self.HeaderSelected = "\(keys[section]): \(String(values![0].1)) -> \(String(values![values!.count-1].1))"
        lbl.text = self.HeaderSelected
        view.addSubview(lbl)
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busRouteStopCells", for: indexPath)
        let keys = Array(routeStopListDict.keys)
        cell.textLabel?.text = String(routeStopListDict[keys[indexPath.section]]![indexPath.row].stopName)
        cell.accessoryType = self.routeStopItemSelected[indexPath.row] ? .detailButton : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        self.routeStopItemSelected[indexPath.row] = !self.routeStopItemSelected[indexPath.row]
        let keys = Array(routeStopListDict.keys)
        busDataManager.selectedStopCode = String(routeStopListDict[keys[indexPath.section]]![indexPath.row].stopCode)
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        performSegue(withIdentifier: "goToETADetail_route", sender: self)
        
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "goToETADetail_route"{
            let destinationVC = segue.destination as! EtaDetailViewController
            destinationVC.busDataManager = self.busDataManager
            destinationVC.HeaderSelected = self.HeaderSelected
        }
    }

}
