//
//  FA_leftMenuImplementation.swift
//  FA_UISplitViewController
//
//  Created by Pierre Laurac on 6/9/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import Foundation
import UIKit

class FA_LeftMenuImplementation: FA_MenuViewController, MillefeuilleLeftControllerSelectionProtocol {
  
  var tableView: UITableView!
  
  var previousRow = 0
  
  var selectedRow = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //self.tableView = UITableView
    self.tableView  = UITableView(frame: CGRectZero)
    self.tableView.translatesAutoresizingMaskIntoConstraints = false
    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.view.addSubview(self.tableView)
    
    let views = ["tableView": self.tableView]
    
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView]|", options: [], metrics: nil, views: views))
    self.view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: [], metrics: nil, views: views))
    
    self.navigationController?.title = "hello"
  }
  

  func shouldPassObject() -> AnyObject? {
      return "test"
  }

  func shouldPerformSegue() -> Bool {
    return selectedRow != previousRow
  }
  
  func performSegue() {
    guard let path = self.tableView.indexPathForSelectedRow else {
      return
    }
    
    if path.row == 0 {
      self.performSegueWithIdentifier("setZero", sender: self)
    }
    
    if path.row == 1 {
      self.performSegueWithIdentifier("setOne", sender: self)
    }
  }

  
}


extension FA_LeftMenuImplementation: UITableViewDataSource, UITableViewDelegate {
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
    
    cell.textLabel?.text = "cell \(indexPath.row)"
    
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    previousRow = selectedRow
    selectedRow = indexPath.row
    self.millefeuille?.selectionWasMade()
  }
}