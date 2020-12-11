//
//  ObjcExample.m
//  TelenavDemo
//
//  Created by ezaderiy on 09.11.2020.
//

#import "ObjcExample.h"
#import "TelenavDemo-Swift.h"
@import TelenavEntitySDK;

@implementation ObjcExample

- (void)test {
    
    TNEntitySearchParams *params = [[[[TNEntitySearchQueryBuilder new] query:@"food"] location:[TNEntityGeoPoint pointWithLat:0 lon:0] ] build];
    
    [TNEntityCore searchWithSearchParams:params completion:^(TNEntitySearchResult * _Nullable res, NSError * _Nullable err) {
        
    }];
}

@end
