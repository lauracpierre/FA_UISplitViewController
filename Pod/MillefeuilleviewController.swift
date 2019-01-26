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
  open var viewOverlay = UIView()
  
  let maxP1Width: CGFloat = 315
  /// Size of the overlay menu
  var leftMenuWidth: CGFloat {
    guard let availableWidth = self.view.window?.frame.width else { return maxP1Width }
    // We always want P1 to take at most 90% of the width
    if availableWidth < maxP1Width * 1.1 {
      return 0.9 * availableWidth
    }
    return maxP1Width
  }
  
  /// Time duration for the show/hide menu animation
  private var animationTimeDuration: TimeInterval = 0.4
  private var dampingRatio: CGFloat = 0.9
  private var openAnimationProgress: CGFloat = 0
  private var closeAnimationProgress: CGFloat = 0
  
  /// the main view displayed at all time in the device. For now, only supporting UISplitViewController
  open var mainViewController: UISplitViewController!
  
  /// the delegate to interact with the left menu in selectionWasMade
  var leftMenuDelegate: MillefeuilleLeftControllerSelectionProtocol?
  
  var leftMenuVisible: Bool = false
  
  public static let MILLEFEUILLE_SHOW_MENU = "MILLEFEUILLE_SHOW_MENU_NOTIFICATION_NAME"
  public static let MILLEFEUILLE_HIDE_MENU = "MILLEFEUILLE_HIDE_MENU_NOTIFICATION_NAME"
  
  private var openP1PropertyAnimator: UIViewPropertyAnimator?
  private var closeP1PropertyAnimator: UIViewPropertyAnimator?
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    
    // Performing the two segues right now creates the view controllers needed for the application.
    // It uses custom Segues in order to get a reference to the view controller
    self.performSegue(withIdentifier: loadMasterSegueIdentifier, sender: nil)
    self.performSegue(withIdentifier: loadMenuSegueIdentifier, sender: nil)
    
    // Registering to a show/hide events in order to display the left menu
    let center = NotificationCenter.default
    center.addObserver(self, selector: #selector(showMenus), name: NSNotification.Name(rawValue: MillefeuilleViewController.MILLEFEUILLE_SHOW_MENU), object: nil)
    center.addObserver(self, selector: #selector(hideMenuFromNotification), name: NSNotification.Name(rawValue: MillefeuilleViewController.MILLEFEUILLE_HIDE_MENU), object: nil)
    
    // Preparing the overlay view
    self.viewOverlay.backgroundColor = UIColor(red: 0.79, green: 0.8, blue: 0.83, alpha: 0.5)
    self.viewOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(overlayViewWasTapped)))
    self.viewOverlay.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanCloseGesture)))
    
    // Adding the left button on the detail view controller so that we can display the view controller if nothing is selected
    let navigationController = self.mainViewController.viewControllers[self.mainViewController.viewControllers.count-1] as! UINavigationController
    navigationController.topViewController!.navigationItem.leftBarButtonItem = self.mainViewController.displayModeButtonItem
    
    self.mainViewController.preferredDisplayMode = .allVisible
    self.mainViewController.maximumPrimaryColumnWidth = 315
  }
  
  /**
   * Call this method to hide the menu. The completion call back will be called when the animation has completed.
   */
  open func closeLeftMenu(_ completion: (() -> Void)? = nil) {
    self.hideMenus(completion)
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
    self.createClosePropertyAnimator()
    self.closeP1PropertyAnimator?.addCompletion{ position in
      guard position == .end else { return }
      completion?()
    }
    self.closeP1PropertyAnimator?.startAnimation()
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
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { ctx in
      self.view.frame.origin = CGPoint(x: 0, y: 0)
      if let leftViewController = self.leftViewController {
        self.leftViewController?.view.frame.origin.x = -leftViewController.view.frame.width
        self.leftViewController?.view.frame.size.height = size.height
      }
      self.viewOverlay.alpha = 0
      self.viewOverlay.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }) { ctx in
      guard ctx.isCancelled == false else { return }
      self.removeMenusFromSuperview()
      self.leftMenuVisible = false
    }
  }
  
  /**
   * Method to call in order to show the menu with the overlay menu.
   * This method will add the menuview and the overlay to the KeyWindow in order to always be over the master view
   */
  @objc func showMenus() {
    self.leftMenuVisible = true
    self.addLeftMenuToKeyWindow()
    self.showMenuFromCurrentFrame()
  }
  
  fileprivate func showMenuFromCurrentFrame() {
    self.createOpenPropertyAnimator()
    self.openP1PropertyAnimator?.startAnimation()
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
    guard let leftVC = self.leftViewController,
      let keyWindow = UIApplication.shared.keyWindow else { return }
    
    let o = UIScreen.main.bounds
    self.viewOverlay.frame = CGRect(x: 0, y: 0, width: o.width, height: o.height)
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
    
    let panGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanOpenGesture))
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
  
  private var hasRunningAnimations: Bool {
    return self.openP1PropertyAnimator?.isRunning ?? false || self.closeP1PropertyAnimator?.isRunning ?? false
  }
  
  private func createClosePropertyAnimator() {
    guard !self.hasRunningAnimations,
      let leftMenuView = self.leftViewController?.view else { return }

    self.viewOverlay.alpha = 0.75

    self.closeP1PropertyAnimator = UIViewPropertyAnimator(duration: self.animationTimeDuration, dampingRatio: self.dampingRatio, animations: {
      self.viewOverlay.alpha = 0.0
      leftMenuView.frame = CGRect(x: -self.leftMenuWidth, y: 0, width: self.leftMenuWidth, height: leftMenuView.frame.height)
      self.view.frame.origin.x = 0
      // Needed to properly update the safe area in P2
      self.view.layoutIfNeeded()
    })
    self.closeP1PropertyAnimator?.isUserInteractionEnabled = false
    self.closeP1PropertyAnimator?.addCompletion({ position in
      if position == .end {
        self.leftMenuVisible = false
        self.removeMenusFromSuperview()
      }
      self.closeP1PropertyAnimator = nil
    })
    self.closeP1PropertyAnimator?.startAnimation()
  }
  
  private func createOpenPropertyAnimator() {
    guard !self.hasRunningAnimations,
          let leftMenuView = self.leftViewController?.view else { return }
    
    self.addLeftMenuToKeyWindow()
    
    self.viewOverlay.alpha = 0.0
    self.view.frame.origin.x = 0
    
    leftMenuView.frame.origin = CGPoint(x: -self.leftMenuWidth, y: 0)
    leftMenuView.frame.size = CGSize(width: self.leftMenuWidth, height: self.view.frame.height)
    
    self.openP1PropertyAnimator = UIViewPropertyAnimator(duration: self.animationTimeDuration, dampingRatio: self.dampingRatio, animations: {
      self.viewOverlay.alpha = 0.75
      leftMenuView.frame = CGRect(x: 0, y: 0, width: self.leftMenuWidth, height: self.view.frame.height)
      self.view.frame.origin.x = self.leftMenuWidth
      // Needed to properly update the safe area in P2
      self.view.layoutIfNeeded()
    })
    self.openP1PropertyAnimator?.isUserInteractionEnabled = false
    self.openP1PropertyAnimator?.addCompletion({ position in
      if position == .start {
        self.leftMenuVisible = false
        self.removeMenusFromSuperview()
      }
      self.openP1PropertyAnimator = nil
    })
    self.openP1PropertyAnimator?.startAnimation()
  }
  
  @objc func overlayViewWasTapped(_ recognizer: UITapGestureRecognizer) {
    self.createClosePropertyAnimator()
  }
  
  @objc func handlePanCloseGesture(_ recognizer: UIPanGestureRecognizer) {
    guard let gestureView = self.mainViewController.viewControllers.first?.view,
      let leftMenuView = self.leftViewController?.view else { return }
    
    let gestureTranslation = recognizer.translation(in: gestureView).x
    let velocityX = recognizer.velocity(in: gestureView).x
    let horizontalChange = min(gestureTranslation, self.leftMenuWidth)
    
    switch recognizer.state {
    case .began:
      self.createClosePropertyAnimator()
      self.closeP1PropertyAnimator?.pauseAnimation()
      self.closeP1PropertyAnimator?.isReversed = false
      if let closeP1Animator = self.closeP1PropertyAnimator {
        self.closeAnimationProgress = closeP1Animator.fractionComplete
      }
    case .changed:
      self.closeP1PropertyAnimator?.isReversed = false
      self.closeP1PropertyAnimator?.fractionComplete = (-horizontalChange / self.leftMenuWidth) + self.closeAnimationProgress
    case .ended, .cancelled:
      let fractionComplete = self.closeP1PropertyAnimator?.fractionComplete ?? 0
      let remainingDistance = -gestureTranslation
      switch velocityX {
      case -100...100:
        if remainingDistance > self.leftMenuWidth / 2 {
          self.closeP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        } else {
          self.closeP1PropertyAnimator?.isReversed = true
          self.closeP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        }
      case 100...:
        self.closeP1PropertyAnimator?.isReversed = true
        self.closeP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
      case ...(-100):
        self.closeP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
      default:
        ()
      }
    default:
      ()
    }
  }
  
  @objc func handlePanOpenGesture(_ recognizer: UIPanGestureRecognizer) {
    guard let gestureView = self.mainViewController.viewControllers.first?.view else { return }
    
    // Simple gesture with no drag and drop
    let gestureTranslation = recognizer.translation(in: gestureView).x
    let horizontalChange = min(gestureTranslation, self.leftMenuWidth)
    
    switch recognizer.state {
    case .began:
      self.createOpenPropertyAnimator()
      self.openP1PropertyAnimator?.pauseAnimation()
      self.openP1PropertyAnimator?.isReversed = false
      self.openAnimationProgress = self.openP1PropertyAnimator?.fractionComplete ?? 0
    case .changed:
      self.openP1PropertyAnimator?.isReversed = false
      self.openP1PropertyAnimator?.fractionComplete = (horizontalChange / self.leftMenuWidth) + self.openAnimationProgress
    case .ended, .cancelled:
      let velocityX = recognizer.velocity(in: gestureView).x
      let remainingDistance = self.leftMenuWidth - gestureTranslation
      let fractionComplete = self.openP1PropertyAnimator?.fractionComplete ?? 0
      switch velocityX {
      case -100...100:
        if remainingDistance < self.leftMenuWidth / 2 {
          self.openP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        } else {
          self.openP1PropertyAnimator?.isReversed = true
          self.openP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
        }
      case 100...:
        self.openP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
      case ...(-100):
        self.openP1PropertyAnimator?.isReversed = true
        self.openP1PropertyAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 1)
      default:
        ()
      }
    default:
      ()
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
      source.addChild(self.destination)
      source.view.addSubview(self.destination.view)
      
      self.destination.didMove(toParent: source)
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
      if let previousSplit = source.children.first as? UISplitViewController {
        previousSplit.preferredDisplayMode = .primaryHidden
        previousSplit.willMove(toParent: nil)
        previousSplit.view.removeFromSuperview()
        previousSplit.removeFromParent()
      }
      
      if let splitViewController = self.destination as? UISplitViewController {
        splitViewController.delegate = source
      }
      
      source.passObjectToMasterViewController()
      source.hideMenus()
      source.addSwipeGestureToMasterViewController()
      
      // Presenting the views and keeping reference to the controller
      source.addChild(self.destination)
      source.view.addSubview(self.destination.view)
      
      self.destination.didMove(toParent: source)
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
