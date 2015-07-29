//
//  PositionSize.h
//  FX Simulator
//
//  Created  on 2014/12/06.
//  
//

//#import <Foundation/Foundation.h>
#import "Common.h"

@class Lot;

@interface PositionSize : NSObject <NSCoding>
-(id)initWithSizeValue:(position_size_t)size;
-(NSString*)toDisplayString;
-(Lot*)toLot;
-(BOOL)isEqualPositionSize:(PositionSize*)positionsize;
@property (nonatomic, readonly) position_size_t sizeValue;
@property (nonatomic, readonly) NSNumber *sizeValueObj;
@end
