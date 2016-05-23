//
//  MillefeuilleviewController.swift
//  test
//
//  Created by Pierre Laurac on 5/17/16.
//  Copyright © 2016 Pierre Laurac. All rights reserved.
//

import Foundation
import UIKit

struct ScreenSize
{
  static let SCREEN_WIDTH = UIScreen.mainScreen().bounds.size.width
  static let SCREEN_HEIGHT = UIScreen.mainScreen().bounds.size.height
  static let SCREEN_MAX_LENGTH = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
  static let SCREEN_MIN_LENGTH = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
  static let IS_IPHONE_4_OR_LESS =  UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
  static let IS_IPHONE_5 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
  static let IS_IPHONE_6 = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
  static let IS_IPHONE_6P = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
}

class MillefeuilleViewController: UIViewController {
  
  private var loadMenuSegueIdentifier = "loadMenu"
  private var loadMasterSegueIdentifier = "loadMaster"
  
  var mainViewController: UIViewController!
  private var leftViewController: UIViewController?
  var leftMenuWidth: CGFloat = 266.0
  private var menuExpanded = false
  private var viewOverlay = UIView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.performSegueWithIdentifier(loadMasterSegueIdentifier, sender: nil)
    self.performSegueWithIdentifier(loadMenuSegueIdentifier, sender: nil)
    
    let center = NSNotificationCenter.defaultCenter()
    center.addObserver(self, selector: #selector(MillefeuilleViewController.showHiddenMenus), name: "SHOW_MENU", object: nil)
    center.addObserver(self, selector: #selector(MillefeuilleViewController.hideMenu), name: "HIDE_MENU", object: nil)
    //center.addObserver(self, selector: #selector(MillefeuilleViewController.rotationDidChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    center.addObserver(self, selector: #selector(MillefeuilleViewController.showMaster), name: "SHOW_MASTER", object: nil)
    
    self.viewOverlay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    self.viewOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MillefeuilleViewController.overlayViewWasTapped)))
  }
  
  func overlayViewWasTapped() {
    self.hideMenu()
  }
  
  func showMaster() {
    let split = self.mainViewController as! UISplitViewController
    split.showViewController(split.viewControllers[0], sender: nil)
    //self.performSegueWithIdentifier("test", sender: self)
  }
  
  func isLandscape() -> Bool {
    let orientation = UIDevice.currentDevice().orientation
    return orientation == .LandscapeRight || orientation == .LandscapeLeft
  }
  
  func isRetina() -> Bool {
    return UIScreen.mainScreen().scale == 2
  }
  
  
//  func showMenu() {
//    if menuExpanded {
//      return
//    }
//    
//    if let leftVC = self.leftViewController {
//
//      leftVC.view.frame = CGRectMake(-self.leftMenuWidth, 0, self.leftMenuWidth, leftVC.view.frame.height)
//      UIApplication.sharedApplication().keyWindow?.addSubview(leftVC.view)
//      UIView.animateWithDuration(0.5, animations: {
//        if let key = UIApplication.sharedApplication().keyWindow {
//          key.subviews.forEach({ (view) in
//            if view != self.leftViewController?.view {
//              view.frame = CGRectMake(self.leftMenuWidth, 0, view.frame.width, view.frame.height)
//            } else {
//              view.frame = CGRectMake(0, 0, self.leftMenuWidth, key.frame.height)
//              NSLog("\(view)")
//            }
//          })
//
//        }
//        self.menuExpanded = true
//      })
//    }
//  }
  
  func showHiddenMenus() {
//    if let leftVC = self.leftViewController {
//      leftVC.modalPresentationStyle = .Custom
//      leftVC.transitioningDelegate = self
//      leftVC.popoverPresentationController?.sourceView = self.view
//      self.presentViewController(leftVC, animated: true, completion: nil)
//    }
    let mainController = self.getMasterController()
    let mainView = mainController.view
    let detailController = self.getDetailController()
    if let leftMenuView = self.leftViewController?.view {
      self.addLeftMenuToKeyWindow()
      self.addOverlay()
      UIView.animateWithDuration(0.5, animations: {
        self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.colorWithAlphaComponent(0.5)
        leftMenuView.frame = CGRectMake(0, 0, self.leftMenuWidth, leftMenuView.frame.height)
        
        if self.shouldMoveMasterToDisplayMenu() {
          mainView.frame = CGRectMake(self.leftMenuWidth, 0, mainView.frame.width, mainView.frame.height)
        }
        
        if let detailView = detailController?.view {
          if self.isLandscape() {
            detailView.frame = CGRectMake((self.leftMenuWidth/2 + mainView.frame.width), 0, detailView.frame.width, detailView.frame.height)
          } else {
            detailView.frame = CGRectMake(self.leftMenuWidth/2, 0, detailView.frame.width, detailView.frame.height)
          }
        }
      })
      
    }
  }
  
  func menuIsShowing() -> Bool {
    return self.viewOverlay.superview != nil
  }
  
  func addOverlay() {
    
    let idiom = UIDevice.currentDevice().userInterfaceIdiom
    let split = self.getSplitViewController()
    let o = UIScreen.mainScreen().bounds
    let newFrame = CGRectMake(0, 0, o.width, o.height)
    self.viewOverlay.frame = newFrame
    
    if idiom == UIUserInterfaceIdiom.Pad {
    
      if split.viewControllers.count < 2 {
        return
      }
      
      guard let nav = split.viewControllers[1] as? UINavigationController else {
        return
      }
      
      nav.view.addSubview(self.viewOverlay)

    } else if idiom == .Phone {
      let mainController = self.getMasterController()
      mainController.view.addSubview(self.viewOverlay)
    }
    
  }
  
  func shouldMoveMasterToDisplayMenu() -> Bool {

    if self.isIphone() {
      return false
    }
    if self.isIpad() {
      return true
    }
    return false
  }
  
  func isIpad() -> Bool {
    return UIDevice.currentDevice().userInterfaceIdiom == .Pad
  }
  
  func isIphone() -> Bool {
    return UIDevice.currentDevice().userInterfaceIdiom == .Phone
  }
  
  func addLeftMenuToKeyWindow() {
    guard let leftVC = self.leftViewController else {
      return
    }
    
    leftVC.view.frame = CGRectMake(-self.leftMenuWidth, 0, self.leftMenuWidth, leftVC.view.frame.height)
    UIApplication.sharedApplication().keyWindow?.addSubview(leftVC.view)
  }
  
//  func getMasterView() -> UIView {
//    let split = self.mainViewController as! UISplitViewController
//    return split.viewControllers[0].view
//  }
  
  func hideMenu() {
    let mainController = self.getMasterController()
    let detailController = self.getDetailController()
    
    let mainView = mainController.view
    let detailView = detailController?.view
    let f = mainView.frame
    let df = detailView?.frame
    
    UIView.animateWithDuration(0.5, animations: {
      self.viewOverlay.backgroundColor = self.viewOverlay.backgroundColor?.colorWithAlphaComponent(0.0)
      self.leftViewController?.view.frame = CGRectMake(-self.leftMenuWidth, 0, self.leftViewController!.view.frame.width, self.leftViewController!.view.frame.height)
      if self.isIpad() {
        if self.isLandscape() {
          let gap: CGFloat = self.isRetina() ? 0.5 : 1.0
          mainView.frame = CGRectMake(0, 0, f.width, f.height)
          if let df = df {
            detailView?.frame = CGRectMake(f.width + gap, 0, df.width, df.height)
          }
        } else {
          mainView.frame = CGRectMake(-f.width, 0, f.width, f.height)
          if let df = df {
            detailView?.frame = CGRectMake(0, 0, df.width, df.height)
          }
        }
      }
    }) { (_) in
      self.viewOverlay.removeFromSuperview()
      self.leftViewController?.view.removeFromSuperview()
    }
  }
  
//  func rotationDidChange(orientation: UIDeviceOrientation) {
//    NSLog("rotation finished: \(orientation)")
//    //self.hideMenu()
//  }
  
  func getSplitViewController() -> UISplitViewController {
    return self.mainViewController as! UISplitViewController
  }
  
  func getMasterController() -> UIViewController {
    return self.getSplitViewController().viewControllers[0]
  }
  
  func getDetailController() -> UIViewController? {
    let splitViewController = self.getSplitViewController()
    if splitViewController.viewControllers.count < 2 {
      return nil
    }
    
    return splitViewController.viewControllers[1]
  }
}

//extension MillefeuilleViewController: UIViewControllerTransitioningDelegate {
//  func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//    NSLog("should display controller")
//    return FA_TransitionPresentationAnimator()
//  }
//  
//  func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//    return FA_TransitionDismissalAnimator()
//  }
//}
//
//class FA_TransitionPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
//  var view: UIView? = nil
//  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
//    return 0.5
//  }
//  
//  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
//    NSLog("should animate presentation")
//    let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
//    let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
//    let containerView = transitionContext.containerView()
//    
//    
//    let animationDuration = self .transitionDuration(transitionContext)
//    
//    if let left = toViewController as? FA_MenuViewController,
//       let millefeuille = fromViewController as? MillefeuilleViewController,
//       let split = millefeuille.mainViewController as? UISplitViewController {
//      
//      let masterView = split.viewControllers[0].view
//      let o = left.view.frame
//      
//      
//      left.view.frame = CGRectMake(-millefeuille.leftMenuWidth, 0, millefeuille.leftMenuWidth, o.height)
//      containerView?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
//      containerView?.addSubview(toViewController.view)
//      containerView?.userInteractionEnabled = false
//      
//      //masterView.frame = CGRectMake(millefeuille.leftMenuWidth, 0, masterView.frame.width, masterView.frame.height)
//      //containerView?.addSubview(masterView)
//      
//      UIView.animateWithDuration(animationDuration, animations: { 
//        left.view.frame = CGRectMake(0,0, millefeuille.leftMenuWidth, o.height)
//        masterView.frame = CGRectMake(millefeuille.leftMenuWidth, 0, masterView.frame.width, masterView.frame.height)
//        //containerView?.backgroundColor = containerView?.backgroundColor?.colorWithAlphaComponent(0.5)
//      }, completion: { (animated) in
//        
//        NSLog("masterView frame: \(masterView.frame)")
//        NSLog("parentView is container?: \(masterView.superview == containerView)")
//        
//       
//      })
//    }
//  }
//}
//
//class FA_TransitionDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
//  func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
//    return 0.5
//  }
//  
//  func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
//    NSLog("should animate dismissal")
//  }
//}
extension MillefeuilleViewController: UISplitViewControllerDelegate {
  
  
  // I think called when we call showViewController
  func splitViewController(splitViewController: UISplitViewController, showViewController vc: UIViewController, sender: AnyObject?) -> Bool {
    NSLog("do you want to display master?")
    switch(splitViewController.displayMode) {
    case .AllVisible: self.showHiddenMenus();break
    case .PrimaryHidden:
      self.showHiddenMenus()
      break
    default: break
    }

    //self.performSegueWithIdentifier("DISPLAY_MENU", sender: nil)
    return true
  }
  
  func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
    guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
    guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
    if topAsDetailController.detailItem == nil {
      // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
      return true
    }
    return false
  }
  
  func splitViewController(svc: UISplitViewController, willChangeToDisplayMode displayMode: UISplitViewControllerDisplayMode) {
    
    switch (displayMode){
      case .AllVisible: NSLog("displaymode is changing: all visible"); break
      case .PrimaryHidden: NSLog("displaymode is changing: primary hidden"); break
      case .PrimaryOverlay: NSLog("displaymode is changing: primary overlay"); break
      case .Automatic: NSLog("displaymode is changing: auto"); break
    }
    if let view = self.leftViewController?.view {
      UIApplication.sharedApplication().keyWindow?.addSubview(view)
      UIView.animateWithDuration(0.2, animations: {
      
          if displayMode == .PrimaryOverlay {
            self.showHiddenMenus()
          } else if displayMode == .PrimaryHidden {
            self.hideMenu()
          } else if displayMode == .AllVisible {
            self.hideMenu()
        }
      })
    }

  }
  
  func splitViewController(splitViewController: UISplitViewController, showDetailViewController vc: UIViewController, sender: AnyObject?) -> Bool {
    NSLog("do you want to disoplauy the secondary?")
    
    if !self.menuIsShowing() {
      return false
    }
    
    guard let detailViewController = self.getDetailController() else {
      return false
    }
    
    let currentView = detailViewController.view
    let splitViewController = self.getSplitViewController()
    vc.view.frame = CGRectMake(currentView.frame.origin.x, currentView.frame.origin.y, currentView.frame.width, currentView.frame.height)
    vc.view.addSubview(self.viewOverlay)
    splitViewController.viewControllers[1] = vc
    
    return true
  }
  
}

class FA_SetMasterMenuSegue: UIStoryboardSegue {
  override func perform() {
    if let source = self.sourceViewController as? MillefeuilleViewController {
      source.mainViewController = self.destinationViewController
      source.addChildViewController(self.destinationViewController)
      source.view.addSubview(self.destinationViewController.view)
      
      if let splitViewController = self.destinationViewController as? UISplitViewController {
        splitViewController.delegate = source
      }
    }
  }
}

class FA_SetMenuSegue: UIStoryboardSegue {
  override func perform() {
    if let source = self.sourceViewController as? MillefeuilleViewController {
      let o = self.destinationViewController.view.frame
      let frame = CGRectMake(-source.leftMenuWidth, o.origin.y, source.leftMenuWidth, o.height)
      self.destinationViewController.view.frame = frame
      source.leftViewController = self.destinationViewController
      //UIApplication.sharedApplication().keyWindow?.addSubview(self.destinationViewController.view)
    }
  }
}