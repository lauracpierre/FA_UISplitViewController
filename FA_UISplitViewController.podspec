#
# Be sure to run `pod lib lint FA_TokenInputView.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = "FA_UISplitViewController"
s.version          = "0.0.8"
s.summary          = "FA_UISplitViewController is a controller to manage and add an overlay menu above the UISplitView"
s.description      = <<-DESC
This contoller let you add an overlay menu above the UISplitViewController.
The menu can then decide whether or not we should create a new UISplitViewContainer based on the selection.
Storyboard friendly.
DESC
s.homepage         = "https://github.com/lauracpierre/FA_UISPlitViewController"
s.license          = 'MIT'
s.author           = { "Pierre Laurac" => "pierre.laurac@gmail.com" }
s.source           = { :git => "https://github.com/lauracpierre/FA_UISplitViewController.git", :tag => "v#{s.version}" }

s.platform     = :ios, '8.0'
s.requires_arc = true

s.source_files = 'Pod/**/*'

end
