/*
 Copyright (C) 2012-2014 Soomla Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "UserProfileUtils.h"

@implementation UserProfileUtils

+ (NSArray*)availableProviders {
    return @[ @(FACEBOOK), @(GOOGLE), @(TWITTER), @(GAME_CENTER) ];
}

+ (NSString *)providerEnumToString:(Provider)provider {
    
    switch(provider) {
        case FACEBOOK:
            return @"facebook";
        case GOOGLE:
            return @"google";
        case TWITTER:
            return @"twitter";
        case GAME_CENTER:
            return @"gameCenter";
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return nil;
}

+ (NSString *)providerNumberToString:(NSNumber*)providerNumber {
    return [self providerEnumToString:(Provider) [providerNumber intValue]];
}

+ (Provider)providerStringToEnum:(NSString *)provider {
    Provider result;
    
    if ([provider isEqualToString:@"facebook"]) {
        result = FACEBOOK;
    } else if ([provider isEqualToString:@"google"]) {
        result = GOOGLE;
    } else if ([provider isEqualToString:@"twitter"]) {
        result = TWITTER;
    } else if ([provider isEqualToString:@"gameCenter"]) {
        result = GAME_CENTER;
    } else {
        [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return result;
}


@end
