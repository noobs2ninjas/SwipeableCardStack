#
# Be sure to run `pod lib lint SwipeableCardStack.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwipeableCardStack'
  s.version          = '0.1.0'
  s.summary          = 'An easy to use library that creates stacks of cards that can be flung away with realism.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/noobs2ninjas/SwipeableCardStack'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'noobs2ninjas' => 'nathankellert@gmail.com' }
  s.source           = { :git => 'https://github.com/noobs2ninjas/SwipeableCardStack.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/noobs2ninjas'

  s.ios.deployment_target = '9.3'

  s.source_files = 'SwipeableCardStack/Classes/**/*'
  
  s.frameworks = 'UIKit'
end
