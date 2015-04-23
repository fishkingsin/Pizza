//
//  Pizza.m
//  Pizza
//
//  Created by James Kong on 23/4/15.
//  Copyright (c) 2015 James Kong. All rights reserved.
//

#import "Pizza.h"


@implementation Pizza

- (id)init
{
    self = [super init];
    if (self) {
        self.pizzeToppings = NONE;
        self.pizzeCrust = NORMAL;
    }
    return self;
}
-(void)bakeWithTemperature:(NSInteger)temperature
{

    NSInteger time = temperature * 10;
    NSLog(@"baking pizza at %ld degrees for %ld milliseconds" , (long)temperature, (long)time);
    
    NSInteger result =
    (temperature < 350) ? HALF_BAKED:
    (temperature < 450) ? BAKED:
    (temperature < 500) ? CRISPY:
    (temperature < 600) ? BURNT:
    ON_FIRE;
    if(self.delegate)
    {
        if([self.delegate respondsToSelector:@selector(bakeResult:)])
        {
            [self.delegate bakeResult:result];
        }
    }
}
@end
