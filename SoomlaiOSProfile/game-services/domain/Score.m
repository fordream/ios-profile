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

#import "Score.h"
#import "UserProfile.h"
#import "PJSONConsts.h"
#import "Leaderboard.h"


@implementation Score {

}

-(instancetype)initWithDictionary:(NSDictionary *)dict {
    if (self = [super init]) {
        self.rank = dict[UP_SCORE_RANK];
        self.leaderboard = [[Leaderboard alloc] initWithDictionary:dict[UP_LEADERBOARD]];
        self.player = [[UserProfile alloc] initWithDictionary:dict[UP_USER_PROFILE]];
        self.value = dict[UP_SCORE_VALUE];
    }
    return self;
}

-(NSDictionary *)toDictionary {
    return @{
            UP_SCORE_RANK:    self.rank,
            UP_LEADERBOARD:   self.leaderboard.toDictionary,
            UP_USER_PROFILE:  self.player.toDictionary,
            UP_SCORE_VALUE:   self.value
    };
}

@end