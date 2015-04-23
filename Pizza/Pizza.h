//
//  Pizza.h
//  Pizza
//
//  Created by James Kong on 23/4/15.
//  Copyright (c) 2015 James Kong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(unsigned char,PizzaCrust){
    NORMAL = 0,
    DEEP_DISH = 1,
    THIN = 2,
};

typedef NS_OPTIONS(unsigned char,PizzaToppings){
    NONE=           0,
    PEPPERONI=      1 << 0,
    MUSHROOMS=      1 << 1,
    EXTRA_CHEESE=   1 << 2,
    BLACK_OLIVES=   1 << 3,
    CANADIAN_BACON= 1 << 4,
    PINEAPPLE=      1 << 5,
    BELL_PEPPERS=   1 << 6,
    SAUSAGE=        1 << 7,
};

typedef NS_OPTIONS(unsigned char,PizzaBakeResult){
    HALF_BAKED= 0,
    BAKED=      1,
    CRISPY=     2,
    BURNT=      3,
    ON_FIRE=    4
};

@protocol PizzaDelegate <NSObject>

-(void)bakeResult:(PizzaBakeResult)result;

@end
@interface Pizza : NSObject
- (id)init;
@property(weak,nonatomic)id<PizzaDelegate> delegate;
@property PizzaCrust pizzeCrust;
@property PizzaToppings pizzeToppings;
@property PizzaBakeResult pizzeBakeResult;
-(void)bakeWithTemperature:(NSInteger)temperature;
@end
