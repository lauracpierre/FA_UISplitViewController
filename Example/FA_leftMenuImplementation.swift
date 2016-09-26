//
//  FA_leftMenuImplementation.swift
//  FA_UISplitViewController
//
//  Created by Pierre Laurac on 6/9/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import Foundation
import UIKit

class FA_LeftMenuImplementation: MillefeuilleMenuViewController, MillefeuilleLeftControllerSelectionProtocol {
  
  var tableView: UITableView!
  
  var previousRow = 0
  
  var selectedRow = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //self.tableView = UITableView
    self.tableView  = UITableView(frame: CGRect.zero)
    self.tableView.translatesAutoresizingMaskIntoConstraints = false
    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.view.addSubview(self.tableView)
    
    let views = ["tableView": self.tableView!]
    
    self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: views))
    self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views))
    
    self.navigationController?.title = "hello"
  }
  

  func shouldPassObject() -> AnyObject? {
      return "test" as AnyObject?
  }

  func shouldPerformSegue() -> Bool {
    return selectedRow != previousRow
  }
  
  func performSegue() {
    guard let path = self.tableView.indexPathForSelectedRow else {
      return
    }
    
    if (path as NSIndexPath).row == 0 {
      self.performSegue(withIdentifier: "setZero", sender: self)
    }
    
    if (path as NSIndexPath).row == 1 {
      self.performSegue(withIdentifier: "setOne", sender: self)
    }
  }

  
}


extension FA_LeftMenuImplementation: UITableViewDataSource, UITableViewDelegate {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    cell.textLabel?.text = "cell \((indexPath as NSIndexPath).row)"
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    previousRow = selectedRow
    selectedRow = (indexPath as NSIndexPath).row
    self.millefeuille?.selectionWasMade()
  }
}
