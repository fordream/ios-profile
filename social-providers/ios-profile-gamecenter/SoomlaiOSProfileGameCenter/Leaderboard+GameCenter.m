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


#import "Leaderboard+GameCenter.h"


@implementation Leaderboard (GameCenter)

-(instancetype)initWithGamecenterLeaderboard:(GKLeaderboard *)leaderboard {
    if (self = [self initWithProvider:GAME_CENTER]) {
        _ID = leaderboard.identifier;
    }
    return self;
}

@end