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

#import <Foundation/Foundation.h>
#import <SoomlaEntity.h>
#import "UserProfileUtils.h"


@interface Leaderboard : NSObject {
    @protected
        NSString *_ID;
}

@property (retain, nonatomic, readonly) NSString* ID;
@property (readonly, nonatomic) Provider provider;

/**
 Constructor

 @param oProvider the provider which the leaderboard's data is associated to
 */
-(instancetype)initWithProvider:(Provider)oProvider;

/**
 Constructor.
 Generates an instance of `Leaderboard` from an `NSDictionary`.

 @param dict An `NSDictionary` representation of the wanted `Leaderboard`.
 */
- (id)initWithDictionary:(NSDictionary*)dict;

/**
 Converts the current `Leaderboard` to an `NSDictionary`.

 @return This instance of Leaderboard as an `NSDictionary`.
 */
- (NSDictionary*)toDictionary;

@end