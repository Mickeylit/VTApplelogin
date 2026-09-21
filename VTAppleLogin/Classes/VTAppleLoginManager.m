//
//  VTAppleLoginManager.m
//  VTAppleLogin
//
//  Created by Billy on 2021/6/30.
//  Copyright © 2021 VTAppleLogin contributors. All rights reserved.
//

#import "VTAppleLoginManager.h"
#import <AuthenticationServices/AuthenticationServices.h>


@interface VTAppleLoginManager () <ASAuthorizationControllerDelegate,ASAuthorizationControllerPresentationContextProviding>

@property (nonatomic,strong) dispatch_semaphore_t appleLoginSemaphore;

@property (nonatomic, copy) void (^blockAppleLoginAuthorization)(VTAppleLoginModel *model,BOOL isSuccess,NSString *errorMsg);

@end

@implementation VTAppleLoginManager


+(instancetype)shareManager
{
    static VTAppleLoginManager *manager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        manager = [[super allocWithZone:NULL]init];
    });
    
    return manager;
}
-(instancetype)init
{
    if (self == [super init]) {
        
        _appleLoginSemaphore = dispatch_semaphore_create(0);

        if(@available(iOS 13.0,*)){
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSignInWithAppleStateChanged:) name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
        }
    }
    return self;
}
-(id)copyWithZone:(NSZone *)zone
{
    return self;
}
+(id)allocWithZone:(struct _NSZone *)zone
{
    return [self shareManager];
}

#pragma mark - Public Method
-(void)appleLoginAuthorizationWithKeyChainInfo:(NSString *)keyChainInfo AppleIDFinishBlock:(void(^)(VTAppleLoginModel *model,BOOL isSuccess,NSString *errorMsg))complete
{
    if(self.blockAppleLoginAuthorization){
        
        NSLog(@"Sign in with AppleID ing...");
        
        return;
    }
    self.blockAppleLoginAuthorization = complete;
    
    __weak __typeof(&*self)weakSelf = self;
    
    [self checkAppIDWithKeyChainInfo:keyChainInfo LoginStateFinish:^(BOOL isGranted) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!isGranted) {
                //移除钥匙串存储
                if(weakSelf.blockLoginSaveKeyChainInfo){
                    weakSelf.blockLoginSaveKeyChainInfo(keyChainInfo,VTAppleLoginManagerTypeDelete);
                }
                
            }
            
            [weakSelf appleLoginAuthorizationRequest];
            
        });
        
        
    }];
    
    
}
#pragma mark - notification 观察SignInWithApple状态改变
-(void)handleSignInWithAppleStateChanged:(NSNotification *)blockAppleLoginStateChanged
{
    if(_blockAppleLoginStateChanged){
        _blockAppleLoginStateChanged(blockAppleLoginStateChanged);
    }
}
#pragma mark - pravite method
-(void)checkAppIDWithKeyChainInfo:(NSString *)keyChainInfo LoginStateFinish:(void(^)(BOOL isGranted))complete
{
    if (@available(iOS 13.0, *)) {
        
        if (keyChainInfo.length>0) {
            ASAuthorizationAppleIDProvider * appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
            [appleIDProvider getCredentialStateForUserID:keyChainInfo
                                              completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState, NSError * _Nullable error) {
                switch (credentialState) {
                    case ASAuthorizationAppleIDProviderCredentialAuthorized:
                        // 授权状态有效
                        complete(YES);
                        break;
                    case ASAuthorizationAppleIDProviderCredentialRevoked:
                        // 苹果账号登录的凭据已被移除，需解除绑定并重新引导用户使用苹果登录
                        complete(NO);
                        break;
                    case ASAuthorizationAppleIDProviderCredentialNotFound:
                        // 未登录授权，直接弹出登录页面，引导用户登录
                        complete(NO);
                        break;
                    case ASAuthorizationAppleIDProviderCredentialTransferred:
                        // 授权AppleID提供者凭据转移
                        complete(NO);
                        break;
                    default:
                        complete(NO);
                        break;
                }
            }];
        }else{
            
            complete(YES);
        }
    }
    
}
-(void)appleLoginAuthorizationRequest
{
    
    if (@available(iOS 13.0,*)) {
        
        // 基于用户的Apple ID授权用户，生成用户授权请求的一种机制
        ASAuthorizationAppleIDProvider *appleIDProvider = [[ASAuthorizationAppleIDProvider alloc]init];
        // 创建新的AppleID 授权请求
        ASAuthorizationAppleIDRequest *authAppleIDRequest = [appleIDProvider createRequest];
        authAppleIDRequest.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
        NSMutableArray<ASAuthorizationRequest *>*arry = [NSMutableArray arrayWithCapacity:1];
        
        if (authAppleIDRequest) {
            [arry addObject:authAppleIDRequest];
        }
        NSArray <ASAuthorizationRequest *>* requests = [arry copy];
        // 由ASAuthorizationAppleIDProvider创建的授权请求 管理授权请求的控制器
        ASAuthorizationController * authorizationController = [[ASAuthorizationController alloc] initWithAuthorizationRequests:requests];
        authorizationController.delegate = self;
        authorizationController.presentationContextProvider = self;
        // 在控制器初始化期间启动授权流
        [authorizationController performRequests];
        
        
    }else{
        //系统不支持Apple登录
        [self loginAuthorizationWithState:NO errorMsg:@"设备系统版本太低不支持Apple登录" AndModel:nil];
        
    }
}
-(void)loginAuthorizationWithState:(BOOL)isSuccess errorMsg:(NSString *)errorMsg AndModel:(VTAppleLoginModel *)model
{
    if (self.blockAppleLoginAuthorization) {
        self.blockAppleLoginAuthorization(model,isSuccess,errorMsg);
    }
    self.blockAppleLoginAuthorization = NULL;
}
#pragma mark- ASAuthorizationControllerDelegate
// 授权成功
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization  API_AVAILABLE(ios(13.0)){
   
    if ([authorization.credential isKindOfClass:[ASAuthorizationAppleIDCredential class]]) {
       
        ASAuthorizationAppleIDCredential * credential = authorization.credential;
        // 苹果用户唯一标识符，该值在同一个开发者账号下的所有 App 下是一样的，开发者可以用该唯一标识符与自己后台系统的账号体系绑定起来。
        NSString * userID = credential.user;
        // 使用过授权的，可能获取不到以下三个参数
        NSPersonNameComponents * fullName = credential.fullName;
        NSString *familyName = fullName.familyName;
        NSString *givenName = fullName.givenName;
        NSString *email = credential.email;
        // 服务器验证需要使用的参数
        NSString * authorizationCode = [[NSString alloc] initWithData:credential.authorizationCode encoding:NSUTF8StringEncoding];
        NSString * identityToken = [[NSString alloc] initWithData:credential.identityToken encoding:NSUTF8StringEncoding];
        // 用于判断当前登录的苹果账号是否是一个真实用户，取值有：unsupported、unknown、likelyReal
        ASUserDetectionStatus realUserStatus = credential.realUserStatus;
        
        VTAppleLoginModel *model = [[VTAppleLoginModel alloc]init];
        model.user = userID;
        model.email = email;
        model.familyName = familyName;
        model.givenName = givenName;
        model.authorizationCode = authorizationCode;
        model.identityToken = identityToken;
        model.realUserStatus = realUserStatus;
        
        [self loginAuthorizationWithState:YES errorMsg:@"" AndModel:model];
        
        //保存到钥匙串
        if(_blockLoginSaveKeyChainInfo){
            _blockLoginSaveKeyChainInfo(userID,VTAppleLoginManagerTypeSave);
        }
        
    } else {
        
        [self loginAuthorizationWithState:NO errorMsg:@"授权信息不符" AndModel:nil];
        
    }
}
// 授权失败
- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error  API_AVAILABLE(ios(13.0)){
    NSString *errorMsg = nil;
    switch (error.code) {
        case ASAuthorizationErrorCanceled:
            errorMsg = @"用户取消了授权请求";
            break;
        case ASAuthorizationErrorFailed:
            errorMsg = @"授权请求失败";
            break;
        case ASAuthorizationErrorInvalidResponse:
            errorMsg = @"授权请求响应无效";
            break;
        case ASAuthorizationErrorNotHandled:
            errorMsg = @"未能处理授权请求";
            break;
        case ASAuthorizationErrorUnknown:
            errorMsg = @"授权请求失败（请检查一下AppID是否授权）";
            break;
        default:
            errorMsg = @"授权未知错误";
            break;
    }
    [self loginAuthorizationWithState:NO errorMsg:errorMsg AndModel:nil];
    
    self.blockAppleLoginAuthorization = NULL;
}
#pragma mark- ASAuthorizationControllerPresentationContextProviding
//主要是告诉 ASAuthorizationController 在哪个 window 上显示
- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller  API_AVAILABLE(ios(13.0)){
    return [UIApplication sharedApplication].keyWindow;
}
#pragma mark - remove noticaiton
- (void)dealloc {
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:ASAuthorizationAppleIDProviderCredentialRevokedNotification object:nil];
    }
}
@end





@implementation VTAppleLoginModel

@end
