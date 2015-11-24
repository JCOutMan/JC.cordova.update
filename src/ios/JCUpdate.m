/********* update.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "MKNetworkKit/MKNetworkKit.h"
#import "SSZipArchive/SSZipArchive.h"
#import "MainViewController.h"


@interface update : CDVPlugin {
    // Member variables go here.
}

@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSString *callbackId;
@property(nonatomic, strong) MainViewController *curViewController;
@property(nonatomic, strong) UIProgressView *progress;
@property(nonatomic, strong) NSString *docDirectoryPath;
@property(nonatomic, strong) NSString *docWWWPath;
@property(nonatomic, strong) NSString *appWWWPath;
@property(nonatomic, strong) NSString *appPath;
@property(nonatomic) BOOL initOK;
@property(nonatomic, strong) NSString *failMsg;

- (void)update:(CDVInvokedUrlCommand *)command;
@end

@implementation update

-(void)first
{
    self.initOK = true;
    //获取当前viewcontroller
    self.curViewController = [self getCurrentMainViewController];
    
    //下载进度
    self.progress = [[UIProgressView alloc]initWithFrame:CGRectMake(0, 0, 200, 20)];
    //更改进度条高度
    self.progress.transform = CGAffineTransformMakeScale(1.0f,3.0f);
    self.progress.center = self.curViewController.view.center;
    [self.progress setHidden: YES];
    [self.curViewController.view addSubview:self.progress];
    
    //获取doc路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.docDirectoryPath = paths[0];
    self.docWWWPath = [self.docDirectoryPath stringByAppendingPathComponent:@"www"];
    
    //获取当前app包内容中www路径
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *appPath = [mainBundle bundlePath];
    self.appPath = appPath;
    self.appWWWPath = [appPath stringByAppendingPathComponent:@"www"];
    
    //将www文件夹压缩复制到doc文件夹
    NSFileManager *manager = [NSFileManager defaultManager];

    
    //判断doc目录下www文件夹是否存在,不存在则将app/www复制
    if(![manager fileExistsAtPath:self.docWWWPath])
    {
        NSLog(@"folder not exists or don't read");
        //压缩app/www后复制到doc/
        if(![self createZipFileAtPath:self.appWWWPath])
        {
            NSString *msg = @"初始化压缩www失败";
            NSLog(msg);
            self.failMsg = msg;
            self.initOK = false;
            return;
        }else{
            //压缩并复制成功,解压www.zip后重新加载index.html
            NSString *docWWWZip = [self.docWWWPath stringByAppendingString:@".zip"];
            if([self unzipFileAtPath:docWWWZip toDestination:self.docWWWPath])
            {
                NSString *index = [self.docDirectoryPath stringByAppendingPathComponent:@"www/index.html"];
                NSURL *localUrl = [NSURL URLWithString:index];
                NSURLRequest *request = [NSURLRequest requestWithURL:localUrl];
                [self.curViewController.webView stopLoading];
                [self.curViewController.webView loadRequest:request];
                
            }else{
                NSString *msg = @"初始化解压www.zip失败";
                NSLog(msg);
                self.failMsg = msg;
                self.initOK = false;
                
            }
        }
        
    
    }else{
        NSString *index = [self.docDirectoryPath stringByAppendingPathComponent:@"www/index.html"];
        NSURL *localUrl = [NSURL URLWithString:index];
        NSURLRequest *request = [NSURLRequest requestWithURL:localUrl];
        [self.curViewController.webView stopLoading];
        [self.curViewController.webView loadRequest:request];
        
    }
    
    
}
//插件初始化
- (void)pluginInitialize {
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(first) userInfo:nil repeats:NO];
}

//下载数据
- (void *)downloadData
{
    //下载文件后的本地路径
    NSString *downloadPath = [self.docDirectoryPath stringByAppendingPathComponent:@"www.zip"];
    
    NSString *path = @"/www.zip";
    path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //    MKNetworkEngine *engine = [[MKNetworkEngin] alloc];
    MKNetworkEngine *engine = [[MKNetworkEngine alloc] initWithHostName:self.url
                                                     customHeaderFields:nil];
    MKNetworkOperation *downloadOperation = [engine operationWithPath:path params:nil httpMethod:@"POST"];
    
    //增加下载流
    [downloadOperation addDownloadStream:[NSOutputStream outputStreamToFileAtPath:downloadPath append:NO]];
    //监听下载进度
    [downloadOperation onDownloadProgressChanged:^(double progress) {
        
        NSLog(@"download progress: %.2f%%", progress*100);
        self.progress.progress = progress;
    }];
    
    //添加完成处理
    [downloadOperation onCompletion:^(MKNetworkOperation *completedOperation) {
        NSLog(@"download file finished!");
        NSData *data = [completedOperation responseData];
        [self.progress setHidden:YES];
        
        if(data)
        {
            //返回数据失败
            NSError *error;
            NSDictionary *resDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            if(resDict)
            {
                NSString *resultCodeObj = [resDict objectForKey:@"ResultCode"];
                
                NSLog(@"error msg:%@", resultCodeObj);
                NSString *retMsg = [NSString stringWithFormat:@"download error,code:%@", resultCodeObj];
                [self sendErrorResult:retMsg];
            }else{
                [self sendErrorResult:@"download unknown error"];
            }
        }else{
            //成功返回数据
            //先删除原来的www文件夹再解压数据
//            NSFileManager *manager = [NSFileManager defaultManager];
//            if([manager fileExistsAtPath:self.docWWWPath])
//            {
//                [manager removeItemAtPath:self.docWWWPath error:nil];
//            }
            //解压数据
            if([self unzipFileAtPath:downloadPath toDestination:self.docDirectoryPath  ])
                //            if(true)
            {
                //更新完成回调通知
                [self sendSuccessResult:@"update success"];
                
                
                //                MainViewController *vc = [self getCurrentMainViewController];
                //                [vc.webView reload];
            }else{
                NSLog(@"解压失败");
                [self sendErrorResult:@"unzip error!"];
            }
        }
    } onError:^(NSError *error) {
        [self.progress setHidden:YES];
        NSLog(@"MKNetwork请求错误:%@", error);
        NSString *msg = [NSString stringWithFormat:@"request error,code:%@", error];
        [self sendErrorResult:msg];
    }];
    
    //启动队列
    [engine enqueueOperation:downloadOperation];
}

//压缩数据恢复
- (BOOL)createZipFileAtPath:(NSString *)path
{
    NSString *wwwZip = [self.docDirectoryPath stringByAppendingPathComponent:@"www.zip"];
    return [SSZipArchive createZipFileAtPath:wwwZip withContentsOfDirectory:path];
}

//解压数据
- (BOOL)unzipFileAtPath:(NSString*)path toDestination:(NSString*)unzipPath
{
    return [SSZipArchive unzipFileAtPath:path toDestination:unzipPath];
    
    
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

- (void)update:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    self.callbackId = command.callbackId;
    [self.progress setHidden:NO];
    
    if(!self.init)
    {
        //初始化失败
        [self sendErrorResult:self.failMsg];
        return;
    }
    
    self.url = [command.arguments objectAtIndex:0];
    
    if (self.url != nil && [self.url length] > 0) {
        [self downloadData];
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
@end
