/********* JCUpdate.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "MainViewController.h"
#import "JCUpdateCore.h"


@interface JCUpdate : CDVPlugin {
    // Member variables go here.
    JCUpdateCore *updateCore;
}

@property(nonatomic, strong) NSString *callbackId;
@property(nonatomic, strong) UIProgressView *progress;

- (void)allUpdate:(CDVInvokedUrlCommand *)command;          //全部更新
- (void)incrementalUpdate:(CDVInvokedUrlCommand *)command;  //增量更新
- (void)debugWeb:(CDVInvokedUrlCommand *)command;           //调试模式

@end

@implementation JCUpdate

-(void)first
{
    //获取当前viewcontroller
    MainViewController *curViewController = [self getCurrentMainViewController];
    
    //下载进度
    self.progress = [[UIProgressView alloc]initWithFrame:CGRectMake(0, 0, 200, 20)];
    //更改进度条高度
    self.progress.transform = CGAffineTransformMakeScale(1.0f,3.0f);
    self.progress.center = curViewController.view.center;
    [self.progress setHidden: YES];
    [curViewController.view addSubview:self.progress];
    
    updateCore = [JCUpdateCore getInstance];
    
    [updateCore debugWeb];                  //执行调试模式
    
    [updateCore pluginInitializeAtWebView:curViewController.webView onCompletion:nil onError:^(NSString *error) {
        [self sendErrorResult:error];
    }];
    
}
//插件初始化
- (void)pluginInitialize {
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(first) userInfo:nil repeats:NO];
}

- (MainViewController *)getCurrentMainViewController
{
    UIViewController *result = nil;
    
    UIWindow *window = [[UIApplication sharedApplication]keyWindow];
    if(window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow *tempWin in windows)
        {
            if(tempWin.windowLevel == UIWindowLevelNormal)
            {
                window = tempWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    //当前的响应者是否属于UIViewController类
    if([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return (MainViewController*)result;
}

//全部更新
- (void)allUpdate:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    self.callbackId = command.callbackId;
    [self.progress setHidden:NO];               //显示进度条
    
    NSString *host = [command.arguments objectAtIndex:0];
    NSString *packPath = [command.arguments objectAtIndex:1];
    
    if ((host != nil && [host length] > 0) && (packPath != nil && [packPath length] > 0)) {
        //        [self downloadData];
        [updateCore onDownloadProgressChanged:^(double progress) {
            self.progress.progress = progress;
        }];
        
        //全部更新
        [updateCore allUpdateAtHost:host packPath:packPath onCompletion:^{
            //完成下载隐藏进度条
            [self.progress setHidden:YES];
            [self sendSuccessResult:nil];
        } onError:^(NSString *error) {
            //完成下载隐藏进度条
            [self.progress setHidden:YES];
            [self sendErrorResult:error];
        }];
    } else {
        [self sendErrorResult:@"url is empty!"];
        return;
    }
    
    
}

//增量更新
- (void)incrementalUpdate:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    self.callbackId = command.callbackId;
    [self.progress setHidden:NO];               //显示进度条
    
    NSString *host = [command.arguments objectAtIndex:0];
    NSString *packPath = [command.arguments objectAtIndex:1];
    
    if (host != nil && [host length] > 0 && (packPath != nil && [packPath length] > 0)) {
        //        [self downloadData];
        [updateCore onDownloadProgressChanged:^(double progress) {
            self.progress.progress = progress;
        }];
        
        //覆盖更新
        [updateCore incrementalUpdateAtHost:host packPath:packPath onCompletion:^{
            //完成下载隐藏进度条
            [self.progress setHidden:YES];
            [self sendSuccessResult:nil];
        } onError:^(NSString *error) {
            //完成下载隐藏进度条
            [self.progress setHidden:YES];
            [self sendErrorResult:error];
        }];
    } else {
        [self sendErrorResult:@"url is empty!"];
        return;
    }
    
    
}

//发送回错误结果给js
-(void)sendErrorResult:(NSString*)msg
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

//发送回成功结果给js
-(void)sendSuccessResult:(NSString*)msg
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (void)debugWeb:(CDVInvokedUrlCommand *)command
{
    if(!updateCore)
        updateCore = [JCUpdateCore getInstance];
    
    [updateCore debugWeb];
}
@end
