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
    
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: #selector(MasterViewController.showMenu))
    
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
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
    NSNotificationCenter.defaultCenter().postNotificationName("SHOW_MENU", object: nil)
  }
  
  // MARK: - Segues
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let object = objects[indexPath.row] as! NSDate
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
        controller.detailItem = object
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    }
  }
  
  // MARK: - Table View
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    cell.textLabel?.text = "secondary master \(indexPath.row)"
    return cell
  }
}

extension Master2ViewController: MillefeuilleMasterViewMinimalImplementation {
  func selectionChangedInMenu(object: AnyObject?) {
    NSLog("changed: \(object)")
  }
  
  func detailIsDisplayingItem() -> Bool {
    return false
  }
}

