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

#import "IAuthProvider.h"
#import "IGameServicesCallbacks.h"

/**
 A provider that exposes game services capabilities such as leaderboards, achievements, challenges and scoring
 */

@protocol IGameServicesProvider <IAuthProvider>

/**
 Fetches the user's contact list

 @param fromStart Should we reset pagination or request the next page
 @param success a contacts fetch success callback
 @param fail a contacts fetch failure callback
 */
-(void)getContacts:(BOOL)fromStart success:(successWithArrayHandler)success fail:(failureHandler)fail;

/**
 Fetches the game's leaderboards list

 @param success a leaderboards fetch success callback
 @param fail a leaderboards fetch failure callback
 */
-(void)getLeaderboardsWithSuccess:(successWithArrayHandler)success fail:(failureHandler)fail;

/**
 Fetches the game's scores list from specified leaderboard

 @param leaderboardId Leaderboard containing desired scores list
 @param fromStart Should we reset pagination or request the next page
 @param success a scores fetch success callback
 @param fail a scores fetch failure callback
 */
-(void)getScoresFromLeaderboard:(NSString *)leaderboardId
                      fromStart:(BOOL)fromStart
                    withSuccess:(successWithArrayHandler)success
                           fail:(failureHandler)fail;

/**
 Reports scores for specified leaderboard

 @param score Value to report
 @param leaderboardId Target leaderboard
 @param success a score report success callback
 @param fail a score report failure callback
 */
-(void)reportScore:(NSNumber *)score
    forLeaderboard:(NSString *)leaderboardId
       withSuccess:(reportScoreSuccessHandler)success
              fail:(failureHandler)fail;

@end
