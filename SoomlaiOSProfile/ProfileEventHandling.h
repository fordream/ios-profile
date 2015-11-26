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
#import "SocialActionUtils.h"

@class UserProfile;
@class Reward;
@class Leaderboard;
@class Score;

// Events
#define EVENT_UP_PROFILE_INITIALIZED            @"up_profile_initialized"

#define EVENT_UP_USER_PROFILE_UPDATED           @"up_user_profile_updated"

#define EVENT_UP_USER_RATING                    @"up_user_rating"

#define EVENT_UP_LOGIN_STARTED                  @"up_login_started"
#define EVENT_UP_LOGIN_FINISHED                 @"up_login_finished"
#define EVENT_UP_LOGIN_FAILED                   @"up_login_failed"
#define EVENT_UP_LOGIN_CANCELLED                @"up_login_cancelled"

#define EVENT_UP_LOGOUT_STARTED                 @"up_logout_started"
#define EVENT_UP_LOGOUT_FINISHED                @"up_logout_finished"
#define EVENT_UP_LOGOUT_FAILED                  @"up_logout_failed"

#define EVENT_UP_SOCIAL_ACTION_STARTED          @"up_social_action_started"
#define EVENT_UP_SOCIAL_ACTION_FINISHED         @"up_social_action_finished"
#define EVENT_UP_SOCIAL_ACTION_CANCELLED        @"up_social_action_cancelled"
#define EVENT_UP_SOCIAL_ACTION_FAILED           @"up_social_action_failed"

#define EVENT_UP_GET_CONTACTS_STARTED           @"up_get_contacts_started"
#define EVENT_UP_GET_CONTACTS_FINISHED          @"up_get_contacts_finished"
#define EVENT_UP_GET_CONTACTS_FAILED            @"up_get_contacts_failed"

#define EVENT_UP_GET_FEED_STARTED               @"up_get_feed_started"
#define EVENT_UP_GET_FEED_FINISHED              @"up_get_feed_finished"
#define EVENT_UP_GET_FEED_FAILED                @"up_get_feed_failed"

#define EVENT_UP_INVITE_STARTED                 @"up_invite_started"
#define EVENT_UP_INVITE_FINISHED                @"up_invite_finished"
#define EVENT_UP_INVITE_CANCELLED               @"up_invite_cancelled"
#define EVENT_UP_INVITE_FAILED                  @"up_invite_failed"

#define EVENT_UP_GET_LEADERBOARDS_STARTED       @"up_get_leaderboards_started"
#define EVENT_UP_GET_LEADERBOARDS_FINISHED      @"up_get_leaderboards_finished"
#define EVENT_UP_GET_LEADERBOARDS_FAILED        @"up_get_leaderboards_failed"

#define EVENT_UP_GET_SCORES_STARTED             @"up_get_scores_started"
#define EVENT_UP_GET_SCORES_FINISHED            @"up_get_scores_finished"
#define EVENT_UP_GET_SCORES_FAILED              @"up_get_scores_failed"

#define EVENT_UP_REPORT_SCORE_STARTED           @"up_report_score_started"
#define EVENT_UP_REPORT_SCORE_FINISHED          @"up_report_score_finished"
#define EVENT_UP_REPORT_SCORE_FAILED            @"up_report_score_failed"

// UserProfile Elements
#define DICT_ELEMENT_USER_PROFILE               @"userProfile"
#define DICT_ELEMENT_PROVIDER                   @"provider"
#define DICT_ELEMENT_FROM_START                 @"fromStart"
#define DICT_ELEMENT_AUTO_LOGIN                 @"autoLogin"
#define DICT_ELEMENT_PAYLOAD                    @"payload"
#define DICT_ELEMENT_HAS_MORE                   @"hasMore"
#define DICT_ELEMENT_SOCIAL_ACTION_TYPE         @"socialActiontype"
#define DICT_ELEMENT_MESSAGE                    @"message"
#define DICT_ELEMENT_CONTACTS                   @"contacts"
#define DICT_ELEMENT_FEEDS                      @"feeds"
#define DICT_ELEMENT_LEADERBOARDS               @"leaderboards"
#define DICT_ELEMENT_LEADERBOARD                @"leaderboard"
#define DICT_ELEMENT_SCORES                     @"scores"
#define DICT_ELEMENT_SCORE                      @"score"
#define DICT_ELEMENT_REQUEST_ID                 @"requestId"
#define DICT_ELEMENT_INVITED_LIST               @"invitedIds"
#define DICT_ELEMENT_REWARD                     @"reward"
#define DICT_ELEMENT_IS_BADGE                   @"isBadge"

/**
 * This class is used to register and post all the supported profile events.
 * Use this class to invoke events on handlers when they occur.
 *
 * SOOMLA uses iOS's `NSNotificationCenter` to handle events across the SDK.
 */
@interface ProfileEventHandling : NSObject

/**
 Subscribes the provider observer to all the profile events at once, 
 the supplied selector will be called when any of the events fired
 
 @param observer the subscriber to the events
 @param selector the selector to call on the observer when events are fired
 */
+ (void)observeAllEventsWithObserver:(id)observer withSelector:(SEL)selector;

/**
Called when the service has been initializedt.
*/
+ (void)postProfileInitialized;

/**
 Called when the app's rating page is opened
 */
+ (void)postUserRating;

/**
 Called when a user profile from a provider has been retrieved
 and updated in the device's local storage. Which fires the 
 `EVENT_UP_USER_PROFILE_UPDATED` event.
 
 @param userProfile The user's profile which was updated
 */
+ (void)postUserProfileUpdated:(UserProfile *)userProfile;

/**
 Called when the login process to a provider has started. Which fires the
 `EVENT_UP_LOGIN_STARTED` event.
 
 @param provider The provider on where the login has started
 */
+ (void)postLoginStarted:(Provider)provider withAutoLogin:(BOOL)autoLogin andPayload:(NSString *)payload;

/**
 Called when the login process finishes successfully. Which fires the
 `EVENT_UP_LOGIN_FINISHED` event.
 
 @param userProfile The user's profile from the logged in provider
 */
+ (void)postLoginFinished:(UserProfile *)userProfile withAutoLogin:(BOOL)autoLogin andPayload:(NSString *)payload;

/**
 Called when the login process to a provider has failed. Which fires the
 `EVENT_UP_LOGIN_FAILED` event.
 
 @param provider The provider on which the login has failed
 @param message a Description of the reason for failure
 */
+ (void)postLoginFailed:(Provider)provider withMessage:(NSString *)message andAutoLogin:(BOOL)autoLogin andPayload:(NSString *)payload;

/**
 Called the login process to a provider has been cancelled. Which fires the
 `EVENT_UP_LOGIN_CANCELLED` event.
 
 @param provider The provider on which the login has failed
 */
+ (void)postLoginCancelled:(Provider)provider withAutoLogin:(BOOL)autoLogin andPayload:(NSString *)payload;

/**
 Called when the logout process from a provider has started. Which fires the
 `EVENT_UP_LOGOUT_STARTED` event.
 
 @param provider The provider on which the login has started.
 */
+ (void)postLogoutStarted:(Provider)provider;

/**
 Called when the logout process from a provider has finished. Which fires the
 `EVENT_UP_LOGOUT_FINISHED` event.
 
 @param provider The provider on which the logout has finished
 */
+ (void)postLogoutFinished:(Provider)provider;

/**
 Called when the logout process from a provider has failed. Which fires the
 `EVENT_UP_LOGOUT_FAILED` event.
 
 @param provider The provider on which the logout has failed
 @param message a Description of the reason for failure
 */
+ (void)postLogoutFailed:(Provider)provider withMessage:(NSString *)message;

/**
 Called when a generic social action on a provider has started. Which fires the
 `EVENT_UP_SOCIAL_ACTION_STARTED` event.
 
 @param provider The provider on which the social action has started
 @param socialActionType The social action which started
 */
+ (void)postSocialActionStarted:(Provider)provider withType:(SocialActionType)socialActionType withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has finished. Which fires the
 `EVENT_UP_SOCIAL_ACTION_FINISHED` event.
 
 @param provider The provider on which the social action has finished
 @param socialActionType The social action which finished
 */
+ (void)postSocialActionFinished:(Provider)provider withType:(SocialActionType)socialActionType withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has been cancelled. Which fires 
 the `EVENT_UP_SOCIAL_ACTION_CANCELLED` event.
 
 @param provider The provider on which the social action has been cancelled
 @param socialActionType The social action which was cancelled
 */
+ (void)postSocialActionCancelled:(Provider)provider withType:(SocialActionType)socialActionType withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has failed. Which fires the
 `EVENT_UP_SOCIAL_ACTION_FAILED` event.
 
 @param provider The provider on which the social action has failed
 @param socialActionType The social action which failed
 @param message a Description of the reason for failure
 */
+ (void)postSocialActionFailed:(Provider)provider withType:(SocialActionType)socialActionType withMessage:(NSString *)message withPayload:(NSString *)payload;

/**
 Called when the get contacts process from a provider has started. Which fires the
 `EVENT_UP_GET_CONTACTS_STARTED` event.
 
 @param provider The provider on which the get contacts process started
 @param socialActionType The social action which is preformed
 */
+ (void)postGetContactsStarted:(Provider)provider withType:(SocialActionType)socialActionType withFromStart:(bool)fromStart withPayload:(NSString *)payload;

/**
 Called when the get contacts process from a provider has finished. Which fires the
 `EVENT_UP_GET_CONTACTS_FINISHED` event.
 
 @param provider The provider on which the get contacts process finished
 @param socialActionType The social action which is preformed
 @param contacts an Array of contacts represented by `UserProfile`
 */
+ (void)postGetContactsFinished:(Provider)provider withType:(SocialActionType)socialActionType withContacts:(NSArray *)contacts withPayload:(NSString *)payload withHasMore:(bool)hasMore;

/**
 Called when the get contacts process from a provider has failed. Which fires the
 `EVENT_UP_GET_CONTACTS_FAILED` event.
 
 @param provider The provider on which the get contacts process has
 failed
 @param socialActionType The social action which is preformed
 @param message a Description of the reason for failure
 */
+ (void)postGetContactsFailed:(Provider)provider withType:(SocialActionType)socialActionType withMessage:(NSString *)message withFromStart:(bool)fromStart withPayload:(NSString *)payload;

/**
 Called when the get feed process from a provider has started. Which fires the
 `EVENT_UP_GET_FEED_STARTED` event.
 
 @param provider The provider on which the get feed process started
 @param socialActionType The social action which is preformed
 */
+ (void)postGetFeedStarted:(Provider)provider withType:(SocialActionType)socialActionType withFromStart:(bool)fromStart withPayload:(NSString *)payload;

/**
 Called when the get feed process from a provider has finished. Which fires the
 `EVENT_UP_GET_FEED_FINISHED` event.
 
 @param provider The provider on which the get feed process finished
 @param socialActionType The social action which is preformed
 @param feeds an Array of feed entries represented by `NSString`
 */
+ (void)postGetFeedFinished:(Provider)provider withType:(SocialActionType)socialActionType withContacts:(NSArray *)feeds withPayload:(NSString *)payload withHasMore:(bool)hasMore;

/**
 Called when the get feed process from a provider has failed. Which fires the
 `EVENT_UP_GET_FEED_FAILED` event.
 
 @param provider The provider on which the get feed process has
 failed
 @param socialActionType The social action which is preformed
 @param message a Description of the reason for failure
 */
+ (void)postGetFeedFailed:(Provider)provider withType:(SocialActionType)socialActionType withMessage:(NSString *)message withFromStart:(bool)fromStart withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has started. Which fires the
 `EVENT_UP_INVITE_STARTED` event.

 @param provider The provider on which the social action has started
 @param socialActionType The social action which started
 */
+ (void)postInviteStarted:(Provider)provider withType:(SocialActionType)socialActionType withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has finished. Which fires the
 `EVENT_UP_INVITE_FINISHED` event.

 @param provider The provider on which the social action has finished
 @param socialActionType The social action which finished
 */
+ (void)postInviteFinished:(Provider)provider withType:(SocialActionType)socialActionType requestId:(NSString *)requestId
                                            invitedIds:(NSArray *)invitedIds withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has been cancelled. Which fires
 the `EVENT_UP_INVITE_CANCELLED` event.

 @param provider The provider on which the social action has been cancelled
 @param socialActionType The social action which was cancelled
 */
+ (void)postInviteCancelled:(Provider)provider withType:(SocialActionType)socialActionType withPayload:(NSString *)payload;

/**
 Called when a generic social action on a provider has failed. Which fires the
 `EVENT_UP_INVITE_FAILED` event.

 @param provider The provider on which the social action has failed
 @param socialActionType The social action which failed
 @param message a Description of the reason for failure
 */
+ (void)postInviteFailed:(Provider)provider withType:(SocialActionType)socialActionType withMessage:(NSString *)message
             withPayload:(NSString *)payload;

/**
 Called when the get leaderboards process from a provider has started. Which fires the
 `EVENT_UP_GET_LEADERBOARDS_STARTED` event.

 @param provider The provider on which the get leaderboards process started
 */
+(void)postGetLeaderboardsStarted:(Provider)provider withPayload:(NSString *)payload;

/**
 Called when the get leaderboards process from a provider has finished. Which fires the
 `EVENT_UP_GET_LEADERBOARDS_FINISHED` event.

 @param provider The provider on which the get leaderboards process finished
 @param leaderboards an Array of leaderboards represented by specified provider
 */
+(void)postGetLeaderboardsFinished:(Provider)provider withLeaderboardsList:(NSArray *)leaderboards andPayload:(NSString *)payload;

/**
 Called when the get leaderboards process from a provider has failed. Which fires the
 `EVENT_UP_GET_LEADERBOARDS_FAILED` event.

 @param provider The provider on which the get leaderboards process has failed
 @param message a Description of the reason for failure
 */
+(void)postGetLeaderboardsFailed:(Provider)provider withMessage:(NSString *)message andPayload:(NSString *)payload;

/**
 Called when the get scores process from a provider has started. Which fires the
 `EVENT_UP_GET_SCORES_STARTED` event.

 @param provider The provider on which the get scores process started
 @param leaderboard The leaderboard scores fetched from
 */
+(void)postGetScoresStarted:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard fromStart:(BOOL)fromStart withPayload:(NSString *)payload;

/**
 Called when the get scores process from a provider has finished. Which fires the
 `EVENT_UP_GET_SCORES_FINISHED` event.

 @param provider The provider on which the get scores process finished
 @param leaderboard The leaderboard scores fetched from
 @param scores an Array of scores represented by specified leaderboard
 */
+(void)postGetScoresFinished:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard withScoresList:(NSArray *)scores hasMore:(BOOL)hasMore andPayload:(NSString *)payload;

/**
 Called when the get scores process from a provider has failed. Which fires the
 `EVENT_UP_GET_SCORES_FAILED` event.

 @param provider The provider on which the get scores process has failed
 @param leaderboard The leaderboard scores fetched from
 @param message a Description of the reason for failure
 */
+(void)postGetScoresFailed:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard fromStart:(BOOL)fromStart withMessage:(NSString *)message andPayload:(NSString *)payload;

/**
 Called when the score reporting process from a provider has started. Which fires the
 `EVENT_UP_REPORT_SCORE_STARTED` event.

 @param provider The provider on which the get scores process started
 @param leaderboard The leaderboard score reported to
 */
+(void)postReportScoreStarted:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard withPayload:(NSString *)payload;

/**
 Called when the score reporting process from a provider has finished. Which fires the
 `EVENT_UP_REPORT_SCORE_FINISHED` event.

 @param provider The provider on which the get scores process finished
 @param leaderboard The leaderboard score reported to
 @param score A new score instance as a result of reporting
 */
+(void)postReportScoreFinished:(Provider)provider score:(Score *)score forLeaderboard:(Leaderboard *)leaderboard andPayload:(NSString *)payload;

/**
 Called when the score reporting process from a provider has failed. Which fires the
 `EVENT_UP_REPORT_SCORE_FAILED` event.

 @param provider The provider on which the get scores process has failed
 @param leaderboard The leaderboard score reported to
 @param message a Description of the reason for failure
 */
+(void)postReportScoreFailed:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard withMessage:(NSString *)message andPayload:(NSString *)payload;

@end
