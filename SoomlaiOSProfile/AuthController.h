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

#import "ProviderLoader.h"
#import "UserProfileUtils.h"

@class Reward;
@class UserProfile;

/**
 A class that loads all authentication providers and performs authentication
 actions on with them.  This class wraps the provider's authentication
 actions in order to connect them to user profile data and rewards.
 */
@interface AuthController : ProviderLoader

/**
 Constructor
 
 Loads all authentication providers
 @param providerParams Special initialization parameters for loaded providers
 */
- (id)initWithParameters:(NSDictionary *)providerParams;

/**
 Auxilliary initializer for internal use by `SocialController`.
 Do not call this method yourself!
 */
- (id)initWithoutLoadingProviders;


/**
 Logs into the given provider and grants the user a reward.
 
 @param provider The provider to login with
 @param reward The reward to grant the user for logging in
 @param payload a String to receive when the function returns.
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)loginWithProvider:(Provider)provider andPayload:(NSString *)payload andReward:(Reward *)reward;

/**
 Logs out of the given provider
 
 @param provider The provider to logout from
 @exception ProviderNotFoundException if the provider is not supported
 */
- (void)logoutWithProvider:(Provider)provider;

/**
 Checks if the user is logged in with given provider
 
 @param provider The provider to use
 @return YES if the user is logged-in with the given provider, NO otherwise
 @exception ProviderNotFoundException if the provider is not supported
 */
- (BOOL)isLoggedInWithProvider:(Provider)provider;

/**
 Fetches the user profile for the given provider from the device's storage.
 
 @param provider
 @return The user profile for the given provider
 @exception ProviderNotFoundException if the provider is not supported
 */
- (UserProfile *)getStoredUserProfileWithProvider:(Provider)provider;

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
 Helper method to assist with browser-based authentication using underlying
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

- (void)settleAutoLogin;
@end
