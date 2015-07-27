//
//  ChartSourceTests.m
//  FX Simulator
//
//  Created by yuu on 2015/07/18.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "Candle.h"
#import "CandlePlistSource.h"
#import "ChartPlistSource.h"
#import "CurrencyPair.h"
#import "TimeFrame.h"

@interface ChartSourceTests : XCTestCase

@end

@implementation ChartSourceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testInitWithDefaultAndChartIndex {
    NSUInteger chartIndex = 0;
    CurrencyPair *currencyPair = [[CurrencyPair alloc] initWithCurrencyPairString:@"EURUSD"];
    TimeFrame *timeScale = [[TimeFrame alloc] initWithMinute:15];
    BOOL isMainChart = YES;
    BOOL isSubChart = NO;
    
    ChartPlistSource *source = [[ChartPlistSource alloc] initWithDefaultAndChartIndex:chartIndex currencyPair:currencyPair timeScale:timeScale isMainChart:isMainChart isSubChart:isSubChart];
    
    Candle *defaultIndicator = [[Candle alloc] initWithCandleSource:[[CandlePlistSource alloc] initWithDefault]];
    NSDictionary *chartSourceDictionary = @{@"ChartIndex":@(chartIndex), @"TimeScale":timeScale.minuteValueObj, @"IsMainChart":@(isMainChart), @"IndicatorSourceDictionaryArray":defaultIndicator.sourceDictionary};
    
    XCTAssertEqualObjects(chartSourceDictionary, source.sourceDictionary);
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
