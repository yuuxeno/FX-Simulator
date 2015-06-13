//
//  OrderManager.m
//  FX Simulator
//
//  Created  on 2014/09/11.
//  
//

#import "OrderManager.h"

#import "UsersOrder.h"
#import "OrderHistoryFactory.h"
#import "OrderHistory.h"
#import "OrderManagerState.h"
#import "ExecutionOrderMaterial.h"
#import "ExecutionOrdersFactory.h"
#import "ExecutionOrdersManager.h"

@implementation OrderManager {
    OrderHistory *_orderHistory;
    OrderManagerState *_orderManagerState;
    ExecutionOrdersFactory *_executionOrdersFactory;
    ExecutionOrdersManager *_executionOrdersManager;
}

/*-(id)init
{
    if (self = [super init]) {
        orderHistory = [OrderHistoryFactory createOrderHistory];
        executionOrdersFactory = [ExecutionOrdersFactory new];
        executionOrdersManager = [ExecutionOrdersManager new];
    }
    
    return self;
}*/

-(id)initWithOrderHistory:(OrderHistory *)orderHistory executionOrdersFactory:(ExecutionOrdersFactory *)executionOrdersFactory executionOrdersManager:(ExecutionOrdersManager *)executionOrdersManager
{
    if (self = [super init]) {
        _orderHistory = orderHistory;
        _orderManagerState = [OrderManagerState new];
        _executionOrdersFactory = executionOrdersFactory;
        _executionOrdersManager = executionOrdersManager;
    }
    
    return self;
}

-(BOOL)execute:(UsersOrder*)order
{
    //if (!order.isValid) {
        /*NSDictionary *errorDic = @{
                                   NSLocalizedDescriptionKey:@"Order Invalid",
                                NSLocalizedRecoverySuggestionErrorKey:@"You can set numberB except zero"
                                   };
        *anError = [[NSError alloc] initWithDomain:domain code:0 userInfo:errorDic];*/
        
        //return false;
    //}
    
    [_orderManagerState updateState:order];
    
    if (![_orderManagerState isExecutable]) {
        [_orderManagerState showAlert:self.alertTarget];
        return NO;
    }
    
    
    int orderNumber = [_orderHistory saveUsersOrder:order];
    
    if (orderNumber < 1) {
        return false;
    }
    
    ExecutionOrderMaterial *material = [[ExecutionOrderMaterial alloc] initWithOrder:order usersOrderNumber:orderNumber];
    
    NSArray *executionOrders = [_executionOrdersFactory create:material];
    
    [_executionOrdersManager executeOrders:executionOrders];
    
    return true;
}

@end
