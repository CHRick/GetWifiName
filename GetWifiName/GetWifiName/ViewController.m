//
//  ViewController.m
//  GetWifiName
//
//  Created by chencancan on 2022/2/23.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController ()<CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *wifiNameLable;
@property (weak, nonatomic) IBOutlet UITextField *apName;
@property (weak, nonatomic) IBOutlet UITextField *psdTextField;
@property (nonatomic, strong) CLLocationManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
}

- (IBAction)getWifiName:(UIButton *)sender {
    [self getWiFiName];
}

- (IBAction)connectAP:(UIButton *)sender {
    [self connectDeviceWifi];
}

- (NSString*)getWiFiName {
    
    if (@available(iOS 13.0, *)) {
        //用户明确拒绝，可以弹窗提示用户到设置中手动打开权限
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            [self showJumpSettingTip:@"定位权限未打开"
                             message:@"应用需要打开定位权限后才能获取到手机连接的Wi-Fi名称"
                         ensureTitle:@"前往设置"];
            return nil;
        }
        if (!self.manager) {
            self.manager = [[CLLocationManager alloc] init];
            self.manager.delegate = self;
        }
        if(![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            //弹框提示用户是否开启位置权限
            [self.manager requestWhenInUseAuthorization];
            sleep(1);
            //递归等待用户选选择
            return nil;
        }
    }
    NSString *wifiName = nil;
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    if (!wifiInterfaces) {
        return nil;
    }
    NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
    for (NSString *interfaceName in interfaces) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));
        
        if (dictRef) {
            NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
            NSLog(@"network info -> %@", networkInfo);
            wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            CFRelease(dictRef);
        }
    }
    
    CFRelease(wifiInterfaces);
    return wifiName;
}

- (void)showJumpSettingTip:(NSString *)title
                   message:(NSString *)message
               ensureTitle:(NSString *)ensureTitle {
    
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:ensureTitle
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
        
        NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            
        }];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    
    if (manager.authorizationStatus != kCLAuthorizationStatusNotDetermined) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.wifiNameLable.text = [weakSelf getWiFiName];
            if (!self.wifiNameLable.text || self.wifiNameLable.text.length <= 0) {
                [weakSelf showJumpSettingTip:@"请先连接路由器Wi-Fi"
                                     message:@"该Wi-Fi将用于设备工作，您可以到手机”设置“中连接Wi-Fi网络。"
                                 ensureTitle:@"去连接Wi-Fi"];
            }
        });
    }
}

- (void)connectDeviceWifi {
    
    NSString *deviceWifiName = self.apName.text;
    NEHotspotConfigurationManager *manager = [NEHotspotConfigurationManager sharedManager];
    NSString *password = self.psdTextField.text;
    NEHotspotConfiguration *config = [[NEHotspotConfiguration alloc] initWithSSID:deviceWifiName
                                                                       passphrase:password
                                                                            isWEP:NO];
    [manager applyConfiguration:config completionHandler:^(NSError * _Nullable error) {
        
        if (error) {
            
        }else {
            NSString *wifiName = [self getWiFiName];
            if ([wifiName isEqualToString:deviceWifiName]) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self performSegueWithIdentifier:@"AddDeviceWiFiInfoVC2AddDeviceWiFiConfigVC" sender:nil];
                });
            }
        }
    }];
}

@end
