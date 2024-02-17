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
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    @IBOutlet weak var searchBar: UISearchBar!

    //var stopCellSelected = [Bool]()
    var busDataManager = BusDataManager()
    var selectedStopName : String = ""
    var selectedStopCode : String = ""
    var displayCells = [[(stopCode:String,stopName:String)]]()
    //var nearestStopCells = [(stopCode:String,stopName:String)]()
    
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
            self.displayCells.append(busDataManager.nearestBusStop)
            self.displayCells.append(busDataManager.bustStopsName.map{($0.key,$0.value)})
           // self.stopCellSelected = Array(repeating: false, count: displayCells.count)
        } else if (self.displayCells.count < 1){
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
                let stopData = (busData as! BusStopDataModel).dataStringList
                
                self.busDataManager.setStopNameList(busStopData.data as! [StopData])
               // self.stopCellSelected = Array(repeating: false, count: self.displayCells.count)
                //self.busDataManager.saveBusDataToLocal(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
                self.busDataManager.saveBusDataToDB(path: self.busDataManager.localStopDataPath!,dataToBeSave: busStopData.data as! [StopData])
                self.busDataManager.searchNearestBusStop()
                self.displayCells = [self.busDataManager.nearestBusStop,stopData]
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    func didFailWithError(error: Error) {
        print("API failed \(error)")
    }


    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections

            return displayCells.count

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

            return displayCells[section].count
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50))
        view.backgroundColor =  UIColor.lightGray
        let lbl = UILabel(frame: CGRect(x: 15, y: 0, width: view.frame.width - 15, height: 30))
        lbl.font = UIFont.boldSystemFont(ofSize: 20)
       // let keys = Array(routeStopListDict.keys)
        //let values = routeStopListDict.values.first
        //self.HeaderSelected = "\(keys[section]): \(String(values![0].1)) -> \(String(values![values!.count-1].1))"
        if (section == 0){
            if (self.displayCells.count > 1 && self.displayCells[0].count > 0){
                lbl.text = "最近的巴士站"
                view.addSubview(lbl)
            } else {
                return nil
            }
        } else {
            lbl.text = "所有巴士站"
            view.addSubview(lbl)
        }
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busStopCells", for: indexPath)
        //cell.accessoryType = self.stopCellSelected[indexPath.row] ? .detailButton : .none
        
        cell.textLabel?.text = displayCells[indexPath.section][indexPath.row].stopName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //self.stopCellSelected[indexPath.row] = !self.stopCellSelected[indexPath.row]
        busDataManager.selectedStopCode = displayCells[indexPath.section][indexPath.row].stopCode
        self.selectedStopName = displayCells[indexPath.section][indexPath.row].stopName
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
    
// MARK UISearchBar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        loadItems(searchBar.text!)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
          
        }
    }
    func loadItems( _ searchText : String = "") {
            
        if searchText != ""{
            let request : NSFetchRequest<Stop> = Stop.fetchRequest()
            
            let predicate_en = NSPredicate(format: "name_en CONTAINS[cd] %@", searchBar.text!)
            let predicate_tc = NSPredicate(format: "name_tc CONTAINS[cd] %@", searchBar.text!)
            let predicate_sc = NSPredicate(format: "name_sc CONTAINS[cd] %@", searchBar.text!)
            
            let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicate_en,predicate_tc,predicate_sc])
            //request.sortDescriptors = [NSSortDescriptor(key: "lat", ascending: true)]
            
            request.predicate = compoundPredicate
            
            do {
                let stopDBArray = try context.fetch(request)
                self.displayCells[1] = stopDBArray.map{(String($0.stop!),String($0.name_tc!))}
            } catch {
                print("Error fetching data from context \(error)")
            }
        } else{
            self.displayCells[1] = busDataManager.bustStopsName.map{($0.key,$0.value)}
        }
        tableView.reloadData()
            
    }
    
}
