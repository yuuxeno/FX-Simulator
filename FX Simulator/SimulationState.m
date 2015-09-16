//
//  SimulationState.m
//  FX Simulator
//
//  Created by yuu on 2015/06/11.
//
//

#import "SimulationState.h"

#import "Account.h"
#import "ForexHistoryData.h"
#import "FXSAlert.h"
#import "Market.h"
#import "SimulationStateResult.h"

static NSString* const shortageAlertTitle = @"資産が足りません。";
static NSString* const chartEndAlertTitle = @"チャートが端まで読み込まれました。";

@implementation SimulationState {
    Account *_account;
    Market *_market;
}

-(instancetype)initWithAccount:(Account *)account Market:(Market *)market
{
    if (self = [super init]) {
        _account = account;
        _market = market;
    }
    
    return self;
}

- (SimulationStateResult *)isStop
{
    if ([_account isShortageForMarket:_market]) {
        return [[SimulationStateResult alloc] initWithIsStop:YES title:shortageAlertTitle message:nil];
    } else if ([_market didLoadLastData]) {
        return [[SimulationStateResult alloc] initWithIsStop:YES title:chartEndAlertTitle message:nil];
    }
    
    return [[SimulationStateResult alloc] initWithIsStop:NO title:nil message:nil];
}

/*-(void)shortage
{
    _isShortage = YES;
}*/

/*-(void)didLoadForexDataEnd
{
    _isForexDataEnd = YES;
}*/

/*- (void)showAlert:(UIViewController *)controller
{
    NSString *title;
    
    if (_isShortage) {
        title = shortageAlertTitle;
    } else if (_isForexDataEnd) {
        title = chartEndAlertTitle;
    }
    
    [FXSAlert showAlertTitle:title message:nil controller:controller];
}

-(void)updatedMarket
{    
    if ([_account isShortage]) {
        _isShortage = YES;
    }
    
    if ([_market didLoadLastData]) {
        _isForexDataEnd = YES;
    }
}

-(void)reset
{
    _isShortage = NO;
    _isForexDataEnd = NO;
}

-(BOOL)isStop
{
    if (_isShortage || _isForexDataEnd) {
        return YES;
    } else {
        return NO;
    }
}*/

@end
