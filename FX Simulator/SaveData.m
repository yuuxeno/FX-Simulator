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
#import "TableNameFormatter.h"
#import "Setting.h"
#import "Spread.h"
#import "PositionSize.h"
#import "Lot.h"
#import "Money.h"
#import "TradeTestDbDataSource.h"
#import "TradeDbDataSource.h"
#import "TimeScaleUtils.h"

@interface SaveData ()
@property (nonatomic) NSUInteger slotNumber;
//@property (nonatomic, readonly) CoreDataManager *coreDataManager;
@end

@implementation SaveData {
    SaveDataSource *_saveDataSource;
}

+ (instancetype)createSaveData
{
    SaveDataSource *source = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SaveDataSource class]) inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
    
    SaveData *saveData = [[SaveData alloc] initWithSaveDataSource:source];
    
    return saveData;
}

+ (instancetype)createDefaultSaveDataFromSlotNumber:(NSUInteger)slotNumber
{
    SaveDataSource *source = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SaveDataSource class]) inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
    
    SaveData *saveData = [[SaveData alloc] initWithSaveDataSource:source];
    
    saveData.slotNumber = slotNumber;
    saveData.currencyPair = [[CurrencyPair alloc] initWithBaseCurrency:[[Currency alloc] initWithCurrencyType:USD] QuoteCurrency:[[Currency alloc] initWithCurrencyType:JPY]];
    saveData.timeFrame = [[TimeFrame alloc] initWithMinute:15];
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

- (instancetype)init
{
    return nil;
}

- (instancetype)initWithSaveDataSource:(SaveDataSource *)source
{
    if (self = [super init]) {
        _saveDataSource = source;
    }
    
    return self;
}

- (void)setDefaultCharts
{
    Chart *mainChart = [[Chart alloc] initWithChartSource:[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ChartSource class]) inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext]];
    mainChart.chartIndex = 0;
    mainChart.currencyPair = self.currencyPair;
    mainChart.timeFrame = self.timeFrame;
    mainChart.isSelected = YES;
    
    [_saveDataSource addMainChartSourcesObject:mainChart.chartSource];
    
    [[Setting timeFrameList] enumerateTimeFrames:^(NSUInteger idx, TimeFrame *timeFrame) {
        Chart *subChart = [[Chart alloc] initWithChartSource:[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ChartSource class]) inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext]];
        subChart.chartIndex = idx;
        subChart.currencyPair = self.currencyPair;
        subChart.timeFrame = self.timeFrame;
        
        if (idx == 0) {
            subChart.isSelected = YES;
        } else {
            subChart.isSelected = NO;
        }
        
        [_saveDataSource addSubChartSourcesObject:subChart.chartSource];
        
    } execept:self.timeFrame];
}

/*- (void)setDefaultDataAndSlotNumber:(NSUInteger)slotNumber
{
    self.slotNumber = (int)slotNumber;
    self.currencyPair = [[CurrencyPair alloc] initWithBaseCurrency:[[Currency alloc] initWithCurrencyType:USD] QuoteCurrency:[[Currency alloc] initWithCurrencyType:JPY]];
    self.timeFrame = [[TimeFrame alloc] initWithMinute:15];
    self.startTime = [Setting rangeForCurrencyPair:self.currencyPair timeScale:self.timeFrame].start;
    self.lastLoadedTime = self.startTime;
    self.spread = [[Spread alloc] initWithPips:1 currencyPair:self.currencyPair];
    self.accountCurrency = [[Currency alloc] initWithCurrencyType:JPY];
    self.startBalance = [[Money alloc] initWithAmount:1000000 currency:self.accountCurrency];
    self.positionSizeOfLot = [[PositionSize alloc] initWithSizeValue:10000];
    self.tradePositionSize = [[PositionSize alloc] initWithSizeValue:10000];
    self.isAutoUpdate = YES;
    self.autoUpdateInterval = 1.0;
}*/

- (void)newSave
{
    NSManagedObjectContext *context = [CoreDataManager sharedManager].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:NSStringFromClass([self class]) inManagedObjectContext:context];
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
    
    [self setDefaultCharts];
}

#pragma mark - getter,setter

- (Chart *)mainChart
{
    return [_saveDataSource.mainChartSources allObjects].firstObject;
}

- (ChartChunk *)subChartChunk
{
    NSMutableArray *subChartArray = [NSMutableArray array];
    
    [_saveDataSource.subChartSources enumerateObjectsUsingBlock:^(ChartSource *obj, BOOL *stop) {
        Chart *chart = [[Chart alloc] initWithChartSource:obj];
        [subChartArray addObject:chart];
    }];
    
    return [[ChartChunk alloc] initWithChartArray:subChartArray];
}

- (NSUInteger)slotNumber
{
    return _saveDataSource.slotNumber;
}

- (void)setCurrencyPair:(CurrencyPair *)currencyPair
{
    _saveDataSource.currencyPair = currencyPair;
}

- (CurrencyPair *)currencyPair
{
    return _saveDataSource.currencyPair;
}

- (void)setTimeFrame:(TimeFrame *)timeFrame
{
    _saveDataSource.timeFrame = timeFrame;
}

- (TimeFrame *)timeFrame
{
    return _saveDataSource.timeFrame;
}

- (void)setStartTime:(MarketTime *)startTime
{
    _saveDataSource.startTime = startTime;
}

- (MarketTime *)startTime
{
    return _saveDataSource.startTime;
}

- (void)setSpread:(Spread *)spread
{
    _saveDataSource.spread = spread;
}

- (Spread *)spread
{
    return _saveDataSource.spread;
}

- (void)setLastLoadedTime:(MarketTime *)lastLoadedTime
{
    _saveDataSource.lastLoadedTime = lastLoadedTime;
}

- (MarketTime *)lastLoadedTime
{
    return _saveDataSource.lastLoadedTime;
}

- (void)setAccountCurrency:(Currency *)accountCurrency
{
    _saveDataSource.accountCurrency = accountCurrency;
}

- (Currency *)accountCurrency
{
    return _saveDataSource.accountCurrency;
}

- (void)setPositionSizeOfLot:(PositionSize *)positionSizeOfLot
{
    _saveDataSource.positionSizeOfLot = positionSizeOfLot;
}

- (PositionSize *)positionSizeOfLot
{
    return _saveDataSource.positionSizeOfLot;
}

- (void)setTradePositionSize:(PositionSize *)tradePositionSize
{
    _saveDataSource.tradePositionSize = tradePositionSize;
}

- (PositionSize *)tradePositionSize
{
    return _saveDataSource.tradePositionSize;
}

- (void)setStartBalance:(Money *)startBalance
{
    _saveDataSource.startBalance = startBalance;
}

- (Money *)startBalance
{
    return _saveDataSource.startBalance;
}

- (void)setIsAutoUpdate:(BOOL)isAutoUpdate
{
    _saveDataSource.isAutoUpdate = isAutoUpdate;
}

- (BOOL)isAutoUpdate
{
    return _saveDataSource.isAutoUpdate;
}

- (void)setAutoUpdateIntervalSeconds:(float)autoUpdateInterval
{
    _saveDataSource.autoUpdateIntervalSeconds = autoUpdateInterval;
}

- (float)autoUpdateIntervalSeconds
{
    return _saveDataSource.autoUpdateIntervalSeconds;
}

@end
