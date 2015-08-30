//
//  ExecutionOrdersFactory.h
//  FX Simulator
//
//  Created  on 2014/11/21.
//  
//

#import <Foundation/Foundation.h>

@class OpenPosition;
@class Order;

@interface ExecutionOrdersFactory : NSObject
- (instancetype)initWithOpenPosition:(OpenPosition *)openPosition;
- (NSArray *)create:(Order *)order;
@end
