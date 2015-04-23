//
//  ViewController.m
//  Pizza
//
//  Created by James Kong on 23/4/15.
//  Copyright (c) 2015 James Kong. All rights reserved.
//

#import "ViewController.h"
#import "LGBLuetooth.h"
#import "Pizza.h"
static NSString * const PizzaServiceUUID = @"13333333-3333-3333-3333-333333333337";
static NSString * const PizzaCrustCharacteristicUUID = @"13333333-3333-3333-3333-333333330001";
static NSString * const PizzaToppingsCharacteristicUUID = @"13333333-3333-3333-3333-333333330002";
static NSString * const PizzaBakeCharacteristicUUID = @"13333333-3333-3333-3333-333333330003";
@interface ViewController ()<PizzaDelegate>
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property(strong,nonatomic) LGPeripheral *myPeripheral;
@property(strong,nonatomic) LGService *PizzaService;
@property(strong,nonatomic) LGCharacteristic *PizzaCrustCharacteristic;
@property(strong,nonatomic) LGCharacteristic *PizzaToppingsCharacteristic;
@property(strong,nonatomic) LGCharacteristic *PizzaBakeCharacteristic;
@property(strong,nonatomic) Pizza *pizza;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) startBaking
{
    __weak typeof(self) weakSelf = self;
    [weakSelf.PizzaCrustCharacteristic  writeByte:THIN completion:^(NSError *error) {
        if(error)
        {
            [self logToTextView:[NSString stringWithFormat:@"Crsut Error %@",error]];
        }
        else
        {
            unsigned char * raw_data = malloc(2);
            u_int16_t value =
            PEPPERONI|
            MUSHROOMS|
            EXTRA_CHEESE|
            BLACK_OLIVES|
            CANADIAN_BACON|
            PINEAPPLE|
            BELL_PEPPERS|
            SAUSAGE;
            raw_data[1]=value & 0xff;
            raw_data[0]=(value >> 8);
            
            NSData *data = [NSData dataWithBytes:raw_data length:2];
            
            [weakSelf.PizzaToppingsCharacteristic writeValue:data completion:^(NSError *error) {
                if(error)
                {
                    [self logToTextView:[NSString stringWithFormat:@"Topping Error %@",error]];
                }
                else{
                    
                    [weakSelf.PizzaBakeCharacteristic setNotifyValue:YES completion:^(NSError *error) {
                        if(error)
                        {
                             [self logToTextView:[NSString stringWithFormat:@"%s %@",__PRETTY_FUNCTION__,error]];
                        }
                        else
                        {
                            unsigned char * raw_data = malloc(2);
                            int value = 450;
                            raw_data[1]=value & 0xff;
                            raw_data[0]=(value >> 8);
                            printf("%i %i",raw_data[0],raw_data[1]);
                            NSData *data = [NSData dataWithBytes:raw_data length:2];
                            
                            [weakSelf.PizzaBakeCharacteristic writeValue:data completion:^(NSError *error) {
                                if (error) {
                                    [self logToTextView:[NSString stringWithFormat:@"bake error"]];
                                }
                            }];
                        }
                    } onUpdate:^(NSData *data, NSError *error) {
                        [self logToTextView:[NSString stringWithFormat:@"Our pizza is ready!"]];
                        if (data.length == 1) {
                            unsigned char* resultByte = malloc(1);
                            [data getBytes:resultByte length:1];
                            unsigned char result = resultByte[0];
                            [self logToTextView:[NSString stringWithFormat:@"The result is %s",(result == HALF_BAKED) ? "half baked." :
                                  (result == BAKED) ? "baked." :
                                  (result == CRISPY) ? "crispy." :
                                  (result == BURNT) ? "burnt." :
                                  (result == ON_FIRE) ? "on fire!" :
                                  "unknown?"]];                        }
                        else {
                            [self logToTextView:[NSString stringWithFormat:@"result length incorrect"]];
                        }
                    }];
                    
                        
                    
                }
            }];
        }
        
    }];
}
- (IBAction)searchPressed:(id)sender {
    if(self.myPeripheral==nil)
    {
        [self logToTextView:[NSString stringWithFormat:@"%s start search for device",__PRETTY_FUNCTION__]];
        // Scaning 4 seconds for peripherals
        [[LGCentralManager sharedInstance] scanForPeripheralsByInterval:4
                                                             completion:^(NSArray *peripherals)
         {
             [self logToTextView:[NSString stringWithFormat:@"%s scan For Peripheral",__PRETTY_FUNCTION__]];
             // If we found any peripherals sending to test
             for (LGPeripheral*peripheral in peripherals) {
                 [self logToTextView:[NSString stringWithFormat:@"LGPeripheral name: %@",peripheral.name]];
                 if([peripheral.name isEqualToString:@"james"] || [peripheral.name isEqualToString:@"rpibplus"] )
                 {
                     self.myPeripheral = peripheral;
                     [peripheral connectWithCompletion:^(NSError *error) {
                         // Discovering services of peripheral
                         
                         [peripheral discoverServicesWithCompletion:^(NSArray *services, NSError *error) {
                             for (LGService *service in services) {
                                 [self logToTextView:[NSString stringWithFormat:@"service.UUIDString %@",service.UUIDString]];
                                 if([service.UUIDString isEqualToString:PizzaServiceUUID])
                                 {
                                     self.PizzaService = service;
                                 }
                                 [service discoverCharacteristicsWithCompletion:^(NSArray *characteristics, NSError *error) {
                                     for (LGCharacteristic *charact in characteristics) {
                                         [self logToTextView:[NSString stringWithFormat:@"charact.UUIDString %@",charact.UUIDString]];
                                         if([charact.UUIDString isEqualToString:PizzaBakeCharacteristicUUID])
                                         {
                                             self.PizzaBakeCharacteristic = charact;
                                         }
                                         else if([charact.UUIDString isEqualToString:PizzaCrustCharacteristicUUID])
                                         {
                                             self.PizzaCrustCharacteristic = charact;
                                         }
                                         else if([charact.UUIDString isEqualToString:PizzaToppingsCharacteristicUUID])
                                         {
                                             self.PizzaToppingsCharacteristic = charact;
                                         }
                                         if(self.PizzaBakeCharacteristic && self.PizzaCrustCharacteristic && self.PizzaToppingsCharacteristic)
                                         {
                                             [self startBaking];
                                         }
                                     }
                                 }];
                             }
                         }];
                     }];
                     
                 }
             }
         }];
    }
    else{
        if(self.PizzaBakeCharacteristic && self.PizzaCrustCharacteristic && self.PizzaToppingsCharacteristic)
        {
            [self startBaking];
        }
    }
    
}
- (IBAction)bakePressed:(id)sender {
    if(self.PizzaBakeCharacteristic || self.PizzaCrustCharacteristic || self.PizzaToppingsCharacteristic)
    {
        [self startBaking];
    }
}
- (IBAction)clearLog:(id)sender {
    self.logTextView.text = @"";
}

-(void)logToTextView:(NSString*)message
{
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",message]];
}
#pragma mark - PizzaDelegate

-(void)bakeResult:(PizzaBakeResult)result
{
    
}
@end
