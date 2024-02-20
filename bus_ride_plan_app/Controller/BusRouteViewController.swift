//
//  ViewController.swift
//  Bus_route_app
//
//  Created by Kwok Leung Tse on 30/1/2024.
//

import UIKit
import CoreData

class BusRouteViewController: UITableViewController,UISearchBarDelegate, BusManagerDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    let defaults = UserDefaults.standard
    //var busRoutesCellDisplay : [String] = []
    //var routeCellSelected : [Bool] = []
    var selectedCellString : String = ""
    var filteredRouteList = [(route: String, displayStr: String)]()// "route,bound,service_type": "toStr"
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
            self.filteredRouteList = busDataManager.busRouteDataList
            //self.busRoutesCellDisplay = busDataManager.busRouteDataList.map{$0.1}
           // self.routeCellSelected = Array(repeating: false, count: self.busRoutesCellDisplay.count)
        } else if (filteredRouteList.count < 1){
            self.busDataManager.fetchAllBusRoute()
        }
    }
        
    //MARK - BusDataManager delegate
    
    func didUpdateBusData(_ busDataManager: BusDataManager, busData: BusDataModel) {
        if let busRouteData = (busData as? BusRouteDataModel) {
            if busRouteData.data.count > 1 {
                self.filteredRouteList = (busData as! BusRouteDataModel).dataStringList
               // self.routeCellSelected = Array(repeating: false, count: self.busRoutesCellDisplay.count)
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
        return filteredRouteList.count
    }
 
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busRouteCells", for: indexPath)
        cell.textLabel?.text = filteredRouteList[indexPath.row].displayStr
       // cell.accessoryType = self.routeCellSelected[indexPath.row] ? .detailButton : .none
        return cell
    }
    //MARK - Tableview Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        //self.routeCellSelected[indexPath.row] = !self.routeCellSelected[indexPath.row]
        let selectedRoute = self.filteredRouteList[indexPath.row].route
        let routeParaList = selectedRoute.split(separator: ",")
        busDataManager.selectedRoute = (String(routeParaList[0]),String(routeParaList[1]),String(routeParaList[2]))
        self.selectedCellString = self.filteredRouteList[indexPath.row].displayStr
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
                let request : NSFetchRequest<Route> = Route.fetchRequest()
                
                let predicate_route = NSPredicate(format: "route CONTAINS[cd] %@", searchBar.text!)
                let predicate_orig_en = NSPredicate(format: "orig_en CONTAINS[cd] %@", searchBar.text!)
                let predicate_dest_en = NSPredicate(format: "dest_en CONTAINS[cd] %@", searchBar.text!)
                let predicate_orig_tc = NSPredicate(format: "orig_tc CONTAINS[cd] %@", searchBar.text!)
                let predicate_dest_tc = NSPredicate(format: "dest_tc CONTAINS[cd] %@", searchBar.text!)
                let predicate_orig_sc = NSPredicate(format: "orig_sc CONTAINS[cd] %@", searchBar.text!)
                let predicate_dest_sc = NSPredicate(format: "dest_sc CONTAINS[cd] %@", searchBar.text!)
                
                let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicate_route,predicate_orig_en,predicate_dest_en,predicate_orig_tc,predicate_dest_tc,predicate_orig_sc,predicate_dest_sc])
                request.sortDescriptors = [NSSortDescriptor(key: "route", ascending: true)]
                
                request.predicate = compoundPredicate
                
                do {
                    let routeDBArray = try context.fetch(request)
                    self.filteredRouteList = routeDBArray.map{("\($0.route!),\($0.bound == "O" ? "outbound" : "inbound"),\(String(describing: $0.service_type))","\($0.route!) - \($0.orig_tc!)->\($0.dest_tc!)")}
                   // self.busRoutesCellDisplay = routeDBArray.map{"\($0.route!) - \($0.orig_tc!)->\($0.dest_tc!)"}
                    
                    
                } catch {
                    print("Error fetching data from context \(error)")
                }
            } else{
                self.filteredRouteList = busDataManager.busRouteDataList
                //self.busRoutesCellDisplay = busDataManager.busRouteDataList.map{$0.1}
            }
            tableView.reloadData()
                
        }

    
}

