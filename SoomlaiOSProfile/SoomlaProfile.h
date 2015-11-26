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

@class Reward;
@class UserProfile;
@class AuthController;
@class SocialController;
@class GameServicesController;
@class Leaderboard;

/**
 This is the main class for the SOOMLA User Profile module.  This class should be initialized once,
 after <code>Soomla.initialize()</code> is invoked.  Use this class to perform authentication and social
 actions on behalf of the user that will grant him \ her rewards in your game.
 */
@interface SoomlaProfile : NSObject {

    @private
    BOOL initialized;
    AuthController* authController;
    SocialController* socialController;
    GameServicesController *gameServicesController;
}

@property BOOL initialized;

+ (void)usingExternalProvider:(BOOL)isExternal;
+ (BOOL)isUsingExternalProvider;

/**
 Constructor.

 Initializes the Profile module.  Call this method after <code>Soomla.initialize()</code>
 */
- (BOOL)initialize;

/**
 Constructor.

 Initializes the Profile module.  Call this method after <code>Soomla.initialize()</code>
 @param customParams provides custom values for specific social providers
 */
- (BOOL)initialize:(NSDictionary *)customParams;

/**
 Login to the given provider

 @param provider The provider to use
 */
- (void)loginWithProvider:(Provider)provider;

/**
 Login to the given provider and grant the user a reward.

 @param provider The provider to use
 @param reward The reward to give the user for logging in.
 If you want your reward to be given more than once, make it repeatable
 */
- (void)loginWithProvider:(Provider)provider andReward:(Reward *)reward;

/**
 Login to the given provider and grant the user a reward.

 @param provider The provider to use
 @param payload a String to receive when the function returns.
 @param reward The reward to give the user for logging in.
               If you want your reward to be given more than once, make it repeatable
 */
- (void)loginWithProvider:(Provider)provider andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Logout from the given provider

 @param provider The provider to use
 */
- (void)logoutWithProvider:(Provider)provider;

/**
 Logout from all available providers
 */
- (void)logoutFromAllProviders;

/**
 Checks if the user is logged in with given provider

 @param provider The provider to use
 @return YES if the user is logged-in with the given provider, NO otherwise
 */
- (BOOL)isLoggedInWithProvider:(Provider)provider;

/**
 Fetches the user's profile for the given provider from the local device storage

 @param provider The provider to use
 @return The user profile
 */
- (UserProfile *)getStoredUserProfileWithProvider:(Provider)provider;

/**
 Retrives user profiles which are stored on the device

 @return an Array of `UserProfile`s which have been stored on the device
 */
- (NSArray *)getStoredUserProfiles;

/**
 Shares the given status to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param status The text to share
 @param payload a String to receive when the function returns.
 @param reward The reward to give the user
 @param showConfirmation If true, shows confirmation dialog before the action
 @param customMessage the message to show in the dialog
 */
- (void)updateStatusWithProvider:(Provider)provider andStatus:(NSString *)status andPayload:(NSString *)payload andReward:(Reward *)reward andConfirmation:(bool)showConfirmation andCustomMessage:(NSString *)customMessage;

- (void)updateStatusWithProvider:(Provider)provider andStatus:(NSString *)status andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Shares the given status to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param status The text to share
 @param reward The reward to give the user
 */
- (void)updateStatusWithProvider:(Provider)provider andStatus:(NSString *)status andReward:(Reward *)reward;

/**
 Shares the given status and link to the user's feed using the provider's
 native dialog (when available)

 @param provider the provider to use
 @param link the link to share (could be nil when not needed)
 @param payload a String to receive when the function returns.
 @param reward the reward to grant for sharing
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)updateStatusWithProviderDialog:(Provider)provider andLink:(NSString *)link andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Shares the given status and link to the user's feed using the provider's
 native dialog (when available)

 @param provider the provider to use
 @param link the link to share (could be nil when not needed)
 @param reward the reward to grant for sharing
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)updateStatusWithProviderDialog:(Provider)provider andLink:(NSString *)link andReward:(Reward *)reward;

/**
 Shares a story to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param message The main text which will appear in the story
 @param name The headline for the link which will be integrated in the
 story
 @param caption The sub-headline for the link which will be
 integrated in the story
 @param description The description for the link which will be
 integrated in the story
 @param link The link which will be integrated into the user's story
 @param picture a Link to a picture which will be featured in the link
 @param payload a String to receive when the function returns.
 @param reward The reward to give the user
 */
- (void)updateStoryWithProvider:(Provider)provider
                     andMessage:(NSString *)message
                        andName:(NSString *)name
                     andCaption:(NSString *)caption
                 andDescription:(NSString *)description
                        andLink:(NSString *)link
                     andPicture:(NSString *)picture
                     andPayload:(NSString *)payload
                      andReward:(Reward *)reward;

/**
Shares a story to the user's feed and grants the user a reward.

@param provider The provider to use
@param message The main text which will appear in the story
@param name The headline for the link which will be integrated in the
story
@param caption The sub-headline for the link which will be
integrated in the story
@param description The description for the link which will be
integrated in the story
@param link The link which will be integrated into the user's story
@param picture a Link to a picture which will be featured in the link
@param payload a String to receive when the function returns.
@param reward The reward to give the user
@param showConfirmation If true, shows confirmation dialog before the action
@param customMessage the message to show in the dialog
*/
- (void)updateStoryWithProvider:(Provider)provider andMessage:(NSString *)message andName:(NSString *)name andCaption:(NSString *)caption andDescription:(NSString *)description andLink:(NSString *)link andPicture:(NSString *)picture andPayload:(NSString *)payload andReward:(Reward *)reward andShowConfirmation:(bool)showConfirmation andCustomMessage:(NSString *)customMessage;

/**
 Shares a story to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param message The main text which will appear in the story
 @param name The headline for the link which will be integrated in the
 story
 @param caption The sub-headline for the link which will be
 integrated in the story
 @param description The description for the link which will be
 integrated in the story
 @param link The link which will be integrated into the user's story
 @param picture a Link to a picture which will be featured in the link
 @param reward The reward to give the user
 */
- (void)updateStoryWithProvider:(Provider)provider
                     andMessage:(NSString *)message
                        andName:(NSString *)name
                     andCaption:(NSString *)caption
                 andDescription:(NSString *)description
                        andLink:(NSString *)link
                     andPicture:(NSString *)picture
                      andReward:(Reward *)reward;

/**
 Shares a story to the user's feed and grants the user a reward, using the
 provider's native dialog (when available)

 @param provider The provider to use
 @param name The headline for the link which will be integrated in the
 story
 @param caption The sub-headline for the link which will be
 integrated in the story
 @param description The description for the link which will be
 integrated in the story
 @param link The link which will be integrated into the user's story
 @param picture a Link to a picture which will be featured in the link
 @param payload a String to receive when the function returns.
 @param reward The reward to give the user
 */
- (void)updateStoryWithProviderDialog:(Provider)provider
                        andName:(NSString *)name
                     andCaption:(NSString *)caption
                 andDescription:(NSString *)description
                        andLink:(NSString *)link
                     andPicture:(NSString *)picture
                     andPayload:(NSString *)payload
                      andReward:(Reward *)reward;

/**
 Shares a story to the user's feed and grants the user a reward, using the
 provider's native dialog (when available)

 @param provider The provider to use
 @param name The headline for the link which will be integrated in the
 story
 @param caption The sub-headline for the link which will be
 integrated in the story
 @param description The description for the link which will be
 integrated in the story
 @param link The link which will be integrated into the user's story
 @param picture a Link to a picture which will be featured in the link
 @param reward The reward to give the user
 */
- (void)updateStoryWithProviderDialog:(Provider)provider
                              andName:(NSString *)name
                           andCaption:(NSString *)caption
                       andDescription:(NSString *)description
                              andLink:(NSString *)link
                           andPicture:(NSString *)picture
                            andReward:(Reward *)reward;

/**
 Shares a photo to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param message A text that will accompany the image
 @param filePath The desired image's location on the device
 @param payload a String to receive when the function returns.
 @param reward The reward to give the user
 */
- (void)uploadImageWithProvider:(Provider)provider
                   andMessage:(NSString *)message
                   andFilePath:(NSString *)filePath
                    andPayload:(NSString *)payload
                     andReward:(Reward *)reward;

/**
 Shares a photo using image data to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param message A text that will accompany the image
 @param imageFileName The desired image's name
 @param imageData The desired image's data
 @param payload a String to receive when the function returns.
 @param reward The reward to give the user
 @param showConfirmation If true, shows confirmation dialog before the action
 @param customMessage the message to show in the dialog
 */
- (void)uploadImageWithProvider:(Provider)provider
                     andMessage:(NSString *)message
               andImageFileName:(NSString *)imageFileName
                   andImageData:(NSData *)imageData
                     andPayload:(NSString *)payload
                      andReward:(Reward *)reward
                andConfirmation:(BOOL)confirmation
               andCustomMessage:(NSString *)customMessage;

/**
 Shares a photo to the user's feed and grants the user a reward.

 @param provider The provider to use
 @param message A text that will accompany the image
 @param filePath The desired image's location on the device
 @param reward The reward to give the user
 */
- (void)uploadImageWithProvider:(Provider)provider
                     andMessage:(NSString *)message
                    andFilePath:(NSString *)filePath
                      andReward:(Reward *)reward;

/**
* Shares a photo to the user's feed and grants the user a reward.
*
* @param provider The provider to use
* @param message A text that will accompany the image
* @param filePath The desired image's location on the device
* @param reward The reward to give the user
* @param showConfirmation If true, shows confirmation dialog before the action
* @param customMessage the message to show in the dialog
*/
- (void)uploadImageWithProvider:(Provider)provider andMessage:(NSString *)message andFilePath:(NSString *)filePath andPayload:(NSString *)payload andReward:(Reward *)reward andConfirmation:(BOOL)showConfirmation andCustomMessage:(NSString *)customMessage;


/**
* Shares a current screenshot to the user's feed and grants the user a reward.
*
* @param provider The provider to use
* @param title A text that will used as title
* @param message A text that will accompany the image
*/
- (void)uploadCurrentScreenshot:(Provider)provider title:(NSString *)title message:(NSString *)message;

/**
* Shares a current screenshot to the user's feed and grants the user a reward.
*
* @param provider The provider to use
* @param title A text that will used as title
* @param message A text that will accompany the image
* @param payload a String to receive when the function returns.
* @param reward The reward to give the user
*/
- (void)uploadCurrentScreenshot:(Provider)provider title:(NSString *)title message:(NSString *)message
                        payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the user's contact list and grants the user a reward.

 @param provider The provider to use
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 */
- (void)getContactsWithProvider:(Provider)provider andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the user's contact list and grants the user a reward.

 @param provider The provider to use
 @param fromStart Should we reset pagination or request the next page
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 */
- (void)getContactsWithProvider:(Provider)provider andFromStart: (bool)fromStart andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the user's contact list and grants the user a reward.

 @param provider The provider to use
 @param reward The reward to grant
 */
- (void)getContactsWithProvider:(Provider)provider andReward:(Reward *)reward;

/**
Fetches the user's feed and grants the user a reward.

 @param provider The provider to use
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
*/
- (void)getFeedWithProvider:(Provider)provider andFromStart:(bool)fromStart andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the user's feed and grants the user a reward.

 @param provider The provider to use
 @param reward The reward to grant
 */
- (void)getFeedWithProvider:(Provider)provider andReward:(Reward *)reward;

/**
 Send an invite and grants the user a reward.

 @param provider The provider to use.
 @param inviteMessage The message was sent in invite.
 @param dialogTitle Title of invite dialog.
 @param payload a String to receive when the function returns.
 @param reward The reward to grant.
 */
- (void)inviteWithProvider:(Provider)provider inviteMessage:(NSString *)inviteMessage dialogTitle:(NSString *)dialogTitle
                   payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Send an invite and grants the user a reward.

 @param provider The provider to use.
 @param inviteMessage The message was sent in invite.
 @param reward The reward to grant.
 */
- (void)inviteWithProvider:(Provider)provider inviteMessage:(NSString *)inviteMessage andReward:(Reward *)reward;

/**
 Opens up a page to like for the user (external)

 @param provider The provider to like page on
 @param pageId The page to open on the provider
 @param reward The reward to grant when page is liked
 */
- (void)like:(Provider)provider andPageId:(NSString *)pageId andReward:(Reward *)reward;

/**
 Utility method to open up the market application rating page
 */
- (void)openAppRatingPage;

/**
* Shares text and/or image using native sharing functionality of your target platform.
* @param text Text to share
* @param imageFilePath Path to an image file to share
*/
- (void)multiShareWithText:(NSString *)text andImageFilePath:(NSString *)imageFilePath;

/**
 Fetches the game's leaderboards list

 @param provider The provider to use
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)getLeaderboardsWithProvider:(Provider)provider payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the game's scores list from specified leaderboard

 @param provider The provider to use
 @param leaderboard Leaderboard containing desired scores list
 @param fromStart Should we reset pagination or request the next page
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)getScoresWithProvider:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard fromStart:(BOOL)fromStart payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Fetches the game's scores list from specified leaderboard

 @param provider The provider to use
 @param leaderboard Leaderboard containing desired scores list
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)getScoresWithProvider:(Provider)provider forLeaderboard:(Leaderboard *)leaderboard payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Reports scores for specified leaderboard

 @param provider The provider to use
 @param score Value to report
 @param leaderboard Target leaderboard
 @param payload a String to receive when the function returns.
 @param reward The reward to grant
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)reportScoreWithProvider:(Provider)provider score:(NSNumber *)score forLeaderboard:(Leaderboard *)leaderboard payload:(NSString *)payload andReward:(Reward *)reward;

/**
 Helper method to assist with browser-based authentication using a sepcific
 underlying authentication provider.

 @param provider The provider to handle open URL
 @param url The URL which caused the application to launch and receive a
 callback
 @param sourceApplication The bundle ID of the app that is requesting your app
 to open the URL (url).
 @param annotation A property list object supplied by the source app to
 communicate information to the receiving app.

 @return YES if the provider was able to handle the URL, NO otherwise
 */
- (BOOL)tryHandleOpenURL:(Provider)provider openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

/**
 Helper method to assist with browser-based authentication using some underlying
 authentication providers.

 @param url The URL which caused the application to launch and receive a
 callback
 @param sourceApplication The bundle ID of the app that is requesting your app
 to open the URL (url).
 @param annotation A property list object supplied by the source app to
 communicate information to the receiving app.

 @return YES if a provider was able to handle the URL, NO otherwise
 */
- (BOOL)tryHandleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

/**
 Retrieves the singleton instance of `SoomlaProfile`
 @return the singleton instance of `SoomlaProfile`
 */
+ (SoomlaProfile *)getInstance;

@end
