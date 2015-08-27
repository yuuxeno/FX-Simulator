//
//  ForexData.m
//  ForexGame
//
//  Created  on 2014/03/23.
//  
//

#import "ForexHistory.h"

#import "MarketTime.h"
#import "TimeFrame.h"
#import "ForexDatabase.h"
#import "ForexDataChunk.h"
#import "ForexHistoryData.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "CurrencyPair.h"
#import "ForexHistoryUtils.h"
#import "Rate.h"


@implementation ForexHistory  {
    FMDatabase *forexDatabase;
    CurrencyPair *_currencyPair;
    TimeFrame *_timeScale;
    int _timeScaleInt;
    NSString *_forexHistoryTableName;
}

-(id)init
{
    if (self = [super init]) {
        forexDatabase = [ForexDatabase dbConnect];
    }
    
    return self;
}

-(id)initWithCurrencyPair:(CurrencyPair *)currencyPair timeScale:(TimeFrame*)timeScale
{
    if (currencyPair == nil || timeScale == nil) {
        DLog(@"CurrencyPair or TimeScale nil");
        return nil;
    }
    
    if (self = [self init]) {
        _currencyPair = currencyPair;
        _timeScale = timeScale;
        _timeScaleInt = timeScale.minute;
        _forexHistoryTableName = [ForexHistoryUtils createTableName:_currencyPair.toCodeString timeScale:_timeScaleInt];
    }
    
    return self;
}

- (ForexDataChunk *)selectBaseTime:(MarketTime *)time frontLimit:(NSUInteger)frontLimit backLimit:(NSUInteger)backLimit
{
    NSString *getFrontDataSql = [NSString stringWithFormat:@"SELECT rowid,* FROM (SELECT rowid,* FROM %@ WHERE ? <= close_minute_close_timestamp ORDER BY close_minute_close_timestamp ASC LIMIT ?) ORDER BY close_minute_close_timestamp DESC", _forexHistoryTableName];
    NSString *getBackDataSql = [NSString stringWithFormat:@"SELECT rowid,* FROM %@ WHERE close_minute_close_timestamp < ? ORDER BY close_minute_close_timestamp DESC LIMIT ?", _forexHistoryTableName];
    
    
    
    [forexDatabase open];
    
    /* get front array */
    
    FMResultSet *results = [forexDatabase executeQuery:getFrontDataSql, time.timestampValueObj, @(frontLimit+1)]; // +1 基準となる時間(time)のデータ自身を含む。
    
    NSMutableArray *frontArray = [NSMutableArray array];
    
    while ([results next]) {
        ForexHistoryData *data = [[ForexHistoryData alloc] initWithFMResultSet:results currencyPair:_currencyPair timeScale:_timeScale];
        [frontArray addObject:data];
    }
    
    /* get back array */
    
    FMResultSet *results2 = [forexDatabase executeQuery:getBackDataSql, time.timestampValueObj, @(backLimit)];
    
    NSMutableArray *backArray = [NSMutableArray array];
    
    while ([results2 next]) {
        ForexHistoryData *data = [[ForexHistoryData alloc] initWithFMResultSet:results2 currencyPair:_currencyPair timeScale:_timeScale];
        [backArray addObject:data];
    }
    
    [forexDatabase close];
    
    
    
    NSArray *array = [[frontArray arrayByAddingObjectsFromArray:backArray] copy];
    
    return [[ForexDataChunk alloc] initWithForexDataArray:array];
}

-(NSArray*)selectMaxCloseTime:(MarketTime *)closeTime limit:(NSUInteger)limit
{
    NSString *sql = [NSString stringWithFormat:@"SELECT rowid,* FROM %@ WHERE close_minute_close_timestamp <= ? ORDER BY close_minute_close_timestamp DESC LIMIT ?", _forexHistoryTableName];
    
    NSMutableArray *array = [NSMutableArray array];
    
    [forexDatabase open];
    
    FMResultSet *results = [forexDatabase executeQuery:sql, closeTime.timestampValueObj, @(limit)];
    
    while ([results next]) {
        ForexHistoryData *data = [[ForexHistoryData alloc] initWithFMResultSet:results currencyPair:_currencyPair timeScale:_timeScale];
        [array addObject:data];
    }
    
    [forexDatabase close];
    
    return [array copy];
}

- (ForexDataChunk *)selectMaxCloseTime:(MarketTime *)closeTime newerThan:(MarketTime *)oldCloseTime
{
    NSString *sql = [NSString stringWithFormat:@"SELECT rowid,* FROM %@ WHERE close_minute_close_timestamp <= ? AND ? < close_minute_close_timestamp ORDER BY close_minute_close_timestamp DESC", _forexHistoryTableName];
    
    NSMutableArray *array = [NSMutableArray array];
    
    [forexDatabase open];
    
    FMResultSet *results = [forexDatabase executeQuery:sql, closeTime.timestampValueObj, oldCloseTime.timestampValueObj];
    
    while ([results next]) {
        ForexHistoryData *data = [[ForexHistoryData alloc] initWithFMResultSet:results currencyPair:_currencyPair timeScale:_timeScale];
        [array addObject:data];
    }
    
    [forexDatabase close];
    
    return [[ForexDataChunk alloc] initWithForexDataArray:array];
}

-(MarketTime*)minOpenTime
{
    return [self firstRecord].open.timestamp;
}

-(MarketTime*)maxOpenTime
{
    return [self lastRecord].close.timestamp;
}

-(ForexHistoryData*)firstRecord
{
    ForexHistoryData *data;
    
    NSString *sql = [NSString stringWithFormat:@"select rowid,* from %@ limit 1;", _forexHistoryTableName];
    
    [forexDatabase open];
    
    FMResultSet *results = [forexDatabase executeQuery:sql];
    
    while ([results next]) {
        data = [[ForexHistoryData alloc] initWithFMResultSet:results currencyPair:_currencyPair timeScale:_timeScale];
    }
    
    [forexDatabase close];
    
    return data;
}

-(ForexHistoryData*)lastRecord
{
    ForexHistoryData *data;
    
    NSString *sql = [NSString stringWithFormat:@"select rowid,* from %@ order by rowid desc limit 1;", _forexHistoryTableName];
    
    [forexDatabase open];
    
    FMResultSet *results = [forexDatabase executeQuery:sql];
    
    while ([results next]) {
        data = [[ForexHistoryData alloc] initWithFMResultSet:results currencyPair:_currencyPair timeScale:_timeScale];
    }
    
    [forexDatabase close];
    
    return data;
}

@end
