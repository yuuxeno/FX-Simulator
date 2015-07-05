//
//  Setting.h
//  FX Simulator
//
//  Created  on 2014/12/02.
//  
//

#import <Foundation/Foundation.h>

@class CurrencyPair;
@class FXSTimeRange;
@class MarketTime;
@class MarketTimeScale;
@class Rate;


/**
 新たなシュミレーション対象の通貨ペアを増やしたり、時間軸、口座通貨を増やしたりするときは、この設定クラスを変更する。
**/

@interface Setting : NSObject
+(BOOL)isLocaleJapanese;
/**
 シュミレーション対象の通貨リスト。新たにシュミレートできる通貨を増やす場合、手動で追加する必要。
 Localeによって配列の並び順が違う。
*/
+(NSArray*)currencyPairList;
/**
 シュミレーション対象の通貨リスト。新たにシュミレートできる通貨を増やす場合、手動で追加する必要。
 並び順はLocaleが違っても同じ。
 */
+(NSDictionary*)currencyPairDictionaryList;
/**
 シュミレーション対象の時間軸(15分足など)リスト。新たにシュミレートできる時間軸を増やす場合、手動で追加する必要。
 */
+(NSArray*)timeScaleList;
/**
 口座通貨に使うことができる通貨のリスト。ドル建て、円建てなど。
 Localeによって並び順が違う。
*/
+(NSArray*)accountCurrencyList;
/**
 1pipが何レートか。例 USD/JPY 1pip = 0.01円
*/
+(Rate*)onePipValueOfCurrencyPair:(CurrencyPair*)currencyPair;
+(NSString*)toStringFromRate:(Rate*)rate;
/**
 通貨の変換などに使うレート。例 USD/JPY １ドル = 100円
*/
+(Rate*)baseRateOfCurrencyPair:(CurrencyPair*)currencyPair;
/**
 その通貨と時間軸で、シュミレーションを開始できる時間の範囲。
*/
+(FXSTimeRange*)rangeForCurrencyPair:(CurrencyPair*)currencyPair timeScale:(MarketTimeScale*)timeScale;
/**
 ChartView(SubChart含む)に表示するForexDataの最大数。
*/
+ (NSUInteger)maxDisplayForexDataCountOfChartView;
/**
 インジケーターに使える、最大の期間。
*/
+ (NSUInteger)maxIndicatorTerm;
@end
