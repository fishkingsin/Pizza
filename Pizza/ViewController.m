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
#import "MHRotaryKnob.h"
#import "M13Checkbox.h"
static NSString * const PizzaServiceUUID = @"13333333-3333-3333-3333-333333333337";
static NSString * const PizzaCrustCharacteristicUUID = @"13333333-3333-3333-3333-333333330001";
static NSString * const PizzaToppingsCharacteristicUUID = @"13333333-3333-3333-3333-333333330002";
static NSString * const PizzaBakeCharacteristicUUID = @"13333333-3333-3333-3333-333333330003";
@interface ViewController ()<PizzaDelegate>
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (weak, nonatomic) IBOutlet MHRotaryKnob *rotaryKnob;
@property (weak, nonatomic) IBOutlet UILabel *degreeLabel;
@property(strong,nonatomic) LGPeripheral *myPeripheral;
@property(strong,nonatomic) LGService *PizzaService;
@property(strong,nonatomic) LGCharacteristic *PizzaCrustCharacteristic;
@property(strong,nonatomic) LGCharacteristic *PizzaToppingsCharacteristic;
@property(strong,nonatomic) LGCharacteristic *PizzaBakeCharacteristic;
@property(strong,nonatomic) Pizza *pizza;
@property (strong, nonatomic) IBOutletCollection(M13Checkbox) NSArray *checkboxes;
@property (strong, nonatomic) NSMutableDictionary *checkboxesDic;
@property (strong, nonatomic)  NSArray * toppings;
@end

@implementation ViewController
@synthesize toppings;
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    toppings = @[@"PEPPERONI",
                 @"MUSHROOMS",
                 @"EXTRA_CHEESE",
                 @"BLACK_OLIVES",
                 @"CANADIAN_BACON",
                 @"PINEAPPLE",
                 @"BELL_PEPPERS",
                 @"SAUSAGE"];
    
    self.rotaryKnob.interactionStyle = MHRotaryKnobInteractionStyleRotating;
    self.rotaryKnob.scalingFactor = 1.5f;
    self.rotaryKnob.maximumValue = 600;
    self.rotaryKnob.minimumValue = 300;
    self.rotaryKnob.value = 450;
    self.rotaryKnob.defaultValue = self.rotaryKnob.value;
    self.rotaryKnob.resetsToDefault = YES;
    self.rotaryKnob.backgroundColor = [UIColor clearColor];
    self.rotaryKnob.backgroundImage = [UIImage imageNamed:@"Knob Background.png"];
    [self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Knob.png"] forState:UIControlStateNormal];
    [self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Knob Highlighted.png"] forState:UIControlStateHighlighted];
    [self.rotaryKnob setKnobImage:[UIImage imageNamed:@"Knob Disabled.png"] forState:UIControlStateDisabled];
    self.rotaryKnob.knobImageCenter = CGPointMake(80.0f, 76.0f);
    [self.rotaryKnob addTarget:self action:@selector(rotaryKnobDidChange) forControlEvents:UIControlEventValueChanged];
    // Do any additional setup after loading the view, typically from a nib.
    
    int i = 0;
    self.checkboxesDic = [NSMutableDictionary dictionary];
    for(M13Checkbox *cb in self.checkboxes)
    {
        M13Checkbox* checkbox  = (M13Checkbox*)cb;
        [checkbox.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [checkbox.titleLabel setText:[toppings objectAtIndex:i]];
        [self.checkboxesDic setObject:checkbox forKey:[toppings objectAtIndex:i]];
        i++;
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(BOOL)isCheckByKey:(NSString*)key
{
    return ((M13Checkbox*)[self.checkboxesDic objectForKey:key]).checkState;
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
            ([self isCheckByKey:[toppings objectAtIndex:0]])?PEPPERONI:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:1]])?MUSHROOMS:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:2]])?EXTRA_CHEESE:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:3]])?BLACK_OLIVES:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:4]])?CANADIAN_BACON:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:5]])?PINEAPPLE:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:6]])?BELL_PEPPERS:NONE|
            ([self isCheckByKey:[toppings objectAtIndex:7]])?SAUSAGE:NONE;
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
                            int value = self.rotaryKnob.value;
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
                                                 "unknown?"]];
                            [weakSelf.PizzaToppingsCharacteristic readValueWithBlock:^(NSData *data, NSError *error) {
                                unsigned char* toppingResultByte = malloc(2);
                                [data getBytes:toppingResultByte length:2];
                                [self logToTextView:[NSString stringWithFormat:@"PizzaToppings %i %i",toppingResultByte[0],toppingResultByte[1]]];
                            }];
                        }
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
    [self.logTextView layoutIfNeeded];
    NSRange range = NSMakeRange(self.logTextView.text.length - 2, 1); //I ignore the final carriage return, to avoid a blank line at the bottom
    [self.logTextView scrollRangeToVisible:range];
}
- (IBAction)rotaryKnobDidChange
{
    self.degreeLabel.text = [NSString stringWithFormat:@"%.3f", self.rotaryKnob.value];
}

#pragma mark - PizzaDelegate

-(void)bakeResult:(PizzaBakeResult)result
{
    
}
@end
