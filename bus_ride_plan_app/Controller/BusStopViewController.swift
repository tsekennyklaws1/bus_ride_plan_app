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
    var displayCells = [(stopCode:String,stopName:String)]()
    
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
            self.displayCells = busDataManager.bustStopsName.map{($0.key,$0.value)}
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
                self.displayCells = (busData as! BusStopDataModel).dataStringList
                self.busDataManager.setStopNameList(busStopData.data as! [StopData])
               // self.stopCellSelected = Array(repeating: false, count: self.displayCells.count)
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


    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return displayCells.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busStopCells", for: indexPath)
        //cell.accessoryType = self.stopCellSelected[indexPath.row] ? .detailButton : .none
        cell.textLabel?.text = displayCells[indexPath.row].stopName
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //self.stopCellSelected[indexPath.row] = !self.stopCellSelected[indexPath.row]
        busDataManager.selectedStopCode = displayCells[indexPath.row].stopCode
        self.selectedStopName = displayCells[indexPath.row].stopName
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
            request.sortDescriptors = [NSSortDescriptor(key: "stopLat", ascending: true)]
            
            request.predicate = compoundPredicate
            
            do {
                let stopDBArray = try context.fetch(request)
                self.displayCells = stopDBArray.map{(String($0.busStop!),String($0.name_tc!))}
            } catch {
                print("Error fetching data from context \(error)")
            }
        } else{
            self.displayCells = busDataManager.bustStopsName.map{($0.key,$0.value)}
        }
        tableView.reloadData()
            
    }
    
}
