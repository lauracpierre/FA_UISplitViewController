//
//  MillefeuilleviewController.swift
//  test
//
//  Created by Pierre Laurac on 5/17/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import Foundation
import UIKit

open class MillefeuilleViewController: UIViewController {
  
  /// Segue name to create the left menu that will overlay the application
  fileprivate var loadMenuSegueIdentifier = "loadMenu"
  
  /// Segue name to create the master view for the UISplitViewController
  fileprivate var loadMasterSegueIdentifier = "loadMaster"
  
  /// variable to indicate whether or not we should check if the iPad start in Portrait mode to force the Overlay menu to appear
  fileprivate var modeCheckedAtLaunch = false
  
  /// Variable to change the opacity of the menu drop shadow
  open var dropShadowOpacity: Float = 0.8
  
  /// A reference to the left menu view controller
  open var leftViewController: UIViewController?
  
  /// The view that we display in overlay of the application while we display the left menu
  fileprivate var viewOverlay = UIView()
  
  /// Size of the overlay menu
  var leftMenuWidth: CGFloat = 266.0
  
  /// Time duration for the show/hide menu animation
  var animationTimeDuration: TimeInterval = 0.3
  
  /// the main view displayed at all time in the device. For now, only supporting UISplitViewController
  open var mainViewController: UISplitViewController!
  
  /// the delegate to interact with the left menu in selectionWasMade
  var leftMenuDelegate: MillefeuilleLeftControllerSelectionProtocol?
  
  var leftMenuVisible: Bool = false
  
  var gestureToDisplayOngoing: Bool = false
  
  let panGestureXLocationStart: CGFloat = 70.0
  
  open static let MILLEFEUILLE_SHOW_MENU = "MILLEFEUILLE_SHOW_MENU_NOTIFICATION_NAME"
  
  open static let MILLEFEUILLE_HIDE_MENU = "MILLEFEUILLE_HIDE_MENU_NOTIFICATION_NAME"
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    // Performing the two segues right now creates the view controllers needed for the application.
    // It uses custom Segues in order to get a reference to the view controller
    self.performSegue(withIdentifier: loadMasterSegueIdentifier, sender: nil)
    self.performSegue(withIdentifier: loadMenuSegueIdentifier, sender: nil)
    
    // Checks whether or not we should change the preferred Display mode to be .OverlayVisible or not
    self.changePreferredDisplayMode(self.isPortrait())
    
    // Registering to a show/hide events in order to display the left menu
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(MillefeuilleViewController.showMenus), name: NSNotification.Name(rawValue: MillefeuilleViewController.MILLEFEUILLE_SHOW_MENU), object: nil)
    center.addObserver(self, selector: #selector(MillefeuilleViewController.hideMenuFromNotification), name: NSNotification.Name(rawValue: MillefeuilleViewController.MILLEFEUILLE_HIDE_MENU), object: nil)
    
    // Preparing the overlay view
    let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(MillefeuilleViewController.overlayViewWasSwiped))
    swipeRecognizer.direction = .left
    self.viewOverlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    self.viewOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MillefeuilleViewController.overlayViewWasTapped)))
    self.viewOverlay.addGestureRecognizer(swipeRecognizer)
    
    // Adding the left button on the detail view controller so that we can display the view controller if nothing is selected
    let navigationController = self.mainViewController.viewControllers[self.mainViewController.viewControllers.count-1] as! UINavigationController
    navigationController.topViewController!.navigationItem.leftBarButtonItem = self.mainViewController.displayModeButtonItem
    
    self.leftViewController?.view.layer.shadowColor = UIColor.black.cgColor
    self.leftViewController?.view.layer.shadowOffset = CGSize(width: 0, height: 0)
    //self.leftViewController?.view.layer.shadowOpacity = 0.8
  }
  
  /**
   * Call this method to hide the menu. The completion call back will be called when the animation has completed.
   */
  open func closeLeftMenu(_ completion: (() -> Void)? = nil) {
    self.hideMenus(completion)
  }
  
  /**
   * Method called when the overlay receives a tap gesture
   * The goal is to hide the menu and the overlay
   */
  @objc func overlayViewWasTapped() {
    self.hideMenus()
  }
  
  /**
   * Method called when the overlay receives a swipe gesture
   * The goal is to hide the menu and the overlay
   */
  @objc func overlayViewWasSwiped() {
    self.hideMenus()
  }
  
  /**
   * This method checks if the iPad is in Portrait mode and if this is the first time we are displaying the view
   * If this is the case we force the preferredDisplayMode to be PrimaryOverlay.
   * Otherwise we let the UISplitViewController decide what it should be.
   */
  fileprivate func changePreferredDisplayMode(_ portrait: Bool) {
    if portrait && self.isIpad() && !self.modeCheckedAtLaunch {
      return self.mainViewController.preferredDisplayMode = .primaryOverlay
    }
    self.modeCheckedAtLaunch = true
    
    return self.mainViewController.preferredDisplayMode = .automatic
  }
  
  /**
   * Method to call in order to hide the menu with the overlay menu.
   * This method will add the menuview and the overlay to the KeyWindow in order to always be over the master view
   */
  func hideMenus(_ completion: (() -> Void)? = nil) {
    self.hideMenuFromCurrentFrame(self.animationTimeDuration, shadowStart: 0.0, completion: completion)
  }
  
  @objc func hideMenuFromNotification() {
    self.hideMenus()
  }
  
  func hideMenuFromCurrentFrame(_ duration: TimeInterval, shadowStart: Float, completion: (() -> Void)? = nil) {
    self.leftMenuVisible = false
    
    let animation = CABasicAnimation(keyPath: "shadowOpacity")
    animation.toValue = self.dropShadowOpacity
    animation.fromValue = NSNumber(value: shadowStart as Float)
    animation.duration = self.animationTimeDuration
    self.leftViewController?.view.layer.add(animation, forKey: "shadowOpacity")
    self.leftViewController?.view.layer.shadowOpacity = shadowStart
    
    UIView.animate(withDuration: self.animationTimeDuration, delay: 0.0, options: [.allowUserInteraction], animations: {
      self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.withAlphaComponent(0.0)
      self.leftViewController?.view.frame = CGRect(x: -self.leftMenuWidth, y: 0, width: self.leftMenuWidth, height: self.leftViewController!.view.frame.height)
    }) { (_) in
      self.removeMenusFromSuperview()
      completion?()
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
    let orientation = UIApplication.shared.statusBarOrientation
    return (orientation == .portrait || orientation == .portraitUpsideDown)
  }
  
  /**
   * Check if the device is in Landscape mode
   */
  override open func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
    self.hideMenusImmediately()
    self.changePreferredDisplayMode(!self.isPortrait())
  }
  
  /**
   * Method to call in order to show the menu with the overlay menu.
   * This method will add the menuview and the overlay to the KeyWindow in order to always be over the master view
   */
  @objc func showMenus() {
    self.leftMenuVisible = true
    self.addLeftMenuToKeyWindow()
    self.showMenuFromCurrentFrame(self.animationTimeDuration, shadowStart: self.dropShadowOpacity)
  }
  
  fileprivate func showMenuFromCurrentFrame(_ animationDuration: TimeInterval, shadowStart: Float) {
    guard let leftMenuView = self.leftViewController?.view else { return }
    
    let animation = CABasicAnimation(keyPath: "shadowOpacity")
    animation.toValue = NSNumber(value: shadowStart as Float)
    animation.fromValue = self.dropShadowOpacity
    animation.duration = self.animationTimeDuration
    leftMenuView.layer.add(animation, forKey: "shadowOpacity")
    leftMenuView.layer.shadowOpacity = self.dropShadowOpacity

    
    UIView.animate(withDuration: self.animationTimeDuration, delay: 0.0, options: [.allowUserInteraction], animations: { 
      self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.withAlphaComponent(0.5)
      leftMenuView.frame = CGRect(x: 0, y: 0, width: self.leftMenuWidth, height: leftMenuView.frame.height)
    }, completion: nil)
  }
  
  open func selectionWasMade(hide: Bool) {
    guard let delegate = self.leftMenuDelegate else {
      return
    }
    
    // let's perform the segue if needed and return
    if delegate.shouldPerformSegue() {
      return delegate.performSegue()
    }
    
    self.passObjectToMasterViewController()
    
    if (hide) {
      self.hideMenus()
    }
  }
  
  func passObjectToMasterViewController() {
    guard let delegate = self.leftMenuDelegate else {
      return
    }
    
    if let object = delegate.shouldPassObject(), let master = self.getMillefeuilleMasterMinimalImplementationObject() {
      master.selectionChangedInMenu(object)
    }
  }
  
  fileprivate func getMillefeuilleMasterMinimalImplementationObject() -> MillefeuilleMasterViewMinimalImplementation? {
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
  fileprivate func hideMenusImmediately() {
    self.removeMenusFromSuperview()
    self.leftMenuVisible = false
  }
  
  /**
   * Removes the menu from the superview in order:
   * - Avoid constraint breaking during rotation
   * - Be less heavy on the UI resources
   */
  fileprivate func removeMenusFromSuperview() {
    self.viewOverlay.removeFromSuperview()
    self.leftViewController?.view.removeFromSuperview()
  }
  
  /**
   * Check if the device is an iPad
   */
  fileprivate func isIpad() -> Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
  }
  
  /**
   * Method responsible for:
   * - Add Overlay to key window (this way we are always above the master view, even when using PrimaryOverlay Visible)
   * - Add Leftviewcontroller's view to key window, above the overlay
   * - Ensure the left controller's view has the right size and position
   */
  fileprivate func addLeftMenuToKeyWindow() {
    guard let leftVC = self.leftViewController else {
      return
    }
    
    guard let keyWindow = UIApplication.shared.keyWindow else {
      return
    }
    
    let o = UIScreen.main.bounds
    let newFrame = CGRect(x: 0, y: 0, width: o.width, height: o.height)
    self.viewOverlay.frame = newFrame
    keyWindow.addSubview(self.viewOverlay)
    
    leftVC.view.frame = CGRect(x: -self.leftMenuWidth, y: 0, width: self.leftMenuWidth, height: o.height)
    keyWindow.addSubview(leftVC.view)
  }
  
  /**
   * Add the swiping gesture to the split view first controller
   * The gesture is added at this level so that in iPad Portrait mode, you can still display the menu i noverlay and then use the gesture again to open the left menu
   */
  fileprivate func addSwipeGestureToMasterViewController() {
    guard let master = self.mainViewController else { return }
    guard let nav = master.viewControllers.first as? UINavigationController else { return }
    guard let view = nav.viewControllers.first?.view else { return }
    
    let panGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(MillefeuilleViewController.handlePanGesture(_:)))
    panGestureRecognizer.edges = [.left]
    panGestureRecognizer.delegate = self
    view.addGestureRecognizer(panGestureRecognizer)
  }
}

// MARK: - Delegate method for UISplitView
extension MillefeuilleViewController: UISplitViewControllerDelegate {
  
  public func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
    guard let master = self.getMillefeuilleMasterMinimalImplementationObject() else {
      return false
    }
    
    return !master.detailIsDisplayingItem()
  }
}

extension MillefeuilleViewController: UIGestureRecognizerDelegate {
  @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
    guard let gestureView = self.mainViewController.viewControllers.first?.view else { return }
    guard let leftMenuView = self.leftViewController?.view else { return }
    
    // Simple gesture with no drag and drop
    let gestureTranslation = recognizer.translation(in: gestureView).x,
        horizontalChange = (gestureTranslation < self.leftMenuWidth) ? gestureTranslation : self.leftMenuWidth,
        positionStart = (-self.leftMenuWidth + horizontalChange),
        distance = (horizontalChange / self.leftMenuWidth),
        shadow = Float(distance * 0.8),
        alpha = distance * 0.5
    
    switch(recognizer.state) {
    case .began:
      self.gestureToDisplayOngoing = true
      self.addLeftMenuToKeyWindow()
      break
    case .changed:
      
      self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.withAlphaComponent(alpha)
      leftMenuView.frame = CGRect(x: positionStart, y: 0, width: self.leftMenuWidth, height: leftMenuView.frame.height)
      leftMenuView.layer.shadowOpacity = shadow
      break
      
    case .ended:
      self.gestureToDisplayOngoing = false
      
      // the gesture went further that the menu size, the menu is fully expanded, exiting
      if gestureTranslation >= self.leftMenuWidth {
        return
      }
      
      let velocityX = recognizer.velocity(in: gestureView).x,
          remainingDistance = self.leftMenuWidth - gestureTranslation,
          duration = Double(remainingDistance / velocityX)
      
      // positive velocity, we are opening the menu, 
      // let's check the velocity to decide wether to close or open
      if velocityX > 0 {

        // if the velocity is fast, let's open the menu right away at the correct speed
        if velocityX > 100 {
          self.showMenuFromCurrentFrame(duration, shadowStart: shadow)
          return
        }
        
        // velocity is slow, let's check how much we opened of the menu. if more than half, open the menu
        if remainingDistance < self.leftMenuWidth / 2 {
          self.showMenuFromCurrentFrame(duration, shadowStart: shadow)
          return
        }
        
        // let's hide it
        self.hideMenuFromCurrentFrame(duration, shadowStart: shadow)
        return
      }
      
      // with a negative velocity, we are potentially closing the menu
      // let's checking the velocity to decide
      if velocityX < -150 {
        self.hideMenuFromCurrentFrame(duration, shadowStart: shadow)
        return
      }
      
      // velocity is slow, let's check how much we closed of the menu. if more than half, open the menu
      if remainingDistance < self.leftMenuWidth / 2 {
        self.showMenuFromCurrentFrame(duration, shadowStart: shadow)
        return
      }
      
      // let's hide it
      self.hideMenuFromCurrentFrame(duration, shadowStart: shadow)
      return
    default:
      break
    }
  }
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    
    if gestureRecognizer is UITapGestureRecognizer {
      // We have to "disable" tap gesture when collapse otherwise we will prevent
      // the view to handle normal tap gesture (like on UITableView)
      if !self.leftMenuVisible {
        return false
      }
    }
    
    return true
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return gestureRecognizer is UIScreenEdgePanGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return gestureRecognizer is UIScreenEdgePanGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer
  }
}

// MARK: - Communication protocols
public protocol MillefeuilleLeftControllerSelectionProtocol {
  
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


public protocol MillefeuilleMasterViewMinimalImplementation {
  
  /**
   * Protocol to implement in order to be notified when the left menu changed the selection
   */
  func selectionChangedInMenu(_ object: AnyObject?)
  
  /**
   * Asking the master view if it is already displaying the detail view
   */
  func detailIsDisplayingItem() -> Bool
}

fileprivate extension UIView {
  func constraintTo(view: UIView) {
    NSLayoutConstraint.activate([
      self.topAnchor.constraint(equalTo: view.topAnchor),
      self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      self.leftAnchor.constraint(equalTo: view.leftAnchor),
      self.rightAnchor.constraint(equalTo: view.rightAnchor)
    ])
  }
}



// MARK: - Custom Segues

/**
 * Use this segue with a UISplitViewController in order to set the set and retain a reference to the UISplitViewController
 * If the source view controller is not of type MillefeuilleViewController then the segue will not do anything
 * If the destinaton view controller is not of type UISplitViewController then the segue will not do anything
 */
class FA_SetSplitViewSegue: UIStoryboardSegue {
  override func perform() {
    if let source = self.source as? MillefeuilleViewController, let main = self.destination as? UISplitViewController {
      source.mainViewController = main
      source.addChildViewController(self.destination)
      source.view.addSubview(self.destination.view)
      
      self.destination.didMove(toParentViewController: source)
      self.destination.view.translatesAutoresizingMaskIntoConstraints = false
      self.destination.view.constraintTo(view: source.view)

      source.addSwipeGestureToMasterViewController()
      
      if let splitViewController = self.destination as? UISplitViewController {
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
    if let menu = self.source as? MillefeuilleMenuViewController, let source = menu.millefeuille,  let main = self.destination as? UISplitViewController {
      source.mainViewController = main
      
      // removing reference to previous child views and controller, otherwise we will never deinit the splitview controllers and memory will go off the charts
      if let previousSplit = source.childViewControllers.first as? UISplitViewController {
        previousSplit.preferredDisplayMode = .primaryHidden
        previousSplit.view.removeFromSuperview()
        previousSplit.removeFromParentViewController()
      }
      
      if let splitViewController = self.destination as? UISplitViewController {
        splitViewController.delegate = source
      }
      
      source.passObjectToMasterViewController()
      source.hideMenus()
      source.addSwipeGestureToMasterViewController()
      
      // Presenting the views and keeping reference to the controller
      source.addChildViewController(self.destination)
      source.view.addSubview(self.destination.view)
      
      self.destination.didMove(toParentViewController: source)
      self.destination.view.translatesAutoresizingMaskIntoConstraints = false
      self.destination.view.constraintTo(view: source.view)
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
    if let source = self.source as? MillefeuilleViewController {
      
      self.setupMenuSegue(source, destination: self.destination)
    }
  }
  
  fileprivate func setupMenuSegue(_ source: MillefeuilleViewController, destination: UIViewController) {
    source.leftViewController = destination
    
    if let destination = destination as? MillefeuilleMenuViewController {
      destination.millefeuille = source
      self.checkDestinationDelegate(source, destination: destination)
    }
    
    if let nav = self.destination as? UINavigationController, let destination = nav.viewControllers.first as? MillefeuilleMenuViewController {
      destination.millefeuille = source
      self.checkDestinationDelegate(source, destination: destination)
    }
  }
  
  fileprivate func checkDestinationDelegate(_ source: MillefeuilleViewController, destination: MillefeuilleMenuViewController) {
    if let delegate = destination as? MillefeuilleLeftControllerSelectionProtocol {
      source.leftMenuDelegate = delegate
    }
  }
}
