//
//  VTAppleLoginManager.h
//  VTAppleLogin
//
//  Created by Billy on 2021/6/30.
//  Copyright © 2021 VTAppleLogin contributors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger,VTAppleLoginManagerType) {
    VTAppleLoginManagerTypeSave = 1,//保存
    VTAppleLoginManagerTypeDelete = 2,//删除
};


@class VTAppleLoginModel;

@interface VTAppleLoginManager : NSObject


+(instancetype)shareManager;

/* 验证回调
 * param keyChainInfo  ->👇blockLoginSaveKeyChainInfo保存在钥匙串的info
 * param model 苹果返回的数据model
 * param isSuccess 是否成功
 * param errorMsg  失败Message
 */
-(void)appleLoginAuthorizationWithKeyChainInfo:(NSString *)keyChainInfo AppleIDFinishBlock:(void(^)(VTAppleLoginModel *model,BOOL isSuccess,NSString *errorMsg))complete;


/* 存储用户标识信息需要使用钥匙串来存储（若不存储，无法从钥匙串获取）
 * param user loginSuccess 返回的唯一user
 * infoType 1 VTAppleLoginManagerTypeSave 保存  2 VTAppleLoginManagerTypeDelete 删除
 * 注意 需要用钥匙串keychain存储方式
 */
@property (nonatomic, copy) void (^blockLoginSaveKeyChainInfo)(NSString *user,VTAppleLoginManagerType infoType);


/*
 * SignInWithApple状态改变监听回调
 */
@property (nonatomic, copy) void (^blockAppleLoginStateChanged)(NSNotification *notication);

@end






@interface VTAppleLoginModel : NSObject

/**  user */
@property (nonatomic,copy) NSString *user;
/**  email */
@property (nonatomic,copy) NSString *email;
/**  familyName */
@property (nonatomic,copy) NSString *familyName;
/**  givenName */
@property (nonatomic,copy) NSString *givenName;
/**  identityToken */
@property (nonatomic,copy) NSString *identityToken;
/**  authorizationCode */
@property (nonatomic,copy) NSString *authorizationCode;
/**  state */
@property (nonatomic,copy) NSString *state;
/**  realUserStatus */
@property (nonatomic,assign) NSInteger realUserStatus;
@end

NS_ASSUME_NONNULL_END
