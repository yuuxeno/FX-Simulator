//
//  TradeType.h
//  ForexGame
//
//  Created  on 2014/06/23.
//  
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PositionType : NSObject

@property (nonatomic, readonly) BOOL isShort;
@property (nonatomic, readonly) BOOL isLong;

- (instancetype)initWithShort;
- (instancetype)initWithLong;
- (instancetype)initWithString:(NSString*)typeString;
- (void)setShort;
- (void)setLong;
- (BOOL)isEqualOrderType:(PositionType*)orderType;
- (NSString *)toDisplayString;

/// DBなどに使う。
- (NSString *)toTypeString;

- (UIColor *)toColor;

@end
