//
//  SaveData.m
//  FX Simulator
//
//  Created  on 2014/10/08.
//  
//

#import "SaveData.h"

#import "SaveDataSource.h"
#import "CoreDataManager.h"
#import "MarketTime.h"
#import "TimeFrame.h"
#import "TimeFrameChunk.h"
#import "Chart.h"
#import "ChartSource.h"
#import "ChartChunk.h"
#import "Currency.h"
#import "CurrencyPair.h"
#import "FXSTimeRange.h"
#import "FXSTest.h"
#import "Setting.h"
#import "Spread.h"
#import "PositionSize.h"
#import "Lot.h"
#import "Money.h"
#import "TimeScaleUtils.h"
#import "OrderHistory.h"
#import "OpenPosition.h"
#import "ExecutionHistory.h"

@interface SaveData ()
@property (nonatomic) NSUInteger slotNumber;
@end

@implementation SaveData {
    SaveDataSource *_saveDataSource;
}

@synthesize orderHistory = _orderHistory;
@synthesize openPosition = _openPosition;
@synthesize executionHistory = _executionHistory;

+ (CoreDataManager *)coreDataManager
{
    return [CoreDataManager sharedManager];
}

+ (instancetype)createDefaultNewSaveDataFromSlotNumber:(NSUInteger)slotNumber
{
    CurrencyPair *currencyPair = [[CurrencyPair alloc] initWithBaseCurrency:[[Currency alloc] initWithCurrencyType:USD] QuoteCurrency:[[Currency alloc] initWithCurrencyType:JPY]];
    TimeFrame *timeFrame = [[TimeFrame alloc] initWithMinute:15];
    
    SaveData *saveData = [self createNewSaveDataFromSlotNumber:slotNumber currencyPair:currencyPair timeFrame:timeFrame];
    
    saveData.startTime = [Setting rangeForCurrencyPair:saveData.currencyPair timeScale:saveData.timeFrame].start;
    saveData.lastLoadedTime = saveData.startTime;
    saveData.spread = [[Spread alloc] initWithPips:1 currencyPair:saveData.currencyPair];
    saveData.accountCurrency = [[Currency alloc] initWithCurrencyType:JPY];
    saveData.startBalance = [[Money alloc] initWithAmount:1000000 currency:saveData.accountCurrency];
    saveData.positionSizeOfLot = [[PositionSize alloc] initWithSizeValue:10000];
    saveData.tradePositionSize = [[PositionSize alloc] initWithSizeValue:10000];
    saveData.isAutoUpdate = YES;
    saveData.autoUpdateIntervalSeconds = 1.0;
    
    return saveData;
}

+ (instancetype)createNewSaveDataFromSlotNumber:(NSUInteger)slotNumber currencyPair:(CurrencyPair *)currencyPair timeFrame:(TimeFrame *)timeFrame
{
    if (currencyPair == nil || timeFrame == nil) {
        return nil;
    }
    
    SaveDataSource *source = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SaveDataSource class]) inManagedObjectContext:[self coreDataManager].managedObjectContext];
    
    SaveData *saveData = [[SaveData alloc] initWithSaveDataSource:source];
    
    saveData.slotNumber = slotNumber;
    saveData.currencyPair = currencyPair;
    saveData.timeFrame = timeFrame;
    
    [saveData setDefaultCharts];
    
    [saveData newSave];
    
    return saveData;
}

+ (instancetype)loadFromSlotNumber:(NSUInteger)slotNumber
{
    NSManagedObjectContext *context = [self coreDataManager].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([SaveDataSource class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(slotNumber = %d)", slotNumber];
     [fetchRequest setPredicate:predicate];
    
    NSError *error2;
    NSArray *objects = [context executeFetchRequest:fetchRequest error:&error2];
    
    SaveDataSource *source = nil;
    
    for (SaveDataSource *obj in objects) {
        source = obj;
    }
    
    return [[self alloc] initWithSaveDataSource:source];
}

- (instancetype)init
{
    return nil;
}

- (instancetype)initWithSaveDataSource:(SaveDataSource *)source
{
    if (source == nil) {
        return nil;
    }
    
    if (self = [super init]) {
        _saveDataSource = source;
    }
    
    return self;
}

- (void)setDefaultCharts
{
    if (self.currencyPair == nil || self.timeFrame == nil) {
        return;
    }
    
    Chart *mainChart = [Chart createNewChartFromSaveDataSource:_saveDataSource];
    mainChart.chartIndex = 0;
    mainChart.currencyPair = self.currencyPair;
    mainChart.timeFrame = self.timeFrame;
    mainChart.isSelected = YES;
    
    [[Setting timeFrameList] enumerateTimeFrames:^(NSUInteger idx, TimeFrame *timeFrame) {
        Chart *subChart = [Chart createNewChartFromSaveDataSource:_saveDataSource];
        subChart.chartIndex = idx;
        subChart.currencyPair = self.currencyPair;
        subChart.timeFrame = self.timeFrame;
        
        if (idx == 0) {
            subChart.isSelected = YES;
        } else {
            subChart.isSelected = NO;
        }
        
    } execept:self.timeFrame];
}

/**
 重複するslotNumberのセーブデータを全て削除する。
*/
- (void)newSave
{
    NSManagedObjectContext *context = [[self class] coreDataManager].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:NSStringFromClass([SaveDataSource class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entityDescription];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(slotNumber = %d)", self.slotNumber];
     [fetchRequest setPredicate:predicate];
    
    NSError * error2;
    NSArray * objects = [context executeFetchRequest:fetchRequest error:&error2];
    
    for (SaveDataSource *obj in objects) {
        if (_saveDataSource.objectID != obj.objectID) {
            [context deleteObject:obj];
        }
    }    
}

#pragma mark - getter,setter

- (Chart *)mainChart
{
    return [Chart createChartFromChartSource:[_saveDataSource.mainChartSources allObjects].firstObject];
}

- (ChartChunk *)subChartChunk
{
    NSMutableArray *subChartArray = [NSMutableArray array];
    
    [_saveDataSource.subChartSources enumerateObjectsUsingBlock:^(ChartSource *obj, BOOL *stop) {
        Chart *chart = [Chart createChartFromChartSource:obj];
        [subChartArray addObject:chart];
    }];
    
    return [[ChartChunk alloc] initWithChartArray:subChartArray];
}

- (NSUInteger)slotNumber
{
    return _saveDataSource.slotNumber;
}

- (void)setSlotNumber:(NSUInteger)slotNumber
{
    _saveDataSource.slotNumber = slotNumber;
}

- (CurrencyPair *)currencyPair
{
    return _saveDataSource.currencyPair;
}

- (void)setCurrencyPair:(CurrencyPair *)currencyPair
{
    _saveDataSource.currencyPair = currencyPair;
}

- (TimeFrame *)timeFrame
{
    return _saveDataSource.timeFrame;
}

- (void)setTimeFrame:(TimeFrame *)timeFrame
{
    _saveDataSource.timeFrame = timeFrame;
}

- (MarketTime *)startTime
{
    return _saveDataSource.startTime;
}

- (void)setStartTime:(MarketTime *)startTime
{
    _saveDataSource.startTime = startTime;
}

- (Spread *)spread
{
    return _saveDataSource.spread;
}

- (void)setSpread:(Spread *)spread
{
    _saveDataSource.spread = spread;
}

- (MarketTime *)lastLoadedTime
{
    return _saveDataSource.lastLoadedTime;
}

- (void)setLastLoadedTime:(MarketTime *)lastLoadedTime
{
    _saveDataSource.lastLoadedTime = lastLoadedTime;
}

- (Currency *)accountCurrency
{
    return _saveDataSource.accountCurrency;
}

- (void)setAccountCurrency:(Currency *)accountCurrency
{
    _saveDataSource.accountCurrency = accountCurrency;
}

- (PositionSize *)positionSizeOfLot
{
    return _saveDataSource.positionSizeOfLot;
}

- (void)setPositionSizeOfLot:(PositionSize *)positionSizeOfLot
{
    _saveDataSource.positionSizeOfLot = positionSizeOfLot;
}

- (PositionSize *)tradePositionSize
{
    return _saveDataSource.tradePositionSize;
}

- (void)setTradePositionSize:(PositionSize *)tradePositionSize
{
    _saveDataSource.tradePositionSize = tradePositionSize;
}

- (Money *)startBalance
{
    return _saveDataSource.startBalance;
}

- (void)setStartBalance:(Money *)startBalance
{
    _saveDataSource.startBalance = startBalance;
}

- (BOOL)isAutoUpdate
{
    return _saveDataSource.isAutoUpdate;
}

- (void)setIsAutoUpdate:(BOOL)isAutoUpdate
{
    _saveDataSource.isAutoUpdate = isAutoUpdate;
}

- (float)autoUpdateIntervalSeconds
{
    return _saveDataSource.autoUpdateIntervalSeconds;
}

- (void)setAutoUpdateIntervalSeconds:(float)autoUpdateInterval
{
    _saveDataSource.autoUpdateIntervalSeconds = autoUpdateInterval;
}

- (OrderHistory *)orderHistory
{
    if (_orderHistory != nil) {
        return _orderHistory;
    }
    
    return [OrderHistory createFromSlotNumber:self.slotNumber];
}

- (OpenPosition *)openPosition
{
    if (_openPosition != nil) {
        return _openPosition;
    }
    
    return [OpenPosition createFromSlotNumber:self.slotNumber AccountCurrency:self.accountCurrency];
}

- (ExecutionHistory *)executionHistory
{
    if (_executionHistory != nil) {
        return _executionHistory;
    }
    
    return [ExecutionHistory createFromSlotNumber:self.slotNumber];
}

@end
