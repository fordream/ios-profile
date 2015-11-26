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
#import "AuthController.h"

@class Leaderboard;

/**
 A class that loads all game services providers and performs specified
 actions on with them.

 Inheritance: GameServicesController > AuthController > ProviderLoader
 */
@interface GameServicesController : AuthController

/**
 Constructor

 Loads all game services providers
 @param providerParams Special initialization parameters for loaded providers
 */
-(id)initWithParameters:(NSDictionary *)providerParams;

/**
 Fetches the user's contact list

 @param provider The provider to use
 @param fromStart Should we reset pagination or request the next page
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
-(void)getContactsWith:(Provider)provider andFromStart:(BOOL)fromStart andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the game's leaderboards list

 @param provider The provider to use
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
-(void)getLeaderboardsWithProvider:(Provider)provider payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the game's scores list from specified leaderboard

 @param provider The provider to use
 @param leaderboard Leaderboard containing desired scores list
 @param fromStart Should we reset pagination or request the next page
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
-(void)getScoresWithProvider:(Provider)provider
              forLeaderboard:(Leaderboard *)leaderboard
                andFromStart:(BOOL)fromStart
                     payload:(NSString *)payload
                   andReward:(Reward *)reward;

/**
 Reports scores for specified leaderboard

 @param provider The provider to use
 @param score Value to report
 @param leaderboard Target leaderboard
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
-(void)reportScoreWithProvider:(Provider)provider
                         score:(NSNumber *)score
                forLeaderboard:(Leaderboard *)leaderboard
                       payload:(NSString *)payload
                     andReward:(Reward *)reward;

@end