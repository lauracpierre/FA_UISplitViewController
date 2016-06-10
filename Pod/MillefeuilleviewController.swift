//
//  MillefeuilleviewController.swift
//  test
//
//  Created by Pierre Laurac on 5/17/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import Foundation
import UIKit

class MillefeuilleViewController: UIViewController {
  
  /// Segue name to create the left menu that will overlay the application
  private var loadMenuSegueIdentifier = "loadMenu"
  
  /// Segue name to create the master view for the UISplitViewController
  private var loadMasterSegueIdentifier = "loadMaster"
  
  /// variable to indicate whether or not we should check if the iPad start in Portrait mode to force the Overlay menu to appear
  private var modeCheckedAtLaunch = false
  
  /// A reference to the left menu view controller
  private var leftViewController: UIViewController?
  
  /// The view that we display in overlay of the application while we display the left menu
  private var viewOverlay = UIView()
  
  /// Size of the overlay menu
  var leftMenuWidth: CGFloat = 266.0
  
  /// Time duration for the show/hide menu animation
  var animationTimeDuration: NSTimeInterval = 0.3
  
  /// the main view displayed at all time in the device. For now, only supporting UISplitViewController
  var mainViewController: UISplitViewController!
  
  /// the delegate to interact with the left menu in selectionWasMade
  var leftMenuDelegate: MillefeuilleLeftControllerSelectionProtocol?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Performing the two segues right now creates the view controllers needed for the application. 
    // It uses custom Segues in order to get a reference to the view controller
    self.performSegueWithIdentifier(loadMasterSegueIdentifier, sender: nil)
    self.performSegueWithIdentifier(loadMenuSegueIdentifier, sender: nil)
    
    // Checks whether or not we should change the preferred Display mode to be .OverlayVisible or not
    self.changePreferredDisplayMode(self.isPortrait())
    
    // Registering to a show/hide events in order to display the left menu
    let center = NSNotificationCenter.defaultCenter()
    center.addObserver(self, selector: #selector(MillefeuilleViewController.showMenus), name: "SHOW_MENU", object: nil)
    center.addObserver(self, selector: #selector(MillefeuilleViewController.hideMenus), name: "HIDE_MENU", object: nil)
    
    // Preparing the overlay view
    let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(MillefeuilleViewController.overlayViewWasSwiped))
    swipeRecognizer.direction = .Left
    self.viewOverlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    self.viewOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MillefeuilleViewController.overlayViewWasTapped)))
    self.viewOverlay.addGestureRecognizer(swipeRecognizer)
    
    // Adding the left button on the detail view controller so that we can display the view controller if nothing is selected
    let navigationController = self.mainViewController.viewControllers[self.mainViewController.viewControllers.count-1] as! UINavigationController
    navigationController.topViewController!.navigationItem.leftBarButtonItem = self.mainViewController.displayModeButtonItem()
  }
  
  /**
   * Method called when the overlay receives a tap gesture
   * The goal is to hide the menu and the overlay
   */
  func overlayViewWasTapped() {
    self.hideMenus()
  }
  
  /**
   * Method called when the overlay receives a swipe gesture
   * The goal is to hide the menu and the overlay
   */
  func overlayViewWasSwiped() {
    self.hideMenus()
  }
  
  /**
   * This method checks if the iPad is in Portrait mode and if this is the first time we are displaying the view
   * If this is the case we force the preferredDisplayMode to be PrimaryOverlay.
   * Otherwise we let the UISplitViewController decide what it should be.
   */
  private func changePreferredDisplayMode(portrait: Bool) {
    if portrait && self.isIpad() && !self.modeCheckedAtLaunch {
      return self.mainViewController.preferredDisplayMode = .PrimaryOverlay
    }
    self.modeCheckedAtLaunch = true
    
    return self.mainViewController.preferredDisplayMode = .Automatic
  }
  
  /**
   * Method to call in order to hide the menu with the overlay menu.
   * This method will add the menuview and the overlay to the KeyWindow in order to always be over the master view
   */
  func hideMenus() {
    UIView.animateWithDuration(self.animationTimeDuration, animations: {
      self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.colorWithAlphaComponent(0.0)
      self.leftViewController?.view.frame = CGRectMake(-self.leftMenuWidth, 0, self.leftMenuWidth, self.leftViewController!.view.frame.height)
    }) { (_) in
      self.removeMenusFromSuperview()
    }
  }

  /**
   * Check if the device is in Landscape mode
   */
  func isLandscape() -> Bool {
    return !self.isPortrait()
  }
  
  /**
   * Check if the device is in Portrait mode
   */
  func isPortrait() -> Bool {
    let orientation = UIApplication.sharedApplication().statusBarOrientation
    return (orientation == .Portrait || orientation == .PortraitUpsideDown)
  }
  
  /**
   * Check if the device is in Landscape mode
   */
  override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
    self.hideMenusImmediately()
    self.changePreferredDisplayMode(!self.isPortrait())
  }
  
  /**
   * Method to call in order to show the menu with the overlay menu.
   * This method will add the menuview and the overlay to the KeyWindow in order to always be over the master view
   */
  func showMenus() {
    if let leftMenuView = self.leftViewController?.view {
      self.addLeftMenuToKeyWindow()
      UIView.animateWithDuration(self.animationTimeDuration, animations: {
        self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.colorWithAlphaComponent(0.5)
        leftMenuView.frame = CGRectMake(0, 0, self.leftMenuWidth, leftMenuView.frame.height)
      })
      
    }
  }
  
  func selectionWasMade() {
    guard let delegate = self.leftMenuDelegate else {
      return
    }
    
    // let's perform the segue if needed and return
    if delegate.shouldPerformSegue() {
      return delegate.performSegue()
    }
    
    self.passObjectToMasterViewController()
  }
  
  func passObjectToMasterViewController() {
    guard let delegate = self.leftMenuDelegate else {
      return
    }
    
    if let object = delegate.shouldPassObject(), let master = self.getMillefeuilleMasterMinimalImplementationObject() {
      master.selectionChangedInMenu(object)
    }
  }
  
  private func getMillefeuilleMasterMinimalImplementationObject() -> MillefeuilleMasterViewMinimalImplementation? {
    // if the master is a navigation controller, let's get the first viewcontroller
    if let nav = self.mainViewController.viewControllers.first as? UINavigationController, let master = nav.viewControllers.first as? MillefeuilleMasterViewMinimalImplementation {
      return master
    }
    
    // may be the master is a simple view controller
    if let master = self.mainViewController.viewControllers.first as? MillefeuilleMasterViewMinimalImplementation {
      return master
    }
    
    return nil
  }
  
  /**
   * Method to call in order to hide the menus without animation.
   */
  private func hideMenusImmediately() {
    self.removeMenusFromSuperview()
  }

  /**
   * Removes the menu from the superview in order: 
   * - Avoid constraint breaking during rotation
   * - Be less heavy on the UI resources
   */
  private func removeMenusFromSuperview() {
    self.viewOverlay.removeFromSuperview()
    self.leftViewController?.view.removeFromSuperview()
  }
  
  /**
   * Check if the device is an iPad
   */
  private func isIpad() -> Bool {
    return UIDevice.currentDevice().userInterfaceIdiom == .Pad
  }
  
  /**
   * Method responsible for:
   * - Add Overlay to key window (this way we are always above the master view, even when using PrimaryOverlay Visible)
   * - Add Leftviewcontroller's view to key window, above the overlay
   * - Ensure the left controller's view has the right size and position
   */
  private func addLeftMenuToKeyWindow() {
    guard let leftVC = self.leftViewController else {
      return
    }
    
    guard let keyWindow = UIApplication.sharedApplication().keyWindow else {
      return
    }
    
    let o = UIScreen.mainScreen().bounds
    let newFrame = CGRectMake(0, 0, o.width, o.height)
    self.viewOverlay.frame = newFrame
    keyWindow.addSubview(self.viewOverlay)
    
    leftVC.view.frame = CGRectMake(-self.leftMenuWidth, 0, self.leftMenuWidth, o.height)
    keyWindow.addSubview(leftVC.view)
  }
}

// MARK: - Delegate method for UISplitView
extension MillefeuilleViewController: UISplitViewControllerDelegate {
  
  func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
    guard let master = self.getMillefeuilleMasterMinimalImplementationObject() else {
      return false
    }
    
    return !master.detailIsDisplayingItem()
  }
  
}

// MARK: - Communication protocols
protocol MillefeuilleLeftControllerSelectionProtocol {
  
  /**
   * Delegate method asking if the left controller wants to pass an object to the splitViewcontroller's master controller
   * This method is called when the left controller called `selectionWasMade`:
   *  - Either immediately if there is no need to change the master's controller type
   *  - After executing the cell's segue, to give data to the newly created controller
   */
  func shouldPassObject() -> AnyObject?
  
  /**
   * Delegate method asking the left controller if the current master controller is the right one or not, and 
   * the MillefeuilleViewController should execute the segue to replace the masterViewController
   */
  func shouldPerformSegue() -> Bool
  
  /**
   * Method called to trigger segue in order to create the new view controller
   */
  func performSegue()
  
}


protocol MillefeuilleMasterViewMinimalImplementation {
  
  /**
   * Protocol to implement in order to be notified when the left menu changed the selection
   */
  func selectionChangedInMenu(object: AnyObject?)
  
  /** 
   * Asking the master view if it is already displaying the detail view
   */
  func detailIsDisplayingItem() -> Bool
}



// MARK: - Custom Segues

/**
 * Use this segue with a UISplitViewController in order to set the set and retain a reference to the UISplitViewController
 * If the source view controller is not of type MillefeuilleViewController then the segue will not do anything
 * If the destinaton view controller is not of type UISplitViewController then the segue will not do anything
 */
class FA_SetSplitViewSegue: UIStoryboardSegue {
  override func perform() {
    if let source = self.sourceViewController as? MillefeuilleViewController, main = self.destinationViewController as? UISplitViewController {
      source.mainViewController = main
      source.addChildViewController(self.destinationViewController)
      source.view.addSubview(self.destinationViewController.view)
      
      if let splitViewController = self.destinationViewController as? UISplitViewController {
        splitViewController.delegate = source
      }
    }
  }
}

/**
 * Use this segue with a UISplitViewController in order to set the set and retain a reference to the UISplitViewController
 * If the source view controller is not of type MillefeuilleViewController then the segue will not do anything
 * If the destinaton view controller is not of type UISplitViewController then the segue will not do anything
 */
class FA_SetSplitViewFromMenuSegue: UIStoryboardSegue {
  override func perform() {
    if let menu = self.sourceViewController as? MillefeuilleMenuViewController, let source = menu.millefeuille,  main = self.destinationViewController as? UISplitViewController {
      source.mainViewController = main
      
      // removing reference to previous child views and controller, otherwise we will never deinit the splitview controllers and memory will go off the charts
      if let previousSplit = source.childViewControllers.first as? UISplitViewController {
        previousSplit.preferredDisplayMode = .PrimaryHidden
        previousSplit.view.removeFromSuperview()
        previousSplit.removeFromParentViewController()
      }
      
      if let splitViewController = self.destinationViewController as? UISplitViewController {
        splitViewController.delegate = source
      }
      
      // Presenting the views and keeping reference to the controller
      source.addChildViewController(self.destinationViewController)
      source.view.addSubview(self.destinationViewController.view)

    }
  }
}

/**
 * Use this segue to get a reference to the left view you want to display as an overlay
 * If the source view controller is not of type MillefeuilleViewController then the segue will not do anything
 * If the destination view controller is not of type FA_LeftMenuViewController then the segue will not do anything
 */
class FA_SetMenuSegue: UIStoryboardSegue {
  override func perform() {
    if let source = self.sourceViewController as? MillefeuilleViewController {
      
      self.setupMenuSegue(source, destination: self.destinationViewController)
    }
  }
  
  private func setupMenuSegue(source: MillefeuilleViewController, destination: UIViewController) {
    source.leftViewController = destination
    
    if let destination = destination as? MillefeuilleMenuViewController {
      destination.millefeuille = source
      self.checkDestinationDelegate(source, destination: destination)
    }
    
    if let nav = self.destinationViewController as? UINavigationController, let destination = nav.viewControllers.first as? MillefeuilleMenuViewController {
      destination.millefeuille = source
      self.checkDestinationDelegate(source, destination: destination)
    }
  }
  
  private func checkDestinationDelegate(source: MillefeuilleViewController, destination: MillefeuilleMenuViewController) {
    if let delegate = destination as? MillefeuilleLeftControllerSelectionProtocol {
      source.leftMenuDelegate = delegate
    }
  }
}
