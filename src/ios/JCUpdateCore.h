//
//  JCUpdateCore.h
//  JCUpdateCore
//
//  Created by JC on 15/11/26.
//  Copyright © 2015年 JC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCUpdateCore : NSObject
+ (JCUpdateCore*)getInstance;
//全部更新
- (void)allUpdateAtHost:(NSString*)host packPath:(NSString*)packPath onCompletion:(void (^)())completion onError:(void(^)(NSString* error))error;
//增量更新
- (void)incrementalUpdateAtHost:(NSString*)host packPath:(NSString*)packPath onCompletion:(void (^)())completion onError:(void(^)(NSString* error))error;
//初始化
- (void)pluginInitializeAtWebView:(UIWebView*)webView onCompletion:(void (^)())completion onError:(void(^)(NSString* error))error;
//下载进度
- (void)onDownloadProgressChanged:(void (^)(double progress))progress;
//调试模式
- (void)debugWeb;
@end
