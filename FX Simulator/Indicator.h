//
//  Indicator.h
//  FX Simulator
//
//  Created by yuu on 2015/07/05.
//
//

#import <Foundation/Foundation.h>
#import "IndicatorSource.h"

@import UIKit;

@class UIBezierPath;
@class UIView;
@class ForexDataChunk;
@class MarketTimeScale;

/**
 @param count 画面に表示するForexDataの個数。
*/

@interface Indicator : NSObject
- (instancetype)initWithSource:(IndicatorSource *)source;
- (void)strokeIndicatorFromForexDataChunk:(ForexDataChunk *)chunk displayForexDataCount:(NSInteger)count displaySize:(CGSize)size;
@property (nonatomic, readonly) NSUInteger displayIndex;
@property (nonatomic, readonly) BOOL isMainChart;
@property (nonatomic, readonly) MarketTimeScale *timeScale;
@property (nonatomic, readonly) NSDictionary *sourceDictionary;
@end

