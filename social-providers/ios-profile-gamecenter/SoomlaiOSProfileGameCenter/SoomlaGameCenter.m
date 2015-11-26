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

#import "SoomlaGameCenter.h"
#import "UserProfile.h"
#import "Leaderboard+GameCenter.h"
#import "Score+GameCenter.h"

@implementation SoomlaGameCenter {
    BOOL _autoLogin;

    NSMutableDictionary *_scoresOffsets;
}

const NSUInteger DEFAULT_OFFSET = 25;

const Provider currentProvider = GAME_CENTER;

/**
 Applies special initialization parameters to the provider

 @param providerParams the parameters needed by the provider to initialize
 */
- (void)applyParams:(NSDictionary *)providerParams {
    if (providerParams) {
        _autoLogin = providerParams[@"autoLogin"] != nil ? [providerParams[@"autoLogin"] boolValue] : NO;
    } else {
        _autoLogin = NO;
    }

    _scoresOffsets = [NSMutableDictionary new];
}

/**
 Retrieves the `Provider` value of the provider it implements
 @return the `Provider` value of the provider it implements
 */
- (Provider)getProvider {
    return currentProvider;
}


#pragma mark IGameServicesProvider methods

/**
 Logs in with the authentication provider

 @param sucesss a login sucess callback
 @param fail a login failure callback
 @param cancel a login cancelled callback
 */
- (void)login:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel {
    [[GKLocalPlayer localPlayer] setAuthenticateHandler:^(UIViewController *viewController, NSError *error) {
        if (error != nil) {
            if (fail != nil) {
                fail(error.localizedDescription);
            }
            return;
        }
        if (viewController != nil)
        {
            if ([UIApplication sharedApplication].keyWindow.rootViewController) {
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:viewController animated:YES completion:nil];
            }
        }
        else if ([GKLocalPlayer localPlayer].isAuthenticated) {
            if (success != nil) {
                success(currentProvider);
            }
        } else {
            if (cancel != nil) {
                cancel();
            }
        }
    }];
}

/**
 Fetches the user profile from the authentication provider

 @param sucesss a fetch sucess callback
 @param fail a fetch failure callback
 */
- (void)getUserProfile:(userProfileSuccess)success fail:(userProfileFail)fail {
    NSString *playerId = [GKLocalPlayer localPlayer].playerID;
    if (playerId != nil) {
        [GKPlayer loadPlayersForIdentifiers:@[playerId] withCompletionHandler:^(NSArray *players, NSError *error) {
            if (players.count) {
                if (success != nil) {
                    success([[self class] userProfileFromGameKitPlayer:((GKPlayer *)players[0])]);
                }
            } else {
                if (fail != nil) {
                    fail(@"Cannot read profile: playerID is incorrect.");
                }
            }
        }];
    } else {
        if (fail != nil) {
            fail(@"Cannot read profile: user ins't authenticated.");
        }
    }
}

+(UserProfile *)userProfileFromGameKitPlayer:(GKPlayer *)player {
    NSString *firstName = nil;
    NSString *lastName = nil;
    if ([player.displayName componentsSeparatedByString:@" "].count == 2) {
        firstName = [[player.displayName componentsSeparatedByString:@" "] firstObject];
        lastName = [[player.displayName componentsSeparatedByString:@" "] lastObject];
    } else if ([player.alias componentsSeparatedByString:@" "].count == 2) {
        firstName = [[player.alias componentsSeparatedByString:@" "] firstObject];
        lastName = [[player.alias componentsSeparatedByString:@" "] lastObject];
    }
    return [[UserProfile alloc] initWithProvider:currentProvider andProfileId:player.playerID andUsername:player.alias
                                        andEmail:@"" andFirstName:(firstName ? firstName : @"")
                                     andLastName:(lastName ? lastName : @"") andExtra:nil];
}

/**
 Logs out of the authentication provider

 @param sucesss a logout sucess callback
 @param fail a logout failure callback
 */
- (void)logout:(logoutSuccess)success fail:(logoutFail)fail {
    fail(@"GameCenter doesn't support logging out.");
}

/**
 Checks if the user is logged-in using the authentication provider

 @return YES if the user is already logged-in using the authentication provider,
 NO otherwise
 */
- (BOOL)isLoggedIn {
    return [GKLocalPlayer localPlayer].authenticated;
}

/**
* Return value of autoLogin setting of the provider.
* @return value of autoLogin
*/
- (BOOL)isAutoLogin {
    return _autoLogin;
}

/**
 Helper method to assist with browser-based authentication for the provider.
 Based on the URL scheme defined for the provider, it will try and handle the
 callback of browser authentication

 @param url The URL which caused the application to launch and receive a
 callback
 @param sourceApplication The bundle ID of the app that is requesting your app
 to open the URL (url).
 @param annotation A property list object supplied by the source app to
 communicate information to the receiving app.

 @return YES if the provider was able to handle the URL, NO otherwise
 */
- (BOOL)tryHandleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return NO;
}

#pragma mark IGameServicesProvider methods

/**
 Fetches the user's contact list

 @param fromStart Should we reset pagination or request the next page
 @param success a contacts fetch success callback
 @param fail a contacts fetch failure callback
 */
-(void)getContacts:(BOOL)fromStart success:(successWithArrayHandler)success fail:(failureHandler)fail {
    [[GKLocalPlayer localPlayer] loadFriendPlayersWithCompletionHandler:^(NSArray *friendPlayers, NSError *error) {
        if (error == nil) {
            NSMutableArray *result = [NSMutableArray new];
            for (GKPlayer *player in friendPlayers) {
                UserProfile *parsedProfile = [[self class] userProfileFromGameKitPlayer:player];
                if (parsedProfile) {
                    [result addObject:parsedProfile];
                }
            }
            success(result, NO);
        } else {
            fail(error.localizedDescription);
        }
    }];
}

/**
 Fetches the game's leaderboards list

 @param success a leaderboards fetch success callback
 @param fail a leaderboards fetch failure callback
 */
-(void)getLeaderboardsWithSuccess:(successWithArrayHandler)success fail:(failureHandler)fail {
    [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
        if (error == nil) {
            NSMutableArray *result = [NSMutableArray new];
            for (GKLeaderboard *leaderboard in leaderboards) {
                Leaderboard *ourLeaderboard = [[Leaderboard alloc] initWithGamecenterLeaderboard:leaderboard];
                if (ourLeaderboard) {
                    [result addObject:ourLeaderboard];
                }
            }
            success(result, NO);
        } else {
            fail(error.localizedDescription);
        }
    }];
}

/**
 Fetches the game's scores list from specified leaderboard

 @param leaderboardId Leaderboard containing desired scores list
 @param fromStart Should we reset pagination or request the next page
 @param success a scores fetch success callback
 @param fail a scores fetch failure callback
 */
-(void)getScoresFromLeaderboard:(NSString *)leaderboardId fromStart:(BOOL)fromStart withSuccess:(successWithArrayHandler)success fail:(failureHandler)fail {
    [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
        if (error == nil) {
            GKLeaderboard *currentLeaderboard = nil;
            for (GKLeaderboard *lb in leaderboards) {
                if ([lb.identifier isEqualToString:leaderboardId]) {
                    currentLeaderboard = lb;
                    break;
                }
            }
            if (currentLeaderboard) {
                if (!_scoresOffsets[leaderboardId] || fromStart) {
                    _scoresOffsets[leaderboardId] = @1;
                }
                currentLeaderboard.range = NSMakeRange([_scoresOffsets[leaderboardId] unsignedIntegerValue], DEFAULT_OFFSET);
                [currentLeaderboard loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
                    if (error == nil) {
                        NSMutableArray *result = [NSMutableArray new];
                        for (GKScore *score in scores) {
                            Score *ourScore = [[Score alloc] initWithGamecenterScore:score];
                            if (ourScore) {
                                [result addObject:ourScore];
                            }
                        }
                        if (result.count == DEFAULT_OFFSET) {
                            _scoresOffsets[leaderboardId] = @([_scoresOffsets[leaderboardId] unsignedIntegerValue] + DEFAULT_OFFSET);
                        }
                        success(result, result.count == DEFAULT_OFFSET);
                    } else {
                        fail(error.localizedDescription);
                    }
                }];
            } else {
                fail(@"Leaderboard with specified identifier not found.");
            }
        } else {
            fail(error.localizedDescription);
        }
    }];
}

/**
 Reports scores for specified leaderboard

 @param score Value to report
 @param leaderboardId Target leaderboard
 @param success a score report success callback
 @param fail a score report failure callback
 */
-(void)reportScore:(NSNumber *)score forLeaderboard:(NSString *)leaderboardId withSuccess:(reportScoreSuccessHandler)success fail:(failureHandler)fail {
    GKScore *newScore = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboardId];
    newScore.value = score.longLongValue;
    newScore.context = 0;

    [GKScore reportScores:@[newScore] withCompletionHandler:^(NSError *error) {
        if (error == nil) {
            success([[Score alloc] initWithGamecenterScore:newScore]);
        } else {
            fail(error.localizedDescription);
        }
    }];
}

@end
