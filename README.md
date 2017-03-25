# FA_UISplitViewController

The goal of this Pod is to provide a simple hamburger menu specifically made for UISplitViewController. The menu can decide if a new controller should be used on the master view. This controller does not instantiate a new view controller upon a user action if the current main controller is of the same type.

The example provided in the project explains how to use this controller. 

`FA_UISPlitViewController` becomes the root view controller. You define in your Storyboard the segue to the two controllers:
- The main controller showed by default (expected to be a `UISplitViewController`).
  - Segue identifier: `loadMaster`
- The menu that will appear bove the main controller (can be any `UIViewController`). 
  - Segue identifier: `loadMenu`
 
 

### Main controller

The main controller can conform to the `MillefeuilleMasterViewMinimalImplementation` protocol and implement the following methods: 
```swift
func selectionChangedInMenu(_ object: AnyObject?)
```
The `FA_UISplitViewController` notifies the main view controller that a selection was made on the menu. The object is something the menu can pass to the main controller. This can be useful to know what was clicked on in the menu to update your UI.
```swift
func detailIsDisplayingItem() -> Bool
```
This method is called by the `UISplitViewController` wants to know if it should collapse the secondary controller.




### Menu controller
The menu controller should inherit from `MillefeuilleMenuViewController` which inherit from `UIViewController`. it adds a property to access the `MillefeuilleViewController`.


##### MillefeuilleMenuViewController
As the menu inherits from this controller, we can call the millefeuilleViewController. 
```swift
self.millefeuille?.selectionWasMade(hide: true)
```
This is to indicate to the `MillefeuilleMenuViewController` that a selection was made. 

##### Delegate methods
The menu should also conform to `MillefeuilleLeftControllerSelectionProtocol`, and implement the following methods: 
```swift
func shouldPassObject() -> AnyObject?
```
Delegate method asking if the left controller wants to pass an object to the splitViewcontroller's master controller
   * This method is called when the left controller called `selectionWasMade`:
     *   Either immediately if there is no need to change the master's controller type
     *   After executing the cell's segue, to give data to the newly created controller

```swift
func shouldPerformSegue() -> Bool
```
 Delegate method asking the left controller if the current master controller is the right one or not, and
   * the MillefeuilleViewController should execute the segue to replace the masterViewController

```swift
func performSegue()
```
Method called to trigger segue in order to create the new view controller


### Flow
Make sure to connect your menu and main controller on the storyboard with the correct segue names. `FA_UISplitViewController` will instantiate the controllers for you. 

#### Opening the menu
The main controller can post a notification to open the menu
`NotificationCenter.default.post(name: Notification.Name(rawValue: "MILLEFEUILLE_SHOW_MENU_NOTIFICATION_NAME"), object: nil)`

#### respond to user action
When the menu has a click action, it calls the `selectionWasMade`. The `FA_UISplitViewController` will call these methods in the following order: 
- `shouldPerformSegue`: Whether or not we need to perform a segue. The menu should know if there is a new for a new, different view controller.
  -  `performSegue`: let the menu call the required segue.
- `shouldPassObject`: Whether or not the menu wants to interact with the main controller by passing an object
  - `selectionChangedInMenu`: calls this method on the master
- Hides the menu if the hide paramater is true.

## Caveats

This controller should be modified to support any `UIViewcontroller` of choice.
