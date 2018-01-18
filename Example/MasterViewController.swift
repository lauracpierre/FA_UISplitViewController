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

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: #selector(MasterViewController.showMenu))

    let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
    self.navigationItem.rightBarButtonItem = addButton
    if let split = self.splitViewController {
        let controllers = split.viewControllers
        self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
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

  @objc func insertNewObject(_ sender: AnyObject) {
    objects.insert(Date() as AnyObject, at: 0)
    let indexPath = IndexPath(row: 0, section: 0)
    self.tableView.insertRows(at: [indexPath], with: .automatic)
  }
  
  @objc func showMenu() {
      NotificationCenter.default.post(name: Notification.Name(rawValue: "MILLEFEUILLE_SHOW_MENU_NOTIFICATION_NAME"), object: nil)
  }

  // MARK: - Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      self.showingSecondary = true
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
    return objects.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

    let object = objects[(indexPath as NSIndexPath).row] as! Date
    cell.textLabel!.text = object.description
    return cell
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        objects.remove(at: (indexPath as NSIndexPath).row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    } else if editingStyle == .insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }


}

extension MasterViewController: MillefeuilleMasterViewMinimalImplementation {
  func selectionChangedInMenu(_ object: AnyObject?) {
    NSLog("Selection changed")
  }
  
  func detailIsDisplayingItem() -> Bool {
   return self.showingSecondary
  }
}

