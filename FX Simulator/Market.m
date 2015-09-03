//
//  Market.m
//  FX Simulator
//
//  Created  on 2014/11/13.
//  
//

#import "Market.h"

#import "CurrencyPair.h"
#import "ForexDataChunk.h"
#import "ForexDataChunkStore.h"
#import "ForexHistoryFactory.h"
#import "ForexHistory.h"
#import "ForexHistoryData.h"
#import "Time.h"
#import "MarketTimeManager.h"
#import "Rate.h"
#import "Rates.h"
#import "SaveData.h"
#import "SaveLoader.h"
#import "Setting.h"

static NSInteger FXSMaxForexDataStore = 500;
static NSString * const kKeyPath = @"currentTime";

@interface Market ()
@property (nonatomic, readwrite) int currentLoadedRowid;
@property (nonatomic) Rate *currentRate;
@property (nonatomic) Time *currentTime;
@property (nonatomic) ForexHistoryData *currentForexData;
@end

@implementation Market {
    MarketTimeManager *_marketTimeManager;
    NSMutableArray *_observers;
    ForexDataChunkStore *_forexDataChunkStore;
    ForexHistory *_forexHistory;
    ForexHistoryData *_lastData;
}

- (instancetype)init
{
    if (self = [super init]) {
        _observers = [NSMutableArray array];
    }
    
    return self;
}

- (void)loadSaveData:(SaveData *)saveData
{
    _isAutoUpdate = saveData.isAutoUpdate;
    
    _forexHistory = [ForexHistoryFactory createForexHistoryFromCurrencyPair:saveData.currencyPair timeScale:saveData.timeFrame];
    _currentTime = saveData.lastLoadedTime;
    _currentForexData = [_forexHistory selectMaxCloseTime:_currentTime limit:1].firstObject;
    
    _forexDataChunkStore = [[ForexDataChunkStore alloc] initWithCurrencyPair:saveData.currencyPair timeScale:saveData.timeFrame getMaxLimit:FXSMaxForexDataStore];
    
    _lastData = [_forexHistory lastRecord];
    
    _marketTimeManager = [MarketTimeManager new];
    [_marketTimeManager addObserver:self];
    
    _isStart = NO;
}

- (void)addObserver:(UIViewController *)observer
{
    [_observers addObject:observer];
    
    [self addObserver:(NSObject*)observer forKeyPath:kKeyPath options:NSKeyValueObservingOptionNew context:NULL];
}

- (Rates *)getCurrentRatesOfCurrencyPair:(CurrencyPair *)currencyPair
{
    Rate *currentBidRate = [self getCurrentBidRateOfCurrencyPair:currencyPair];
    
    if (!currentBidRate) {
        return nil;
    }
    
    return [[Rates alloc] initWithBidRtae:currentBidRate];
}

- (Rate *)getCurrentBidRateOfCurrencyPair:(CurrencyPair *)currencyPair
{
    if ([self.currentForexData.close.currencyPair isEqualCurrencyPair:currencyPair]) {
        return self.currentForexData.close;
    } else {
        return nil;
    }
}

- (Rate *)getCurrentAskRateOfCurrencyPair:(CurrencyPair *)currencyPair
{
    Rate *currentBidRate = [self getCurrentBidRateOfCurrencyPair:currencyPair];
    
    if (!currentBidRate) {
        return nil;
    }
    
    return [[[Rates alloc] initWithBidRtae:currentBidRate] askRate];
}

/**
 ObserverにMarketの更新前、更新、更新後を通知。
*/
- (void)updateMarketFromNewCurrentData:(ForexHistoryData *)data
{
    // Market更新前を通知。
    if ([self.delegate respondsToSelector:@selector(willNotifyObservers)]) {
        [self.delegate willNotifyObservers];
    }
    
    self.currentForexData = data;
    self.currentRate = data.close;
    
    // Market更新。
    self.currentTime = self.currentRate.timestamp;
    
    // SimulatorManager
    // observeの呼ばれる順番は不規則
    // Marketの更新"直後"に実行したいものはObserverにしない
    // MarketTimeの変化でのみcurrentTimestampが変化
    // currentTimestampの変化で、MarketのObserverを更新
    
    // Market更新後を通知。
    if ([self.delegate respondsToSelector:@selector(didNotifyObservers)]) {
        [self.delegate didNotifyObservers];
    }
}

- (void)start
{
    // 初期データでMarketを更新しておく。
    [self updateMarketFromNewCurrentData:self.currentForexData];
    
    if (_isAutoUpdate) {
        [self startTime];
    }
}

- (void)pause
{
    [_marketTimeManager pause];
}

- (void)resume
{
    [_marketTimeManager resume];
}

- (void)add
{
    [_marketTimeManager add];
}

- (void)startTime
{
    _isStart = YES;
    [_marketTimeManager start];
}

- (void)setIsAutoUpdate:(BOOL)isAutoUpdate
{
    _isAutoUpdate = isAutoUpdate;
    
    if (_isStart) {
        if (_isAutoUpdate == YES) {
            [_marketTimeManager resume];
        } else {
            [_marketTimeManager pause];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentLoadedRowid"] && [object isKindOfClass:[MarketTimeManager class]]) {
        
        ForexDataChunk *currentForexDataChunk = [_forexDataChunkStore getChunkFromNextDataOfTime:self.currentTime limit:1];
        
        ForexHistoryData *newCurrentData = currentForexDataChunk.current;
        
        if (newCurrentData == nil) {
            return;
        }
        
        [self updateMarketFromNewCurrentData:newCurrentData];
    }
}

- (void)setAutoUpdateInterval:(NSNumber *)autoUpdateInterval
{
    _marketTimeManager.autoUpdateInterval = autoUpdateInterval;
}

- (BOOL)didLoadLastData
{
    if (_lastData.ratesID == self.currentForexData.ratesID) {
        return YES;
    } else {
        return NO;
    }
}

- (void)dealloc
{
    for (NSObject *obj in _observers) {
        [self removeObserver:obj forKeyPath:kKeyPath];
    }
}

@end
