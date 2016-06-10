//
//  MasterViewController.swift
//  test
//
//  Created by Pierre Laurac on 5/17/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

  var detailViewController: DetailViewController? = nil
  var objects = [AnyObject]()
  var showingSecondary = false


  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: #selector(MasterViewController.showMenu))

    let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
    self.navigationItem.rightBarButtonItem = addButton
    if let split = self.splitViewController {
        let controllers = split.viewControllers
        self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }

  override func viewWillAppear(animated: Bool) {
    self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
    super.viewWillAppear(animated)
    self.showingSecondary = false
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  deinit {
    NSLog("deinit MasterViewcontroller")
  }

  func insertNewObject(sender: AnyObject) {
    objects.insert(NSDate(), atIndex: 0)
    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }
  
  func showMenu() {
      NSNotificationCenter.defaultCenter().postNotificationName("SHOW_MENU", object: nil)
  }

  // MARK: - Segues
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      self.showingSecondary = true
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
    return objects.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

    let object = objects[indexPath.row] as! NSDate
    cell.textLabel!.text = object.description
    return cell
  }

  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
  }

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
        objects.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }


}

extension MasterViewController: MillefeuilleMasterViewMinimalImplementation {
  func selectionChangedInMenu(object: AnyObject?) {
    NSLog("changed: \(object)")
  }
  
  func detailIsDisplayingItem() -> Bool {
   return self.showingSecondary
  }
}

