Pod::Spec.new do |s|
  s.name     = 'MultiSpeedSlider'
  s.version  = '1.0.2'
  s.license  = 'MIT'
  s.summary  = 'Subclass of UISlider giving variable scrubbing speed and also larger touch area support'
  s.homepage = 'https://github.com/Sajjon/MultiSpeedSlider'
  s.author   = { 'Alexander Cyon' => 'alex.cyon@gmail.com' }
  s.source   = { :git => 'https://github.com/Sajjon/MultiSpeedSlider.git', :tag => "#{s.version}" }
  s.description = 'MultuSpeedSlider is a UISlider subclass that adds variable scrubbing speeds as seen in the Music app on iOS. MultuSpeedSlider is formost a Swift porting of the excellent OBSlider pod written in Objective C. But this has slightly different behaviour. The user provides different threshold values for the when the vertical distance between the finger and the UISlider is big enough to switch to a different scrubbing speed. This makes it easier for the user to scrub with greater precision.'
  s.platform = :ios, '8.0'
  s.source_files = 'MultiSpeedSlider/**/*.{swift}'

  s.requires_arc = true
end