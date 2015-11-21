/*
 Copyright (C) 2012-2015 Soomla Inc.

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

#import "Leaderboard.h"
#import "PJSONConsts.h"


@implementation Leaderboard {

}

-(instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super initWithDictionary:dict]) {
        self.identifier = dict[UP_IDENTIFIER];
    }
    return self;
}

-(NSDictionary *)toDictionary {
    NSMutableDictionary *result = [[super toDictionary] mutableCopy];
    [result addEntriesFromDictionary:@{
            UP_IDENTIFIER : self.identifier?: [NSNull null]
    }];
    return result;
}

@end