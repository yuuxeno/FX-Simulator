//
//  Chart.h
//  FX Simulator
//
//  Created by yuu on 2015/07/18.
//
//

#import <Foundation/Foundation.h>

@class CurrencyPair;
@class TimeFrame;
@class ChartSource;
@class ForexDataChunk;

@interface Chart : NSObject
- (instancetype)initWithChartSource:(ChartSource *)source;
- (NSComparisonResult)compareDisplayOrder:(Chart *)chart;
- (void)setForexDataChunk:(ForexDataChunk *)chunk;
- (void)stroke;
- (BOOL)isEqualChartIndex:(NSUInteger)index;
@property (nonatomic, readonly) ChartSource *chartSource;
@property (nonatomic) NSUInteger chartIndex;
@property (nonatomic) CurrencyPair *currencyPair;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) TimeFrame *timeFrame;
@end
