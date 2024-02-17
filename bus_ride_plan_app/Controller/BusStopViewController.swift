//
//  BusStopViewController.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 31/1/2024.
//

import UIKit
import CoreData

class BusStopViewController: UITableViewController, UISearchBarDelegate, BusManagerDelegate {
    let defaults = UserDefaults.standard
    @IBOutlet weak var searchBar: UISearchBar!
    var busStops  : [(stopCode:String,stopName:String)] = []
    var stopCellSelected : [Bool] = []
    var busDataManager = BusDataManager()
    var selectedStopName : String = ""
    var selectedStopCode : String = ""
    
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
        self.busDataManager.delegate = self
        
        if (busDataManager.bustStopsName.count > 1) {
            self.busStops = busDataManager.bustStopsName.map{($0.key,$0.value)}
            self.stopCellSelected = Array(repeating: false, count: self.busStops.count)
        } else if (self.busStops.count < 1){
            self.busDataManager.fetchAllBusStop()
        }
         
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    
    // MARK: - BusDataManager delegate
    
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        
        if let busStopData = (busData as? BusStopDataModel) {
            if busStopData.data.count > 1 {
                self.busStops = (busData as! BusStopDataModel).dataStringList
                self.busDataManager.setStopNameList(busStopData.data as! [StopData])
                self.stopCellSelected = Array(repeating: false, count: self.busStops.count)
                //self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
                self.busDataManager.saveBusDataToDB(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func didFailWithError(error: Error) {
        print("API failed \(error)")
    }
    
    // MARK: - Search Bar Delegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Clicked")
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return busStops.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busStopCells", for: indexPath)
        cell.textLabel?.text = busStops[indexPath.row].stopName
        cell.accessoryType = self.stopCellSelected[indexPath.row] ? .detailButton : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.stopCellSelected[indexPath.row] = !self.stopCellSelected[indexPath.row]
        busDataManager.selectedStopCode = busStops[indexPath.row].stopCode
        self.selectedStopName = busStops[indexPath.row].stopName
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        performSegue(withIdentifier: "goToStopRouteList", sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "goToStopRouteList"{
            let destinationVC = segue.destination as! StopEtaListViewController
            destinationVC.busDataManager = self.busDataManager
            destinationVC.selectedStopName = self.selectedStopName
        }
    }
    

}
