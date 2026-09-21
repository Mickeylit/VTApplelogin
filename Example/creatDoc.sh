#使用说明 替换lib_name
# 方法一
# chmod u+x createDoc.sh
# ./creatDoc.sh
# 方法二
# zsh creatDoc.sh

#!/bin/zsh
lib_name=VTAppleLogin

output="$(pwd)/docs/$lib_name"
swift_doc="$output/$lib_name-swift-doc.json"
objc_doc="$output/$lib_name-objc-doc.json"

lib_path=$(pwd)/../$lib_name/Classes
umbrella_header="$(pwd)/Pods/Target Support Files/$lib_name/$lib_name-umbrella.h"
sdk_path=`xcrun --show-sdk-path --sdk iphonesimulator`

#objc库生成文档
pod install
bundle exec jazzy -o docs/$lib_name \
--objc \
--sdk iphoneos \
--build-tool-arguments \
--objc,$umbrella_header,--,-x,objective-c,-isysroot,$sdk_path,-I,$lib_path

#混编合成
sourcekitten doc --objc $umbrella_header \
      -- -x objective-c -isysroot $sdk_path \
      -I $lib_path \
      -fmodules > $objc_doc

sourcekitten doc -- -project Pods/Pods.xcodeproj -target $lib_name > $swift_doc

jazzy -o $output --sourcekitten-sourcefile $swift_doc,$objc_doc

#swift库生成文档
#bundle exec jazzy -o docs/$lib_name \
    --build-tool-arguments -project,Pods/Pods.xcodeproj,-target,$lib_name
