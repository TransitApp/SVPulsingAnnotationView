Pod::Spec.new do |s|
  s.name            = 'SVPulsingAnnotationView'
  s.version         = '0.1'
  s.license         = 'ISC'
  s.summary         = 'Customizable MKUserLocationView replica.'
  s.homepage        = 'https://github.com/samvermette/SVPulsingAnnotationView'
  s.author          = { 'Sam Vermette' => 'hello@samvermette.com' }
  s.source          = { :git => 'https://github.com/samvermette/SVPulsingAnnotationView.git', :tag => s.version.to_s }
  s.source_files    = 'SVPulsingAnnotationView/*.{h,m}'
  s.frameworks      = 'QuartzCore', 'MapKit'
  s.preserve_paths  = 'Demo'
  s.requires_arc    = true
end
