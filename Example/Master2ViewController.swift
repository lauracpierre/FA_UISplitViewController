//
//  MasterViewController.swift
//  test
//
//  Created by Pierre Laurac on 5/17/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import UIKit

class Master2ViewController: UITableViewController {
  
  var detailViewController: DetailViewController? = nil
  var objects = [AnyObject]()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(MasterViewController.showMenu))
    
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  deinit {
    NSLog("deinit Master2Viewcontroller")
  }
  
  
  func showMenu() {
    NotificationCenter.default.post(name: Notification.Name(rawValue: "MILLEFEUILLE_SHOW_MENU_NOTIFICATION_NAME"), object: nil)
  }
  
  // MARK: - Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let object = objects[(indexPath as NSIndexPath).row] as! Date
        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
        controller.detailItem = object as AnyObject?
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }
  
  // MARK: - Table View
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    cell.textLabel?.text = "secondary master \((indexPath as NSIndexPath).row)"
    return cell
  }
}

extension Master2ViewController: MillefeuilleMasterViewMinimalImplementation {
  func selectionChangedInMenu(_ object: AnyObject?) {
    NSLog("Selection changed")
  }
  
  func detailIsDisplayingItem() -> Bool {
    return false
  }
}

