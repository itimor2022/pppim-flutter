Pod::Spec.new do |s|
  s.name             = 'ZBar'
  s.version          = '1.3.1'
  s.summary          = 'A barcode reading library.'
  
  # Generate config.h to make it compatible with CocoaPods
  s.prepare_command = <<-CMD
    mkdir -p include
    echo '#define HAVE_INTTYPES_H 1' > include/config.h
    echo '#define HAVE_STDLIB_H 1' >> include/config.h
    echo '#define HAVE_STRING_H 1' >> include/config.h
    echo '#define HAVE_MEMORY_H 1' >> include/config.h
  CMD
  s.homepage         = 'https://github.com/ZBar/ZBar'
  s.license          = { :type => 'LGPL-2.1', :file => 'LICENSE' }
  s.author           = { 'ZBar' => 'http://zbar.sourceforge.net/' }
  s.source           = { :path => '.' }
  # If tag 1.3.1 doesn't exist, we might need a specific commit. 
  # But assuming trunk works? No, let's point to HEAD or a known commit if needed.
  # For now try git without tag to default to HEAD, or check repo tags.
  # But s.source in podspec is just metadata if we override in Podfile? 
  # Actually, if we use :podspec => local_file, the source inside matters if Podfile doesn't override it.
  
  s.platform     = :ios, '9.0'
  # Only include core decoding logic, exclude video/window/processor which contain platform specific and duplicate files
  s.source_files = 'include/*.h', 'zbar/*.c', 'zbar/decoder/*.c', 'zbar/qrcode/*.c'
  # Exclude the high-level managers that require backends (which we excluded) and might cause conflicts
  s.exclude_files = 'zbar/video.c', 'zbar/window.c', 'zbar/processor.c', 'zbar/svg.c', 'zbar/convert.c', 'zbar/decoder/pdf417.c', 'zbar/jpeg.c', 'zbar/png.c'
  s.public_header_files = 'include/*.h'
  s.libraries = 'iconv'
  s.frameworks = 'AVFoundation', 'CoreMedia', 'CoreVideo', 'QuartzCore'
  s.pod_target_xcconfig = { 
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/include" "${PODS_TARGET_SRCROOT}/zbar" "${PODS_TARGET_SRCROOT}/zbar/qrcode" "${PODS_TARGET_SRCROOT}/zbar/decoder"',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) ENABLE_QRCODE=1 ENABLE_EAN=1 ENABLE_I25=1 ENABLE_DATABAR=1 ENABLE_CODABAR=1 ENABLE_CODE39=1 ENABLE_CODE93=1 ENABLE_CODE128=1 HAVE_SYS_TIME_H=1 HAVE_UNISTD_H=1 HAVE_INTTYPES_H=1 HAVE_STDLIB_H=1 HAVE_STRING_H=1 HAVE_MEMORY_H=1 ZBAR_VERSION_MAJOR=0 ZBAR_VERSION_MINOR=10'
  }
  
  # ZBar structure is complex (autotools). It might need more tweaking.
  # But Adrift001 likely flattened it.
  # Using ZBarSDK podspec as reference would be best.
  # Let's hope official ZBar repo structure matches what's needed.
end
