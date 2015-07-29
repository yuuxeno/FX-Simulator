//
//  MarketTimeScale.h
//  FX Simulator
//
//  Created  on 2014/12/02.
//  
//

#import <Foundation/Foundation.h>

@interface TimeFrame : NSObject <NSCoding>
-(id)initWithMinute:(NSUInteger)minute;
- (NSComparisonResult)compare:(TimeFrame *)timeFrame;
- (BOOL)isEqualToTimeFrame:(TimeFrame *)timeFrame;
-(NSString*)toDisplayString;
@property (nonatomic, readonly) NSUInteger minute;
@property (nonatomic, readonly) NSNumber *minuteValueObj;
@end
