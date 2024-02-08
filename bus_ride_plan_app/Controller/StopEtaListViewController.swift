//
//  RouteListViewController.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 3/2/2024.
//

import UIKit

class StopEtaListViewController: UITableViewController , BusManagerDelegate{
    var stopEtaDict : [String:[String]] = [:]
    var tableCellList : [(routeStr: String, cellStr: String)] = []
    var tableCellItemSelected : [Bool] = []
    //var HeaderSelected : String = ""
    var busDataManager = BusDataManager()
    var selectedStopName : String = ""
    var selectedStopCode : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.busDataManager.delegate = self
        self.selectedStopCode = busDataManager.selectedStopCode
        if (tableCellList.count < 1){
             self.busDataManager.fetchStopsRoute_eta(stopCode: selectedStopCode)
        }
        if (busDataManager.busStopEtaList.count > 1) {
            self.tableCellList = busDataManager.busStopEtaList
            self.tableCellItemSelected = Array(repeating: false, count: self.tableCellList.count)
            
        }
    }

    // MARK: - BusManager Delegate
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        if let busStopEtaData = (busData as? BusStopEtaDataModel) {
            if busStopEtaData.data.count > 1 {
                let data = busStopEtaData.data as! [StopEtaData]
                self.tableCellList = data.map{($0.toRoute(),$0.toStr())}
                self.tableCellItemSelected = Array(repeating: false, count: self.tableCellList.count)
                self.busDataManager.setStopEtaList(data)
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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableCellList.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        view.backgroundColor =  UIColor.lightGray
        let lbl = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.width - 15, height: 30))
        lbl.font = UIFont.boldSystemFont(ofSize: 20)
        lbl.text = self.selectedStopName
        view.addSubview(lbl)
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stopRouteCells", for: indexPath)
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.text = tableCellList[indexPath.row].cellStr
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.tableCellItemSelected[indexPath.row] = !self.tableCellItemSelected[indexPath.row]
        let routeParaList = tableCellList[indexPath.row].routeStr.split(separator: ",")
        busDataManager.selectedRoute = (String(routeParaList[0]),String(routeParaList[1]),String(routeParaList[2]))
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
       // performSegue(withIdentifier: "goToETADetail_stop", sender: self)
    }
}
