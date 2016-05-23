//
//  FA_MenuViewController.swift
//  test
//
//  Created by Pierre Laurac on 5/17/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import Foundation
import UIKit

class FA_MenuViewController: UIViewController {
  
  
  @IBAction func hideMenu(sender: AnyObject) {
    NSNotificationCenter.defaultCenter().postNotificationName("HIDE_MENU", object: nil)
  }
  
}