//
//  ViewController.m
//  Beacon
//
//  Created by Christopher Ching on 2014-04-27.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//

#import "ViewController.h"
#import "PulsingHaloLayer.h"

#define kMaxRadius 160

@interface ViewController () {
    
    int btn;
}

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLBeaconRegion *beaconRegion;
// Beacon
@property (weak, nonatomic) IBOutlet UIImageView *beaconView;

@property (nonatomic, strong) PulsingHaloLayer *halo;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // ボタン初期値
    btn = 1;
    
    // 背景に画像をセット
    UIImage *image = [UIImage imageNamed:@"bg01"];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    [[_statusLabel layer] setBorderColor:[[UIColor greenColor] CGColor]]; // 枠線の色
    [[_statusLabel layer] setBorderWidth:1.0]; // 枠線の太さ
    [[_statusLabel layer] setCornerRadius:10.0]; // 枠線を角丸
    [_statusLabel setClipsToBounds:YES]; // 枠線を角丸
    
    // Create a NSUUID object
    // 生成したUUIDから送信NSUUIDオブジェクトを作成します。送受信同じNSUUID
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"A77A1B68-49A7-4DBF-914C-760D07FBB87B"];
    
    // Initialize the Beacon Region
    // ビーコン領域を初期化します Region:領域、範囲
    self.myBeaconRegion = [[CLBeaconRegion alloc]
                           initWithProximityUUID:uuid
                                            major:1
                                            minor:1
                                        identifier:@"com.appcoda.testregion"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// [発信]ボタンを押した時
- (IBAction)btStat:(id)sender {
    
    // Statボタン２度押し禁止
    if (btn == 1) {
        
        // Get the beacon data to advertise
        // ビーコンデータを広告することを得る peripheral:周辺 With:共に Measured:測定された
        self.myBeaconData = [self.myBeaconRegion peripheralDataWithMeasuredPower:nil];
        
        // Start the peripheral manager
        // 周辺マネージャを起動します
        self.peripheralManager = [[CBPeripheralManager alloc]
                                  initWithDelegate:self queue:nil  // 待ち行列
                                  options:nil];
        // パルス波形表示設定
        [self puls:1];
        
        // UUIDの表示
        NSString *lbuuid = self.myBeaconRegion.proximityUUID.UUIDString;
        self.lbUUID.text = [NSString stringWithFormat:@"UUID: %@", lbuuid];
        
        btn = 0;
    }
}

/*
// 領域から出ると呼ばれる
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"Exit Region"];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}
*/

// [停止]ボタンを押した時
- (IBAction)btStop:(id)sender {
    
    if (btn == 0) {
        // パルス波形表示設定
        [self puls:0];
        
        self.lbUUID.text = nil;
        
        // BLEアドバタイズ停止処理
        [self.peripheralManager stopAdvertising];

        btn = 1;
    }
}

// iBeacon（周辺機器）のモニター（アップデート状態）判定
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager*)peripheral
{
    // iBeaconの状態判定
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        
        self.statusLabel.text = @"発信中";
        self.statusLabel.textColor = [UIColor greenColor];
        
        // パルス波形表示設定
        //[self puls:1];
        
        // BLEアドバタイズ開始処理 Beaconとして動作
        [self.peripheralManager startAdvertising:self.myBeaconData];
    }
    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
    {
        
        self.statusLabel.text = @"停止中";
        self.statusLabel.textColor = [UIColor redColor];

        // パルス波形非表示設定
        [self puls:0];
        
        // BLEアドバタイズ停止処理
        [self.peripheralManager stopAdvertising];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnsupported)
    {
        // "Unsupported" 発信されていない
        self.statusLabel.text = @"発信されていない";
    }
}

// iBeacon監視状態知らせてくれるように要求
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    //[self sendLocalNotificationForMessage:@"Start Monitoring Region"];
    
    // iOS7から追加された”CLLocationManager requestStateForRegion:”を呼び出し、現在自分が、iBeacon監視でどういう状態にいるかを知らせてくれるように要求します。
    [self.locationManager requestStateForRegion:self.beaconRegion];
}

// 領域に関する状態を取得する
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    /*
     CLRegionStateInside が渡ってきていれば、すでになんらかのiBeaconのリージョン内にいるので、iOS7から
     追加された”CLLocationManager startRangingBeaconsInRegion:”を呼び、通知の受け取りを開始します。
     */
    switch (state) {
        case CLRegionStateInside: // リージョン内にいる
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
            }
            break;
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    //[self sendLocalNotificationForMessage:@"Enter Region"];
    
    // あとは、リージョンの境界を越えて入った時にも同じく通知を開始するようにします。
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}

// iBeaconパルス波形表示設定　引数１つ半径 arg01(ON:1 OFF:0)
- (void)puls:(int)arg01 {
    
    // arg01(ON:1 OFF:0)
    if (arg01 == 1) {
        
        // プロパティに所望の値をセットすれば、半径が変わります。
        self.halo = [PulsingHaloLayer layer];
        
        self.beaconView.hidden = NO; //表示にする
        // Beacon
        self.halo.position = self.beaconView.center;
        
        [self.view.layer insertSublayer:self.halo below:self.beaconView.layer];
        
        self.halo.radius = 1.0;
        
        // Beacon ON:1
        self.halo.radius = 1.0 * kMaxRadius;
        
        // 色を変える
        UIColor *color = [UIColor colorWithRed:0.6    // 0
                                         green:0.0    // 0.487
                                          blue:0.5    // 1.0
                                         alpha:1.0];
        
        self.halo.backgroundColor = color.CGColor;
        
    } else {
        
        //self.beaconView.hidden = YES; //非表示にする
        self.halo.backgroundColor = nil; //非表示にする
        self.statusLabel.text = @"停止中";
        self.statusLabel.textColor = [UIColor redColor];
    }
    
}

- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


@end
