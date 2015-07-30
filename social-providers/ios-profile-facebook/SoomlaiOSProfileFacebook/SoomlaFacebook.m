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

#import <FacebookSDK/FacebookSDK.h>
#import "SoomlaFacebook.h"
#import "UserProfile.h"
#import "SoomlaUtils.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedClassInspection"

#define DEFAULT_LOGIN_PERMISSIONS @[@"public_profile", @"email", @"user_birthday", @"user_photos", @"user_friends", @"read_stream"]
#define DEFAULT_PAGE_SIZE 20

@interface SoomlaFacebook ()
@property(nonatomic) NSNumber *lastContactPage;
@property(nonatomic) NSNumber *lastFeedPage;
@property(nonatomic) FBSessionLoginBehavior loginBehavior;
@property(nonatomic, strong) NSMutableArray *permissions;
@end

@implementation SoomlaFacebook {
    NSArray *_loginPermissions;
    NSNumber *_autoLogin;
}

@synthesize loginSuccess, loginFail, loginCancel,
            logoutSuccess;

static NSString *TAG = @"SOOMLA SoomlaFacebook";

- (id)init {
    self = [super init];
    if (!self) return nil;

    LogDebug(TAG, @"addObserver kUnityOnOpenURL notification");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(innerHandleOpenURL:)
                                                 name:@"kUnityOnOpenURL"
                                               object:nil];

    if (![UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"fb://"]]) {
        self.loginBehavior = FBSessionLoginBehaviorForcingWebView;
    } else {
        self.loginBehavior = FBSessionLoginBehaviorWithFallbackToWebView;
    }

    return self;
}

- (void)dealloc {
    LogDebug(TAG, @"removeObserver kUnityOnOpenURL notification");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)innerHandleOpenURL:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"kUnityOnOpenURL"]) {
        LogDebug(TAG, @"Successfully received the kUnityOnOpenURL notification!");

        NSURL *url = [[notification userInfo] valueForKey:@"url"];
        NSString *sourceApplication = [[notification userInfo] valueForKey:@"sourceApplication"];
        BOOL urlWasHandled = [FBAppCall handleOpenURL:url
                                    sourceApplication:sourceApplication
                                      fallbackHandler:^(FBAppCall *call) {
                    LogDebug(TAG, ([NSString stringWithFormat:@"Unhandled deep link: %@", url]));
                    // Here goes the code to handle the links
                    // Use the links to show a relevant view of your app to the user
                }];

        LogDebug(TAG,
                        ([NSString stringWithFormat:@"urlWasHandled: %@",
                                                    urlWasHandled ? @"True" : @"False"]));
    }
}

- (void)applyParams:(NSDictionary *)providerParams {
    _loginPermissions = DEFAULT_LOGIN_PERMISSIONS;
    if (providerParams) {
        _autoLogin = providerParams[@"autoLogin"] ?: @NO;
        if (providerParams[@"permissions"]) {
            _loginPermissions = [providerParams[@"permissions"] componentsSeparatedByString:@","];
        }
    } else {
        _autoLogin = @NO;
    }
}

- (Provider)getProvider {
    return FACEBOOK;
}

- (void)login:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel {

    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
            || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {

        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];

    } else {
        [FBSession setActiveSession:[[FBSession alloc] initWithPermissions:_loginPermissions]];
        [[FBSession activeSession]
                openWithBehavior:self.loginBehavior
               completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                   self.loginSuccess = success;
                   self.loginFail = fail;
                   self.loginCancel = cancel;
                   [self sessionStateChanged:session state:state error:error];
               }];
    }
}

/*
 Asks for the user's public profile and birthday.
 First checks for the existence of the `public_profile` and `user_birthday` permissions
 If the permissions are not present, requests them
 If/once the permissions are present, makes the user info request
 */
- (void)getUserProfile:(userProfileSuccess)success fail:(userProfileFail)fail {
    LogDebug(TAG, @"Getting user profile");
    [self checkPermissions: @[@"public_profile", @"user_birthday"] withWrite:NO
                   success:^() {

        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                LogDebug(TAG, ([NSString stringWithFormat:@"user info: %@", result]));

                UserProfile *userProfile = [[UserProfile alloc] initWithProvider:FACEBOOK
                                                                    andProfileId:result[@"id"]
                                                                     andUsername:result[@"email"]
                                                                        andEmail:result[@"email"]
                                                                    andFirstName:result[@"first_name"]
                                                                     andLastName:result[@"last_name"]];

                userProfile.gender = result[@"gender"];
                userProfile.birthday = result[@"birthday"];
                userProfile.location = result[@"location"][@"name"];
                userProfile.avatarLink = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", result[@"id"]];

                success(userProfile);
            } else {

                LogError(TAG, error.description);
                fail(error.description);
            }
        }];

    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];
}


- (void)logout:(logoutSuccess)success fail:(logoutFail)fail {

    self.logoutSuccess = success;

    // Clear this token
    [FBSession.activeSession closeAndClearTokenInformation];
}

/**
 Checks if the user is logged-in using the authentication provider
 
 @return YES if the user is already logged-in using the authentication provider, NO otherwise
 */
- (BOOL)isLoggedIn {
    return ((FBSession.activeSession != nil) && ((FBSession.activeSession.state == FBSessionStateOpen
                                                  || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)));
}

- (BOOL)isAutoLogin {
    return [_autoLogin boolValue];
}


- (BOOL)tryHandleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                           sourceApplication:sourceApplication
                             fallbackHandler:^(FBAppCall *call) {
                                 LogDebug(TAG, ([NSString stringWithFormat:@"Unhandled deep link: %@", url]));
                                 // Here goes the code to handle the links
                                 // Use the links to show a relevant view of your app to the user
                             }];
}

- (void)updateStatus:(NSString *)status success:(socialActionSuccess)success fail:(socialActionFail)fail {
    LogDebug(TAG, @"Updating status");

    [self checkPermissions: @[@"publish_actions"] withWrite:YES
                   success:^() {

        // NOTE: pre-filling fields associated with Facebook posts,
        // unless the user manually generated the content earlier in the workflow of your app,
        // can be against the Platform policies: https://developers.facebook.com/policy
        [FBRequestConnection startForPostStatusUpdate:status ? status : @""
                                    completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // Status update posted successfully to Facebook
                success();
            } else {
                // An error occurred, we need to handle the error
                // See: https://developers.facebook.com/docs/ios/errors
                fail(error.description);
            }
        }];

    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];
}

- (void)updateStatusWithProviderDialog:(NSString *)link success:(socialActionSuccess)success fail:(socialActionFail)fail {
    LogDebug(TAG, @"Updating status");
    
    [self openDialog:link andName:nil andCaption:nil andDescription:nil andPicture:nil success:success fail:fail];
}

-(void) openDialog:(NSString *)link
           andName:(NSString *)name
        andCaption:(NSString *)caption
    andDescription:(NSString *)description
        andPicture:(NSString *)picture
           success:(socialActionSuccess)success
              fail:(socialActionFail)fail {
    [self checkPermissions:@[@"publish_actions"] withWrite:YES success:^{
        
        FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
        if (link) {
            params.link = [NSURL URLWithString:link];
            if (name) {
                params.name = name;
            }
            if (caption) {
                params.caption = caption;
            }
            if (description) {
                params.linkDescription = description;
            }
            if (picture) {
                params.picture = [NSURL URLWithString:picture];
            }
        }
        
        // If the Facebook app is installed and we can present the share dialog
        if ([FBDialogs canPresentShareDialogWithParams:params]) {
            [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                if (!error) {
                    NSString *postId = results[@"postId"];
                    if (postId) {
                        success();
                    }
                    else {
                        fail(@"User did not complete share operation");
                    }
                } else {
                    // An error occurred, we need to handle the error
                    // See: https://developers.facebook.com/docs/ios/errors
                    fail(error.description);
                }
            }];
        } else {
            // If the Facebook app is not installed fallback to web dialogs
            NSMutableDictionary *dialogParams = [NSMutableDictionary dictionary];
            if (link) {
                dialogParams[@"link"] = link;
                if (name) {
                    dialogParams[@"name"] = name;
                }
                if (caption) {
                    dialogParams[@"caption"] = caption;
                }
                if (description) {
                    dialogParams[@"description"] = description;
                }
                if (picture) {
                    dialogParams[@"picture"] = picture;
                }
            }
            
            // Invoke the dialog
            [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                                   parameters:dialogParams
                                                      handler:
             ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                 if (error) {
                     fail(error.description);
                 } else {
                     if (result == FBWebDialogResultDialogNotCompleted) {
                         // User clicked the "x" icon
                         fail(@"User canceled story publishing.");
                     } else {
                         // Handle the publish feed callback
                         NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                         if (![urlParams valueForKey:@"post_id"]) {
                             // User clicked the Cancel button
                             fail(@"User canceled story publishing.");
                         } else {
                             success();
                         }
                     }
                 }
             }];
        }
    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];
}

/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

- (void)updateStoryWithMessage:(NSString *)message
                       andName:(NSString *)name
                    andCaption:(NSString *)caption
                andDescription:(NSString *)description
                       andLink:(NSString *)link
                    andPicture:(NSString *)picture
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail {

    [self checkPermissions: @[@"publish_actions"] withWrite:YES
                   success:^() {

// NOTE: pre-filling fields associated with Facebook posts,
// unless the user manually generated the content earlier in the workflow of your app,
// can be against the Platform policies: https://developers.facebook.com/policy

// Put together the dialog parameters
        NSMutableDictionary *params = [@{
                @"message" : message,
                @"name" : name,
                @"caption" : caption,
                @"description" : description,
                @"link" : link,
                @"picture" : picture} mutableCopy];

// Make the request
        [FBRequestConnection startWithGraphPath:@"/me/feed"
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                success();
            } else {
                fail(error.description);
            }
        }];
    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];
}

- (void)updateStoryWithMessageDialog:(NSString *)name
                          andCaption:(NSString *)caption
                      andDescription:(NSString *)description
                             andLink:(NSString *)link
                          andPicture:(NSString *)picture
                             success:(socialActionSuccess)success
                                fail:(socialActionFail)fail {
    LogDebug(TAG, @"Updating story");
    
    [self openDialog:link andName:name andCaption:caption andDescription:description andPicture:picture success:success fail:fail];
}

- (void)getContacts:(bool)fromStart success:(contactsActionSuccess)success fail:(contactsActionFail)fail {
//    NSLog(@"============================ getContacts ============================");

    int offset = DEFAULT_PAGE_SIZE * (fromStart ? 0 : (self.lastContactPage != nil ? [self.lastContactPage integerValue] : 0));
    self.lastContactPage = nil;

    [self checkPermissions: @[@"user_friends"] withWrite:NO
                   success:^() {

        /* make the API call */
        [FBRequestConnection startWithGraphPath:@"/me/friends"
                                     parameters:@{
                                             @"fields": @"id,email,first_name,last_name,gender,birthday,location",
                                             @"limit":  @(DEFAULT_PAGE_SIZE).stringValue,
                                             @"offset": @(offset).stringValue
                                     }
                                     HTTPMethod:@"GET"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {

            if (error) {
                // An error occurred, we need to handle the error
                // See: https://developers.facebook.com/docs/ios/errors
                LogError(TAG, ([NSString stringWithFormat:@"Get contacts error: %@", error.description]));
                fail(error.description);
            } else {
                // Success
                LogDebug(TAG, ([NSString stringWithFormat:@"Get contacts success: %@", result]));

                if (result[@"paging"][@"next"] != nil) {
                    self.lastContactPage = @(offset + 1);
                }

                NSArray *rawContacts = [result data];
                NSMutableArray *contacts = [NSMutableArray array];

                for (NSDictionary *contactDict in rawContacts) {
                    UserProfile *contact = [[UserProfile alloc] initWithProvider:FACEBOOK
                                                                        andProfileId:contactDict[@"id"]
                                                                         andUsername:contactDict[@"email"]
                                                                            andEmail:contactDict[@"email"]
                                                                        andFirstName:contactDict[@"first_name"]
                                                                         andLastName:contactDict[@"last_name"]];
                    contact.gender = contactDict[@"gender"];
                    contact.birthday = contactDict[@"birthday"];
                    if (contactDict[@"location"]) {
                        contact.location = contactDict[@"location"][@"name"];
                    }
                    contact.avatarLink = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", contactDict[@"id"]];

                    [contacts addObject:contact];
                }

                success(contacts, self.lastContactPage != nil);
            }
        }];
    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];
}

- (void)getFeed:(bool)fromStart success:(feedsActionSuccess)success fail:(feedsActionFail)fail {
//    NSLog(@"============================ getFeed ============================");

    int offset = DEFAULT_PAGE_SIZE * (fromStart ? 0 : (self.lastFeedPage != nil ? [self.lastFeedPage integerValue] : 0));
    self.lastFeedPage = nil;

    [self checkPermissions: @[@"read_stream"] withWrite:NO
                   success:^() {

        /* make the API call */
        [FBRequestConnection startWithGraphPath:@"/me/feed"
                                     parameters:@{
                                             @"limit":  @(DEFAULT_PAGE_SIZE).stringValue,
                                             @"offset": @(offset).stringValue
                                     }
                                     HTTPMethod:@"GET"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error) {

                // An error occurred, we need to handle the error
                // See: https://developers.facebook.com/docs/ios/errors
                LogError(TAG, ([NSString stringWithFormat:@"Get feeds error: %@", error.description]));
                fail(error.description);
            } else {
                // Success
                if (result[@"paging"][@"next"] != nil) {
                    self.lastFeedPage = @(offset + 1);
                }
                LogDebug(TAG, ([NSString stringWithFormat:@"Get feeds success: %@", result]));
                NSMutableArray *feeds = [NSMutableArray array];
                NSArray *rawFeeds = [result data];
                for (NSDictionary *dict in rawFeeds) {
                    NSString *str;
                    str = dict[@"story"];
                    if (str) {
                        [feeds addObject:str];
                    }
                }
                success(feeds, self.lastFeedPage != nil);
            }
        }];

    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];
}

- (void)uploadImageWithMessage:(NSString *)message
                   andFilePath:(NSString *)filePath
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail {

    [self checkPermissions: @[@"publish_actions"] withWrite:YES
                   success:^() {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        // Put together the dialog parameters
        NSDictionary *params = @{
                @"picture": UIImagePNGRepresentation(image),
                @"message" : message
        };

        // Make the request
        [FBRequestConnection startWithGraphPath:@"/me/photos"
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                success();
            } else {
                fail(error.description);
            }
        }];


    } fail:^(NSString *errorMessage) {
        fail(errorMessage);
    }];

}

- (void)uploadImageWithMessage:(NSString *)message
              andImageFileName: (NSString *)fileName
                  andImageData: (NSData *)imageData
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail{

    [self checkPermissions: @[@"publish_actions"] withWrite:YES
                   success:^() {
                       UIImage *image = [UIImage imageWithData:imageData];
                       // Put together the dialog parameters
                       NSDictionary *params = @{
                                                @"picture": UIImagePNGRepresentation(image),
                                                @"message" : message
                                                };

                       // Make the request
                       [FBRequestConnection startWithGraphPath:@"/me/photos"
                                                    parameters:params
                                                    HTTPMethod:@"POST"
                                             completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                 if (!error) {
                                                     success();
                                                 } else {
                                                     fail(error.description);
                                                 }
                                             }];


                   } fail:^(NSString *errorMessage) {
                       fail(errorMessage);
                   }];

}

- (void)like:(NSString *)pageId {
    
    NSURL *providerURL = nil;
    NSString *baseURL = @"fb://profile/";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:baseURL]] &&
        ([pageId rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound))
    {
        providerURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, pageId]];
    } else {
        providerURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.facebook.com/%@", pageId]];
    }
    
    [[UIApplication sharedApplication] openURL:providerURL];
}

//
// Private Methods
//


// This method will handle ALL the session state changes in the app
- (void)sessionStateChanged:(__unused FBSession *)session state:(FBSessionState)state error:(NSError *)error {

    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen) {
        LogDebug(TAG, @"Session opened");

        // Callback
        if (self.loginSuccess) {
            self.loginSuccess(FACEBOOK);
        }
        [self clearLoginBlocks];
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {

        if (state == FBSessionStateClosedLoginFailed) {
            if (self.loginCancel) {
                self.loginCancel();
            }
            [self clearLoginBlocks];
        }

        if (state == FBSessionStateClosed) {
            if (logoutSuccess) {
                self.logoutSuccess();
            }
            [self clearLoginBlocks];
        }

        // If the session is closed
        LogDebug(TAG, @"Session closed");
    }

    // Handle errors
    if (error) {
        LogError(TAG, @"Error");
        NSString *alertText;
        NSString *alertTitle;

        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error]) {
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];

            // Callback
            if (self.loginFail) {
                self.loginFail([NSString stringWithFormat:@"%@: %@", alertTitle, alertText]);
            }
            [self clearLoginBlocks];
        } else {

            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                LogError(TAG, @"User cancelled login");

                // Callback
                if (self.loginCancel) {
                    self.loginCancel();
                }
                [self clearLoginBlocks];

                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
                alertTitle = @"Session Error";
                alertText = @"Your current session is no longer valid. Please log in again.";

                // Callback
                if (self.loginFail) {
                    self.loginFail([NSString stringWithFormat:@"%@: %@", alertTitle, alertText]);
                }
                [self clearLoginBlocks];

                // For simplicity, here we just show a generic message for all other errors
                // You can learn how to handle other errors using our guide: https://developers.facebook.com/docs/ios/errors
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[error.userInfo[@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];

                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", errorInformation[@"message"]];

                // Callback
                if (self.loginFail) {
                    self.loginFail([NSString stringWithFormat:@"%@: %@", alertTitle, alertText]);
                }
                [self clearLoginBlocks];
            }
        }

        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}

/**
A helper method for requesting user data from Facebook.
*/

- (void)checkPermissions: (NSArray*)requestedPermissions withWrite:(BOOL)writePermissions success:(void (^)())success fail:(void(^)(NSString* message))fail {

    void (^checking)() = ^() {
        NSMutableArray *missedPermissions = [[NSMutableArray alloc] init];
        for (NSString *permission in requestedPermissions) {
            if (![self.permissions containsObject:permission]) {
                [missedPermissions addObject:permission];
            }
        }

        if ([missedPermissions count] == 0) {
            success();
            return;
        }

        if (writePermissions) {
            // Ask for the missing read permissions
            [FBSession.activeSession
                    requestNewPublishPermissions:missedPermissions
                                 defaultAudience:FBSessionDefaultAudienceFriends
                               completionHandler:^(FBSession *session, NSError *newPublishPermissionsError) {
                                   if (!newPublishPermissionsError) {
                                       [[self permissions] addObjectsFromArray:missedPermissions];
                                       // Permission granted, we can go on
                                       success();
                                   } else {
                                       fail(newPublishPermissionsError.description);
                                   }
                               }];
        }
        else {
            // Ask for the missing publish permissions
            [FBSession.activeSession
                    requestNewReadPermissions:missedPermissions
                            completionHandler:^(FBSession *session, NSError *newReadPermissionsError) {
                                if (!newReadPermissionsError) {
                                    [[self permissions] addObjectsFromArray:missedPermissions];
                                    // Permission granted, we can go on
                                    success();
                                } else {
                                    fail(newReadPermissionsError.description);
                                }
                            }];
        }

    };

    if (self.permissions == nil) {
        [self fetchPermissions:checking fail:fail];
    } else {
        checking();
    }
}

- (NSMutableArray *)parsePermissions:(id)response {
    NSMutableArray *permissions = [[NSMutableArray alloc] init];

    NSArray *dataJson = [response data];

    for (NSDictionary *dataItem in dataJson) {
        if ([@"granted" isEqual:dataItem[@"status"]]) {
            [permissions addObject:dataItem[@"permission"]];
        }
    }

    return permissions;
}

- (void) fetchPermissions:(void (^)())success fail:(void(^)(NSString* message))fail {
    [FBRequestConnection startWithGraphPath:@"/me/permissions"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              if (error) {
                                  fail(error.description);
                              }
                              self.permissions = [self parsePermissions:result];
                              success();
                          }
    ];
}

/*
 Helper methods for clearing callback blocks
 */

- (void)clearLoginBlocks {
    self.loginSuccess = nil;
    self.loginFail = nil;
    self.loginCancel = nil;
}

@end

#pragma clang diagnostic pop