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
#import "IProvider.h"

@class UserProfile;

// Define block signatures for authentication callbacks

typedef void (^loginSuccess)(Provider provider);
typedef void (^loginFail)(NSString* message);
typedef void (^loginCancel)();
typedef void (^userProfileSuccess)(UserProfile* userProfile);
typedef void (^userProfileFail)(NSString* message);
typedef void (^logoutSuccess)();
typedef void (^logoutFail)(NSString* message);


/**
 A provider that exposes authentication capabilities.
 */
@protocol IAuthProvider <IProvider>

/**
 Logs in with the authentication provider
 
 @param sucesss a login sucess callback
 @param fail a login failure callback
 @param cancel a login cancelled callback
 */
- (void)login:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel;

/**
 Fetches the user profile from the authentication provider
 
 @param sucesss a fetch sucess callback
 @param fail a fetch failure callback
 */
- (void)getUserProfile:(userProfileSuccess)success fail:(userProfileFail)fail;

/**
 Logs out of the authentication provider
 
 @param sucesss a logout sucess callback
 @param fail a logout failure callback
 */
- (void)logout:(logoutSuccess)success fail:(logoutFail)fail;

/**
 Checks if the user is logged-in using the authentication provider
 
 @return YES if the user is already logged-in using the authentication provider, 
 NO otherwise
 */
- (BOOL)isLoggedIn;

- (BOOL)isAutoLogin;

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
- (BOOL)tryHandleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end
