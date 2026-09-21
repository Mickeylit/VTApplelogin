# VTAppleLogin

**VTAppleLogin** （Sign in with Apple） 苹果登录。

## Usage - VTAppleLogin

导入方式：
```objc
pod 'VTAppleLogin', :git => 'https://github.com/Mickeylit/VTApplelogin.git'
```

相关函数参数说明：
## `keyChainInfo`参数
用于第一次保存苹果登录成功回调的用户数据（建议保存在钥匙串）
注意：第一次验证调用的时候就传入

## `blockLoginSaveKeyChainInfo` 函数
存储用户标识信息需要使用钥匙串来存储（若不存储，无法从钥匙串获取，每次都向苹果服务器获取）

## `blockAppleLoginStateChanged` 函数
SignInWithApple状态改变监听回调（授权状态）




## License

VTAppleLogin is available under the MIT license. See the LICENSE file for more info.
