//
//  KSYRTCKitDemoVC.m
//  KSYGPUStreamerDemo
//
//  Created by yiqian on 6/23/16.
//  Copyright © 2016 ksyun. All rights reserved.
//
#import "KSYStreamerVC.h"
#import <libksyrtclivedy/KSYRTCStreamerKit.h>
#import <libksyrtclivedy/KSYRTCStreamer.h>

#import <libksygpuliveDy/libksygpuimage.h>
#import <libksygpuliveDy/KSYGPUStreamerKit.h>
#import "KSYRTCKitDemoVC.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
@interface KSYRTCKitDemoVC () {
    id _filterBtn;
    UILabel* label;
    NSDateFormatter * _dateFormatter;
    int64_t _seconds;
    bool _ismaster;
    
    UIPanGestureRecognizer *panGestureRecognizer;
    UIView* _winRtcView;
}

@end

@implementation KSYRTCKitDemoVC

#pragma mark - UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    _kit = [[KSYRTCStreamerKit alloc] initWithDefaultCfg];
    // 获取streamerBase, 方便进行推流相关操作, 也可以直接 _kit.streamerBase.xxx
    self.streamerBase = _kit.streamerBase;
    // 采集相关设置初始化
    [self setCaptureCfg];
    //推流相关设置初始化
    [self setStreamerCfg];
    //设置rtc参数
    [self setRtcSteamerCfg];
    
    //设置拖拽手势
    panGestureRecognizer=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    CGRect rect;
    rect.origin.x = _kit.winRect.origin.x * self.view.frame.size.width;
    rect.origin.y = _kit.winRect.origin.y * self.view.frame.size.height;
    rect.size.height =_kit.winRect.size.height * self.view.frame.size.height;
    rect.size.width =_kit.winRect.size.width * self.view.frame.size.width;
    
    _winRtcView =  [[UIView alloc] initWithFrame:rect];
    _winRtcView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_winRtcView];
    [self.view bringSubviewToFront:_winRtcView];
    [_winRtcView addGestureRecognizer:panGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.ctrlView.btnQuit setTitle: @"退出kit"
                           forState: UIControlStateNormal];
    [self.ksyMenuView.rtcBtn setHidden:NO];
    if (_kit) {
        // init with default filter
        [_kit setupFilter:self.ksyFilterView.curFilter];
        [_kit startPreview:self.view];
    }
}

- (void) setCaptureCfg {
    _kit.capPreset = [self.presetCfgView capResolution];
    _kit.videoFPS       = [self.presetCfgView frameRate];
    _kit.cameraPosition = [self.presetCfgView cameraPos];
    _kit.videoProcessingCallback = ^(CMSampleBufferRef buf){
    };
}

#pragma mark -  state change
- (void)onTimer:(NSTimer *)theTimer{
    [super onTimer:theTimer];
    _seconds++;
    if (_seconds%5){ // update label every 5 second
        UIApplicationState appState = [UIApplication sharedApplication].applicationState;
        if(appState == UIApplicationStateActive){
            NSDate *now = [[NSDate alloc] init];
//            _kit.textLable.text = [_dateFormatter stringFromDate:now];
//            [_kit updateTextLable];
        }
    }
}

- (void) onFlash {
    [_kit toggleTorch];
}

- (void) onCameraToggle{
    [_kit switchCamera];
    [super onCameraToggle];
}

- (void) onCapture{
    if (!_kit.vCapDev.isRunning){
        [_kit startPreview:self.view];
    }
    else {
        [_kit stopPreview];
    }
}
- (void) onStream{
    if (_kit.streamerBase.streamState == KSYStreamStateIdle ||
        _kit.streamerBase.streamState == KSYStreamStateError) {
        [_kit.streamerBase startStream:self.hostURL];
        self.streamerBase = _kit.streamerBase;
        _seconds = 0;
    }
    else {
        [_kit.streamerBase stopStream];
        self.streamerBase = nil;
    }
}


- (void) onQuit{  // quit current demo
    [_kit.streamerBase stopStream];
    self.streamerBase = nil;
    
    [_kit stopPreview];
    [_kit stopRTCView];
    if(_kit.rtcSteamer)
    {
        [_kit.rtcSteamer stopCall];
        [_kit.rtcSteamer unRegisterRTC];
        _kit.rtcSteamer = nil;
    }
    _kit = nil;
    [super onQuit];
}

- (void) onFilterChange:(id)sender{
    if (self.ksyFilterView.curFilter != _kit.filter){
        // use a new filter
        [_kit setupRtcFilter:self.ksyFilterView.curFilter];
    }
}

#pragma mark - UIViewController
- (void) setRtcSteamerCfg {
    //设置ak/sk鉴权信息,本demo从testAppServer取，客户请从自己的appserver获取。
    _kit.rtcSteamer.authString = nil;
    //设置域名查询domain，内部使用
    _kit.rtcSteamer.queryDomainString = @"http://rtc.vcloud.ks-live.com:6000/querydomain";
    //设定公司后缀
    _kit.rtcSteamer.uniqName = @"apptest";
    //设置音频采样率
    _kit.rtcSteamer.sampleRate = 44100;
    //设置视频帧率
    _kit.rtcSteamer.videoFPS = 15;
    //是否打开rtc的日志
    _kit.rtcSteamer.openRtcLog = YES;
    //设置对端视频的宽高
    _kit.rtcSteamer.scaledWidth = 180;
    _kit.rtcSteamer.scaledHeight = 320;
    //设置rtc传输的码率
    _kit.rtcSteamer.AvgBps = 256000;
    _kit.rtcSteamer.MaxBps = 256000;
    //设置信令传输模式,tls为推荐
    _kit.rtcSteamer.rtcMode = 1;
    //设置小窗口的大小和显示
    _kit.winRect = CGRectMake(0.6, 0.6, 0.3, 0.3);
    
    __weak KSYRTCKitDemoVC *weak_demo = self;
    __weak KSYRTCStreamerKit *weak_kit = _kit;
    _kit.rtcSteamer.onRegister= ^(int status){
        NSString * message = [NSString stringWithFormat:@"local sip account:%@",weak_kit.rtcSteamer.authUid];
        [weak_demo statString:message];
        [weak_demo statEvent:@"register callback" result:status];
    };
    _kit.rtcSteamer.onUnRegister= ^(int status){
        [weak_demo statEvent:@"unregister callback" result:status];
        NSLog(@"unregister callback");
    };
    _kit.rtcSteamer.onCallInComing =^(char* remoteURI){
        NSString *text = [NSString stringWithFormat:@"有呼叫到来,id:%s",remoteURI];
        [weak_demo statEvent:text result:0];
        [weak_demo onRtcAnswerCall];
    };
    
    _kit.onCallStart =^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                [weak_demo statEvent:@"建立连接," result:status];
            }
        }
        else if(status == 408){
            [weak_demo statEvent:@"对方无应答," result:status];
            [weak_kit stopRTCView];
        }
        else if(status == 404){
            [weak_demo statEvent:@"呼叫未注册号码,主动停止" result:status];
        }
        NSLog(@"oncallstart:%d",status);
    };
    _kit.onCallStop = ^(int status){
        if(status == 200)
        {
            if([UIApplication sharedApplication].applicationState !=UIApplicationStateBackground)
            {
                [weak_demo statEvent:@"断开连接," result:status];
            }
        }
        else if(status == 408)
        {
            [weak_demo statEvent:@"408超时" result:status];
            [weak_kit stopRTCView];
        }
        NSLog(@"oncallstop:%d",status);
    };
    _ismaster = NO;
}


-(void)statEvent:(NSString *)event
          result:(int)ret
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.ctrlView.lblStat.text.length > 100)
            self.ctrlView.lblStat.text= @"";
        NSString *text = [NSString stringWithFormat:@"\n%@, ret:%d",event,ret];
        self.ctrlView.lblStat.text = [ self.ctrlView.lblStat.text  stringByAppendingString:text  ];
        
    });
}
-(void)statString:(NSString *)event
{
    if(self.ctrlView.lblStat.text.length > 100)
        self.ctrlView.lblStat.text= @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = [NSString stringWithFormat:@"\n%@",event];
        self.ctrlView.lblStat.text = [ self.ctrlView.lblStat.text  stringByAppendingString:text  ];
    });
}


-(void)onMasterChoosed:(BOOL)isMaster{
    _ismaster = isMaster;
    if(isMaster)
    {
        [self statEvent:@"主播" result:0];
        //主播小窗口看到的是对端
        _kit.selfInFront = NO;
    }
    else{
        [self statEvent:@"辅播" result:0];
        //辅播小窗口看到的是自己
        _kit.selfInFront = YES;
    }
}

- (void)onRtcRegister:(NSString *)localid
{
    _kit.rtcSteamer.localId = localid;
    
    NSString * TestASString;
    if(![self checkNetworkReachability:AF_INET6])
    {
    //获取鉴权串，demo里为testAppServer，请改用自己的appserver
    TestASString = [NSString stringWithFormat:@"http://120.132.89.26:6001/rtcauth?uid=%@",localid];
    _kit.rtcSteamer.authString=[NSString stringWithFormat:@"https://rtc.vcloud.ks-live.com:6001/auth?%@",
                                    [self AuthFromTestAS:TestASString]];
    }
    else{
    TestASString = @"accesskey=D8uDWZ88ZKW48/eZHmRm&expire=1474713034&nonce=CnhQKCkGZ5DnSvYwtz2uhjb0j599E1e7&uid=330&uniqname=apptest&signature=tndMoVqr0nq3fsFM2iEUNwBw1h8%3D";
        _kit.rtcSteamer.authString=[NSString stringWithFormat:@"https://rtc.vcloud.ks-live.com:6001/auth?%@",TestASString];
    }

    [_kit.rtcSteamer registerRTC];
}

- (void)onRtcStartCall:(NSString *)remoteid{
    
    int ret = [_kit.rtcSteamer startCall:remoteid];
    
    NSString * event = [NSString stringWithFormat:@"发起呼叫,remote_id:%@",remoteid];
    [self statEvent:event result:ret];
}
- (void)onRtcAnswerCall{
    int ret = [_kit.rtcSteamer answerCall];
    [self statEvent:@"应答" result:ret];
}
- (void)onRtcUnregister{
    int ret = [_kit.rtcSteamer unRegisterRTC];
    
    [self statEvent:@"unregister" result:ret];
}

- (void)onRtcRejectCall{
    int ret = [_kit.rtcSteamer rejectCall];
    [self statEvent:@"reject" result:ret];
}
- (void)onRtcStopCall{
    int ret = [_kit.rtcSteamer stopCall];
    [self statEvent:@"stopcall" result:ret];
   }

-(NSString *)AuthFromTestAS:(NSString *)ServerIp
{
    NSURLResponse *response = nil;
    NSError *error = nil;
    //http请求消息
    NSURL *requestURL = [NSURL URLWithString:ServerIp];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:requestURL];
    //发送同步请求
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    //处理http响应消息
    if(error)
    {
        NSLog(@"testAppServer fail, error = %@", error);
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

-(void) onSwitchRtcView:(CGPoint)location
{
    CGRect winrect = _kit.winRect;
    
    //只有小窗口点击才会切换窗口
    if((location.x > winrect.origin.x && location.x <winrect.origin.x +winrect.size.width) &&
        (location.y > winrect.origin.y && location.y <winrect.origin.y +winrect.size.height))
    {
        _kit.selfInFront = !_kit.selfInFront;
    }
}

-(void)panAction:(UIPanGestureRecognizer *)sender
{
    //获取手势在屏幕上拖动的点
    
    CGPoint translatedPoint = [panGestureRecognizer translationInView:self.view];
    
    panGestureRecognizer.view.center = CGPointMake(panGestureRecognizer.view.center.x + translatedPoint.x, panGestureRecognizer.view.center.y + translatedPoint.y);
    
    CGRect newWinRect;
    newWinRect.origin.x = (panGestureRecognizer.view.center.x - panGestureRecognizer.view.frame.size.width/2)/self.view.frame.size.width;
    newWinRect.origin.y = (panGestureRecognizer.view.center.y - panGestureRecognizer.view.frame.size.height/2)/self.view.frame.size.height;
    newWinRect.size.height = _kit.winRect.size.height;
    newWinRect.size.width = _kit.winRect.size.width;
    _kit.winRect = newWinRect;
    [panGestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (BOOL)checkNetworkReachability:(sa_family_t)sa_family {
    //www.apple.com - IPv4: 125.252.236.67 - IPv6: 64:ff9b::7dfc:ec43
    static unsigned char ipv4_addr[4] = {125, 252, 236, 67};
    static unsigned char ipv6_addr[16] = {0x00, 0x64, 0xff, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7d, 0xfc, 0xec, 0x43};
    
    struct sockaddr *pZeroAddress = nil;
    struct sockaddr_in zeroSockaddrin;
    struct sockaddr_in6 zeroSockaddrin6;
    if (AF_INET == sa_family) {
        bzero(&zeroSockaddrin, sizeof(zeroSockaddrin));
        bcopy(ipv4_addr, &zeroSockaddrin.sin_addr, sizeof(zeroSockaddrin.sin_addr));
        zeroSockaddrin.sin_len = sizeof(zeroSockaddrin);
        zeroSockaddrin.sin_family = AF_INET;
        pZeroAddress = (struct sockaddr *)&zeroSockaddrin;
    } else if (AF_INET6 == sa_family) {
        bzero(&zeroSockaddrin6, sizeof(zeroSockaddrin6));
        bcopy(ipv6_addr, &zeroSockaddrin6.sin6_addr, sizeof(zeroSockaddrin6.sin6_addr));
        zeroSockaddrin6.sin6_len = sizeof(zeroSockaddrin6);
        zeroSockaddrin6.sin6_family = AF_INET6;
        pZeroAddress = (struct sockaddr *)&zeroSockaddrin6;
    }
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, pZeroAddress);
    SCNetworkReachabilityFlags flags;
    if (!defaultRouteReachability) {
        return NO;
    }
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags) {
        return NO;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL isLocalAddress = flags & kSCNetworkFlagsIsLocalAddress;
    BOOL isDirect = flags & kSCNetworkFlagsIsDirect;
    return (isReachable && !isLocalAddress && !isDirect) ? YES : NO;
}


@end