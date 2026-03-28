Pod::Spec.new do |s|
  s.name             = 'ffmpeg-kit-ios-full-gpl'
  s.version          = '6.0'
  s.summary          = 'FFmpegKit for iOS'
  s.homepage         = 'https://github.com/arthenica/ffmpeg-kit'
  s.license          = { :type => 'LGPLv3' }
  s.author           = { 'Taner Sener' => 'tanersener@gmail.com' }
  s.source           = { :http => "https://github.com/luthviar/ffmpeg-kit-ios-full/releases/download/6.0/ffmpeg-kit-ios-full.zip" }
  s.platform         = :ios, '12.1'
  s.vendored_frameworks = 'ffmpeg-kit-ios-full/*.xcframework'
end
