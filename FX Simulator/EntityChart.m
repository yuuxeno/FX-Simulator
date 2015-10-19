//
//  EntityChart.m
//  FXSimulator
//
//  Created by yuu on 2015/10/08.
//
//

#import "EntityChart.h"

#import "Candle.h"
#import "ForexHistoryData.h"
#import "ForexDataChunk.h"
#import "IndicatorChunk.h"
#import "Market.h"
#import "Time.h"

static NSUInteger FXSRequireForexDataCount = 500;
static NSUInteger FXSEntityChartForexDataCount = 300;

@interface EntityChart ()
@property (nonatomic) UIImage *chartImage;
@property (nonatomic) EntityChart *previousEntityChart;
@property (nonatomic) EntityChart *nextEntityChart;
@property (nonatomic) ForexHistoryData *visibleViewDefaultStartForexData;
@property (nonatomic) ForexHistoryData *visibleViewDefaultEndForexData;
@end

@implementation EntityChart {
    CurrencyPair *_currencyPair;
    TimeFrame *_timeFrame;
    ForexDataChunk *_forexDataChunk;
    ForexDataChunk *_forexDataChunkOfEntityChart;
    NSUInteger _entityChartForexDataCount;
    CGSize _viewSize;
    Candle *_candle;
    IndicatorChunk *_indicatorChunk;
    NSObject *_syncPreviousEntityChart;
    NSObject *_syncNextEntityChart;
    BOOL _isStartedPreparePreviousEntityChart;
    BOOL _isStartedPrepareNextEntityChart;
}

@synthesize entityChartView = _entityChartView;
@synthesize maxRate = _maxRate;
@synthesize minRate = _minRate;

+ (NSUInteger)forexDataCount
{
    return FXSEntityChartForexDataCount;
}

- (instancetype)initWithCurrencyPair:(CurrencyPair *)currencyPair timeFrame:(TimeFrame *)timeFrame indicatorChunk:(IndicatorChunk *)indicatorChunk
{
    if (self = [super init]) {
        _currencyPair = currencyPair;
        _timeFrame = timeFrame;
        _indicatorChunk = indicatorChunk;
        _viewSize = self.entityChartView.frame.size;
        
        _syncPreviousEntityChart = [NSObject new];
        _syncNextEntityChart = [NSObject new];
    }
    
    return self;
}

- (void)strokeForMarket:(Market *)market
{
    ForexDataChunk *forexDataChunk = [market chunkForCurrencyPair:_currencyPair timeFrame:_timeFrame Limit:FXSRequireForexDataCount];
    [self strokeForForexDataChunk:forexDataChunk];
}

- (void)strokeForForexDataChunk:(ForexDataChunk *)forexDataChunk
{
    _forexDataChunk = forexDataChunk;
    _forexDataChunkOfEntityChart = [_forexDataChunk chunkLimit:FXSEntityChartForexDataCount];
    [self setEntityChartImage];
}

- (void)setEntityChartImage
{
    UIGraphicsBeginImageContextWithOptions(_viewSize, NO, 0.0);
    
    if (![_indicatorChunk existsBaseIndicator]) {
        _candle = [Candle createTemporaryDefaultCandle];
        [_candle strokeIndicatorFromForexDataChunk:_forexDataChunk displayDataCount:FXSEntityChartForexDataCount displaySize:_viewSize];
    }
    
    [_indicatorChunk strokeIndicatorFromForexDataChunk:_forexDataChunk displayDataCount:FXSEntityChartForexDataCount displaySize:_viewSize];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.entityChartView.image = image;
    }];
}

- (ForexDataChunk *)chunkForRangeStartX:(float)startX endX:(float)endX
{
    return [_candle chunkRangeStartX:startX endX:endX];
}

- (ForexHistoryData *)leftEndForexData
{
    return [_candle leftEndForexData];
}

- (float)zoneStartXOfForexData:(ForexHistoryData *)forexData
{
    return [_candle zoneStartXOfForexData:forexData];
}

- (float)zoneEndXOfForexData:(ForexHistoryData *)forexData
{
    return [_candle zoneEndXOfForexData:forexData];
}

- (float)zoneStartXOfForexDataFromLeftEnd:(NSUInteger)index
{
    return [_candle zoneStartXOfForexDataFromLeftEnd:index];
}

- (ForexHistoryData *)forexDataFromLeftEnd:(NSUInteger)index
{
    return [_candle forexDataFromLeftEnd:index];
}

- (void)preparePreviousEntityChartForMarket:(Market *)market
{
    if (_isStartedPreparePreviousEntityChart) {
        return;
    }
        
    _isStartedPreparePreviousEntityChart = YES;
    
    NSOperationQueue *queue = [NSOperationQueue new];
    
    [queue addOperationWithBlock:^{
        @synchronized (_syncPreviousEntityChart) {
            ForexHistoryData *leftEndForexData = [_candle leftEndForexData];
            NSUInteger limit = FXSEntityChartForexDataCount / 2;
            NSUInteger frontLimit = limit - 1;
            NSUInteger backLimit = FXSRequireForexDataCount - (frontLimit + 1);
            ForexDataChunk *newForexDataChunk = [market chunkForCenterForexData:leftEndForexData frontLimit:frontLimit backLimit:backLimit];
            
            NSComparisonResult result = [leftEndForexData.oldestTime compare:newForexDataChunk.oldestTime];
            
            if (result != NSOrderedDescending) {
                return;
            }
            
            self.previousEntityChart = [[[self class] alloc] initWithCurrencyPair:_currencyPair timeFrame:_timeFrame indicatorChunk:_indicatorChunk];
            [self.previousEntityChart strokeForForexDataChunk:newForexDataChunk];
            self.previousEntityChart.visibleViewDefaultStartForexData = leftEndForexData;
        }
    }];
}

- (void)prepareNextEntityChartForMarket:(Market *)market
{
    if (_isStartedPrepareNextEntityChart) {
        return;
    }
    
    _isStartedPrepareNextEntityChart = YES;
    
    NSOperationQueue *queue = [NSOperationQueue new];
    
    [queue addOperationWithBlock:^{
        @synchronized (_syncNextEntityChart) {
            ForexHistoryData *rightEndForexData = [_candle rightEndForexData];
            NSUInteger limit = FXSEntityChartForexDataCount / 2;
            NSUInteger frontLimit = limit - 1;
            NSUInteger backLimit = FXSRequireForexDataCount - (frontLimit + 1);
            ForexDataChunk *newForexDataChunk = [market chunkForCenterForexData:rightEndForexData frontLimit:frontLimit backLimit:backLimit];
            
            NSComparisonResult result = [rightEndForexData.latestTime compare:newForexDataChunk.latestTime];
            
            if (result != NSOrderedAscending) {
                return;
            }
            
            self.nextEntityChart = [[[self class] alloc] initWithCurrencyPair:_currencyPair timeFrame:_timeFrame indicatorChunk:_indicatorChunk];
            [self.nextEntityChart strokeForForexDataChunk:newForexDataChunk];
            self.nextEntityChart.visibleViewDefaultEndForexData = rightEndForexData;
        }
    }];
}

- (UIImageView *)entityChartView
{
    if (!_entityChartView) {
        _entityChartView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 2000, 1000)];
    }
    
    return _entityChartView;
}

- (Rate *)maxRate
{
    if (!_maxRate) {
        _maxRate = [_forexDataChunkOfEntityChart getMaxRate];
    }
    
    return _maxRate;
}

- (Rate *)minRate
{
    if (!_minRate) {
        _minRate = [_forexDataChunkOfEntityChart getMinRate];
    }
    
    return _minRate;
}

- (EntityChart *)previousEntityChart
{
    // prepareのsynchronizedより先に、このsynchronizedが実行される可能性がある。(間隔が極めて短い時など)
    /*if (_isStartedPreparePreviousEntityChart) {
        [NSThread sleepForTimeInterval:0.01];
    }*/
    
    @synchronized (_syncPreviousEntityChart) {
        return _previousEntityChart;
    }
}

- (float)visibleViewDefaultStartX
{
    if (!self.visibleViewDefaultStartForexData) {
        return 0;
    }
    
    return [self zoneStartXOfForexData:self.visibleViewDefaultStartForexData];
}

- (float)visibleViewDefaultEndX
{
    if (!self.visibleViewDefaultEndForexData) {
        return 0;
    }
    
    return [self zoneEndXOfForexData:self.visibleViewDefaultEndForexData];
}

@end
