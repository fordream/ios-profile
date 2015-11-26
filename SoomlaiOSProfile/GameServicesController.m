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

#import <Reward.h>
#import "GameServicesController.h"
#import "IGameServicesProvider.h"
#import "ProfileEventHandling.h"
#import "SoomlaUtils.h"
#import "Leaderboard.h"
#import "Score.h"


@implementation GameServicesController

static NSString* TAG = @"SOOMLA GameServicesController";

- (id)initWithParameters:(NSDictionary *)providerParams {
    if (self = [super init]) {

        // TODO: Check if providerPkgPrefix can be omitted completely in iOS
        if (![self loadProvidersWithProtocol:@protocol(IGameServicesProvider) andProviderParams:providerParams]) {
            NSString* msg = @"You don't have a IGameServicesProvider service attached. \
                            Decide which IAuthProvider you want, and add its static libraries \
                            and headers to the target's search path.";
            LogDebug(TAG, msg);
        } else {

        }
    }

    return self;
}

- (id)initWithoutLoadingProviders {
    if (self = [super init]) {

    }
    return self;
}

-(void)getContactsWith:(Provider)provider andFromStart:(BOOL)fromStart andPayload:(NSString *)payload andReward:(Reward *)reward {

    id<IGameServicesProvider> gsProvider = (id<IGameServicesProvider>)[self getProvider:provider];

    // Perform get contacts process
    [ProfileEventHandling postGetContactsStarted:provider withType:GET_CONTACTS withFromStart:fromStart withPayload:payload];

    [gsProvider getContacts:fromStart
                    success:^(NSArray *contacts, BOOL hasMore) {
                        if (reward) {
                            [reward give];
                        }
                        [ProfileEventHandling postGetContactsFinished:provider
                                                             withType:GET_CONTACTS
                                                         withContacts:contacts
                                                          withPayload:payload
                                                          withHasMore:hasMore];

                    } fail:^(NSString *message) {
                [ProfileEventHandling postGetContactsFailed:provider
                                                   withType:GET_CONTACTS
                                                withMessage:message
                                              withFromStart:fromStart
                                                withPayload:payload];
            }];
}

-(void)getLeaderboardsWithProvider:(Provider)provider payload:(NSString *)payload andReward:(Reward *)reward {
    id<IGameServicesProvider> gsProvider = (id<IGameServicesProvider>)[self getProvider:provider];

    [ProfileEventHandling postGetLeaderboardsStarted:provider withPayload:payload];
    [gsProvider getLeaderboardsWithSuccess:^(NSArray *leaderboards, BOOL hasMore) {
        if (reward) {
            [reward give];
        }
        [ProfileEventHandling postGetLeaderboardsFinished:provider withLeaderboardsList:leaderboards andPayload:payload];
    } fail:^(NSString *message) {
        [ProfileEventHandling postGetLeaderboardsFailed:provider withMessage:message andPayload:payload];
    }];
}

-(void)getScoresWithProvider:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard andFromStart:(BOOL)fromStart payload:(NSString *)payload andReward:(Reward *)reward {

    id<IGameServicesProvider> gsProvider = (id<IGameServicesProvider>)[self getProvider:provider];

    [ProfileEventHandling postGetScoresStarted:provider forLeaderboard:leaderboard fromStart:fromStart withPayload:payload];
    [gsProvider getScoresFromLeaderboard:leaderboard.ID fromStart:fromStart withSuccess:^(NSArray *result, BOOL hasMore) {
        if (reward) {
            [reward give];
        }
        for (Score *sc in result) {
            sc.leaderboard = leaderboard;
        }
        [ProfileEventHandling postGetScoresFinished:provider forLeaderboard:leaderboard withScoresList:result hasMore:hasMore andPayload:payload];
    }                               fail:^(NSString *message) {
        [ProfileEventHandling postGetScoresFailed:provider forLeaderboard:leaderboard fromStart:fromStart withMessage:message andPayload:payload];
    }];
}

-(void)reportScoreWithProvider:(Provider)provider score:(NSNumber *)score forLeaderboard:(Leaderboard *)leaderboard payload:(NSString *)payload andReward:(Reward *)reward {

    id<IGameServicesProvider> gsProvider = (id<IGameServicesProvider>)[self getProvider:provider];

    [ProfileEventHandling postReportScoreStarted:provider forLeaderboard:leaderboard withPayload:payload];
    [gsProvider reportScore:score forLeaderboard:leaderboard.ID withSuccess:^(Score *newScore) {
        if (reward) {
            [reward give];
        }
        newScore.leaderboard = leaderboard;
        [ProfileEventHandling postReportScoreFinished:provider score:newScore forLeaderboard:leaderboard andPayload:payload];
    } fail:^(NSString *message) {
        [ProfileEventHandling postReportScoreFailed:provider forLeaderboard:leaderboard withMessage:message andPayload:payload];
    }];
}

@end