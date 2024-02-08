//
//  StopRouteEtaViewController.swift
//  bus_ride_plan_app
//
//  Created by Kwok Leung Tse on 6/2/2024.
//

import UIKit

class EtaDetailViewController: UITableViewController , BusManagerDelegate{
    var stopRouteEtaDict : [String:[String]] = [:]
    var tableCellList : [String] = []
    var tableCellItemSelected : [Bool] = []
    var HeaderSelected : String = ""
    var busDataManager = BusDataManager()
    var selectedStopName : String = ""
    var selectedStopCode : String = ""
    var selectedRoute : (route: String, bound: String, service_type: String) = ("","","")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.busDataManager.delegate = self
        self.selectedStopCode = busDataManager.selectedStopCode
        self.selectedStopName = busDataManager.getBusStopName(busCode: selectedStopCode)
        self.selectedRoute = busDataManager.selectedRoute!
        if (tableCellList.count < 1){
           
            self.busDataManager.fetchStopsRoute_etaDetail(stopCode: selectedStopCode, route: selectedRoute.route, service_type: selectedRoute.service_type)
             //self.busDataManager.fetchStopsRoute_eta(stopCode: selectedStopCode)
            //self.busDataManager.fetchSelectedRouteStops()
        }
        if (busDataManager.busEtaDetailList.count > 1) {

            self.tableCellList = busDataManager.busEtaDetailList
            self.tableCellItemSelected = Array(repeating: false, count: self.tableCellList.count)
            //self.stopRouteDict = busDataManager.StopRouteDict
            
        }
    }

    // MARK: - BusManager Delegate
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        if let busEtaDetailData = (busData as? BusEtaDetailDataModel) {
            if busEtaDetailData.data.count > 1 {
                let data = busEtaDetailData.data as! [EtaDetailData]
                self.tableCellList = data.map{"\(String($0.toStr()))"}
                self.busDataManager.setEtaDetailList(data)
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
        lbl.text = selectedStopName
        view.addSubview(lbl)
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eta_detail_cell", for: indexPath)
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.text = tableCellList[indexPath.row]
        return cell
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
