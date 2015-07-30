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

#import <UIKit/UIKit.h>

#import "STTwitterOS.h"
#import "STTwitterOAuth.h"

#import "SoomlaTwitter.h"
#import "UserProfile.h"
#import "UserProfileStorage.h"

#import "SoomlaUtils.h"
#import "KeyValueStorage.h"

NSString *const TWITTER_OAUTH_TOKEN     = @"oauth.token";
NSString *const TWITTER_OAUTH_SECRET    = @"oauth.secret";

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedClassInspection"

#define DEFAULT_PAGE_SIZE 20

// Private properties

@interface SoomlaTwitter ()

@property (strong, nonatomic) STTwitterAPI *twitter;

@property(nonatomic) NSString* lastContactCursor;
@property(nonatomic) NSString* lastFeedCursor;
@property(nonatomic, strong) UIViewController *webVc;
@end

@implementation SoomlaTwitter {
    NSNumber *_autoLogin;
}

@synthesize loginSuccess, loginFail, loginCancel,
            logoutSuccess;

static NSString* DB_KEY_PREFIX  = @"soomla.profile.twitter.";
static NSString *TAG            = @"SOOMLA SoomlaTwitter";

- (id)init {
    self = [super init];
    if (!self) return nil;
    
    LogDebug(TAG, @"addObserver kUnityOnOpenURL notification");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(innerHandleOpenURL:)
                                                 name:@"kUnityOnOpenURL"
                                               object:nil];
    
    return self;
}

- (void)innerHandleOpenURL:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"kUnityOnOpenURL"]) {
        LogDebug(TAG, @"Successfully received the kUnityOnOpenURL notification!");
        
        NSURL *url = [[notification userInfo] valueForKey:@"url"];
        NSString *sourceApplication = [[notification userInfo] valueForKey:@"sourceApplication"];
        id annotation = [[notification userInfo] valueForKey:@"annotation"];
        BOOL urlWasHandled = [self tryHandleOpenURL:url sourceApplication:sourceApplication annotation:annotation];
        
        LogDebug(TAG,
                 ([NSString stringWithFormat:@"urlWasHandled: %@",
                   urlWasHandled ? @"True" : @"False"]));
    }
}

- (void)dealloc {
    LogDebug(TAG, @"removeObserver kUnityOnOpenURL notification");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applyParams:(NSDictionary *)providerParams {
    

    if (providerParams) {
        _autoLogin = providerParams[@"autoLogin"] ?: @NO;
        _consumerKey = providerParams[@"consumerKey"];
        _consumerSecret = providerParams[@"consumerSecret"];
        
        // Allows the user to force web browser authentication
        NSNumber *forceWeb = providerParams[@"forceWeb"];
        webOnly = forceWeb ? [forceWeb boolValue] : NO;
    } else {
        _autoLogin = @NO;
        webOnly = NO;
    }
    
    if ([self isEmptyString:self.consumerKey] || [self isEmptyString:self.consumerSecret]) {
        LogDebug(TAG, @"Either consumer key or consumer secret were not provided, falling back to native only");
        webAvailable = NO;
    }
    else {
        webAvailable = YES;
    }

}

- (Provider)getProvider {
    return TWITTER;
}

- (void)login:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel {
    LogDebug(TAG, @"Login started...");
    
    if (webOnly) {
        [self loginWithWeb:success fail:fail cancel:cancel];
    }
    else {
        // Try to verify account using native Twitter support in iOS
        self.twitter = [STTwitterAPI twitterAPIOSWithFirstAccount];
        
        [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
            loggedInUser = username;
            success([self getProvider]);
        } errorBlock:^(NSError *error) {
            if (error.code == STTwitterOSUserDeniedAccessToTheirAccounts) {
                // User has literally blocked your application
                LogError(TAG, @"User denied access");
                fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
            }
            else {
                LogDebug(TAG, @"Unable to natively login to Twitter trying via web");
                [self loginWithWeb:success fail:fail cancel:cancel];
            }
        }];
    }
}

- (void)loginWithWeb:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel {
    
    if (!webAvailable) {
        LogError(TAG, @"Consumer key and secret were not defined, please provide them in initialization");
        return;
    }
    
    // Try logging in to Twitter using stored OAuth tokens
    if ([self tryLoginFromDB:success fail:fail cancel:cancel]) {
        return;
    }
    
    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:self.consumerKey
                                                 consumerSecret:self.consumerSecret];

    // Get request token to launch a browser instance
    // Provides meaningful URL Scheme to make the browser call the application back
    [_twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
                // Launch browser to have the user verify your application
                // Should eventually return to tryHandleOpenURL
                self.loginSuccess = success;
                self.loginFail = fail;
                self.loginCancel = cancel;
//                [[UIApplication sharedApplication] openURL:url];

                self.webVc = [[UIViewController alloc] init];
                UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 20, 300, 500)];
                webView.backgroundColor = [UIColor whiteColor];
                webView.scalesPageToFit = YES;
                webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
                webView.delegate = self;
                [webView setTranslatesAutoresizingMaskIntoConstraints:NO];
                [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:_webVc animated:YES completion:nil];
                [self.webVc.view addSubview:webView];

                NSDictionary *views = NSDictionaryOfVariableBindings(webView);

                [self.webVc.view addConstraints:
                        [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|"
                                                                options:0
                                                                metrics:nil
                                                                  views:views]];

                [self.webVc.view addConstraints:
                        [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|"
                                                                options:0
                                                                metrics:nil
                                                                  views:views]];

                [webView loadRequest:[NSURLRequest requestWithURL:url]];

            } authenticateInsteadOfAuthorize:NO
                    forceLogin:@(NO)
                    screenName:nil
                 oauthCallback:[NSString stringWithFormat:@"%@://twitter_access_tokens/", [self getURLScheme]]
                    errorBlock:^(NSError *error) {
                        LogError(TAG, @"Unable to login via web");
                        fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
                    }];
}

- (BOOL)tryLoginFromDB:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel {
    NSString *oauthToken = [KeyValueStorage getValueForKey:[self getTwitterStorageKey:TWITTER_OAUTH_TOKEN]];
    NSString *oauthSecret = [KeyValueStorage getValueForKey:[self getTwitterStorageKey:TWITTER_OAUTH_SECRET]];
    
    if ([self isEmptyString:oauthToken] || [self isEmptyString:oauthSecret]) {
        return NO;
    }
    
    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:_consumerKey consumerSecret:_consumerSecret
                                                     oauthToken:oauthToken oauthTokenSecret:oauthSecret];
    
    // Try to use stored OAuth tokens to verify the application
    [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        loggedInUser = username;
        success([self getProvider]);
    } errorBlock:^(NSError *error) {
        // Something's wrong with my oauth tokens, retry login from web
        [self cleanTokensFromDB];
        [self loginWithWeb:success fail:fail cancel:cancel];
    }];
    
    return YES;
}

- (void) applyOauthTokens:(NSString *)token andVerifier:(NSString *)verifier {
    if (!token || !verifier) {
        self.loginCancel([self getProvider]);
        return;
    }
    
    [self.twitter postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        
        [KeyValueStorage setValue:oauthToken forKey:[self getTwitterStorageKey:TWITTER_OAUTH_TOKEN]];
        [KeyValueStorage setValue:oauthTokenSecret forKey:[self getTwitterStorageKey:TWITTER_OAUTH_SECRET]];
        
        loggedInUser = screenName;
        self.loginSuccess([self getProvider]);
        
        [self clearLoginBlocks];
    } errorBlock:^(NSError *error) {
        LogError(TAG, @"Unable to login via web");
        self.loginFail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
    }];
}

- (void)getUserProfile:(userProfileSuccess)success fail:(userProfileFail)fail {
    [self.twitter getUserInformationFor:loggedInUser successBlock:^(NSDictionary *user) {
        UserProfile *userProfile = [self parseUserProfile:user];
        success(userProfile);
    } errorBlock:^(NSError *error) {
        fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
    }];
}

- (void)logout:(logoutSuccess)success fail:(logoutFail)fail {
    loggedInUser = nil;
    [self cleanTokensFromDB];
    self.twitter = nil;
    
    success();
}

- (BOOL)isLoggedIn {
    return ![self isEmptyString:loggedInUser] && self.twitter;
}

- (BOOL)isAutoLogin {
    return [_autoLogin boolValue];
}

- (BOOL)tryHandleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSString *expectedScheme = [self getURLScheme];
    
    if (![[url scheme] isEqualToString:expectedScheme]) {
        return NO;
    }

    if (self.webVc != nil) {
        [self.webVc dismissViewControllerAnimated:YES completion:nil];
        self.webVc = nil;
    }

    NSDictionary *d = [self parametersDictionaryFromQueryString:[url query]];
    
    NSString *token = d[@"oauth_token"];
    NSString *verifier = d[@"oauth_verifier"];
    
    [self applyOauthTokens:token andVerifier:verifier];
    
    return YES;
}

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
    
    for(NSString *s in queryComponents) {
        NSArray *pair = [s componentsSeparatedByString:@"="];
        if([pair count] != 2) continue;
        
        NSString *key = pair[0];
        NSString *value = pair[1];
        
        md[key] = value;
    }
    
    return md;
}

- (void)updateStatus:(NSString *)status success:(socialActionSuccess)success fail:(socialActionFail)fail {
    if (![self testLoggedIn:fail]) {
        return;
    }
    
    LogDebug(TAG, @"Updating status");
    [self.twitter postStatusUpdate:status inReplyToStatusID:nil latitude:nil longitude:nil placeID:nil displayCoordinates:nil trimUser:nil successBlock:^(NSDictionary *status) {
        LogDebug(TAG, @"Updating status success");
        success();
    } errorBlock:^(NSError *error) {
        fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
    }];
}

- (void)updateStatusWithProviderDialog:(NSString *)link success:(socialActionSuccess)success fail:(socialActionFail)fail {
    LogDebug(TAG, @"Dialogs are not available in Twitter");
    fail(@"Dialogs are not available in Twitter");
}

- (void)updateStoryWithMessage:(NSString *)message
                       andName:(NSString *)name
                    andCaption:(NSString *)caption
                andDescription:(NSString *)description
                       andLink:(NSString *)link
                    andPicture:(NSString *)picture
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail {
    // These parameters cannot be added to the tweet.
    // Please use cards (https://dev.twitter.com/cards) and add these parameters
    // to the supplied link's HTML
    [self updateStatus:[NSString stringWithFormat:@"%@ %@", message, link] success:success fail:fail];
}

- (void)updateStoryWithMessageDialog:(NSString *)name
                          andCaption:(NSString *)caption
                      andDescription:(NSString *)description
                             andLink:(NSString *)link
                          andPicture:(NSString *)picture
                             success:(socialActionSuccess)success
                                fail:(socialActionFail)fail {
    LogDebug(TAG, @"Dialogs are not available in Twitter");
    fail(@"Dialogs are not available in Twitter");
}

- (void)getContacts:(bool)fromStart success:(contactsActionSuccess)success fail:(contactsActionFail)fail {
    if (![self testLoggedIn:fail]) {
        return;
    }
    
    LogDebug(TAG, @"Getting contacts");

    NSString *cursor = fromStart ? nil : self.lastContactCursor;
    self.lastContactCursor = nil;

    [self.twitter getFriendsListForUserID:loggedInUser orScreenName:loggedInUser cursor:cursor count:@"20" skipStatus:@(YES) includeUserEntities:@(YES)
                             successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor) {

                                 self.lastContactCursor = nextCursor;

                                 LogDebug(TAG, ([NSString stringWithFormat:@"Get contacts success: %@", users]));

                                 NSMutableArray *contacts = [NSMutableArray array];

                                 for (NSDictionary *userDict in users) {
                                     UserProfile *contact = [self parseUserProfile:userDict];
                                     [contacts addObject:contact];
                                 }

                                 success(contacts, [nextCursor longLongValue] != 0);

                             } errorBlock:^(NSError *error) {
                LogError(TAG, ([NSString stringWithFormat:@"Get contacts error: %@", error.localizedDescription]));

                fail([NSString stringWithFormat:@"%ld: %@", (long) error.code, error.localizedDescription]);
            }];
}

- (void)getFeed:(bool)fromStart success:(feedsActionSuccess)success fail:(feedsActionFail)fail {
    if (![self testLoggedIn:fail]) {
        return;
    }
    
    LogDebug(TAG, @"Getting feed");

    NSString *cursor = fromStart ? nil : self.lastFeedCursor;
    self.lastFeedCursor = nil;

    [self.twitter getUserTimelineWithScreenName:loggedInUser sinceID:cursor maxID:nil count:DEFAULT_PAGE_SIZE
                                   successBlock:^(NSArray *statuses) {
                                       LogDebug(TAG, ([NSString stringWithFormat:@"Get feed success: %@", statuses]));

                                       id lastId = nil;
                                       
                                       NSMutableArray *feeds = [NSMutableArray array];
                                       for (NSDictionary *statusDict in statuses) {
                                           NSString *str;
                                           str = statusDict[@"text"];
                                           if (str) {
                                               [feeds addObject:str];
                                           }
                                           lastId = statusDict[@"id"];
                                       }
                                       if (feeds.count >= DEFAULT_PAGE_SIZE) {
                                           self.lastFeedCursor = lastId;
                                       }
                                       success(feeds, self.lastFeedCursor != nil);
                                   }
                                     errorBlock:^(NSError *error) {
                                         LogError(TAG, ([NSString stringWithFormat:@"Get feed error: %@", error]));
                                     }];
}

- (void)uploadImageWithMessage:(NSString *)message
                   andFilePath:(NSString *)filePath
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail {
    if (![self testLoggedIn:fail]) {
        return;
    }
    
    LogDebug(TAG, @"Uploading image");
    
    [self.twitter postMediaUpload:[NSURL fileURLWithPath:filePath]
              uploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
                  // nothing to do here
              } successBlock:^(NSDictionary *imageDictionary, NSString *mediaID, NSString *size) {
                  [self.twitter postStatusUpdate:message inReplyToStatusID:nil
                                        mediaIDs:[NSArray arrayWithObject:mediaID] latitude:nil longitude:nil placeID:nil displayCoordinates:@(NO) trimUser:nil
                                    successBlock:^(NSDictionary *status) {
                                        LogDebug(TAG, ([NSString stringWithFormat:@"Upload image (status) success: %@", status]));
                                        success();
                                    } errorBlock:^(NSError *error) {
                                        LogError(TAG, ([NSString stringWithFormat:@"Upload image (status) error: %@", error]));
                                        fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
                                    }];
              } errorBlock:^(NSError *error) {
                  LogError(TAG, ([NSString stringWithFormat:@"Upload image error: %@", error]));
                  fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
              }];
}

- (void)uploadImageWithMessage:(NSString *)message
              andImageFileName: (NSString *)fileName
                  andImageData: (NSData *)imageData
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail{
    if (![self testLoggedIn:fail]) {
        return;
    }

    LogDebug(TAG, @"Uploading image");

    [self.twitter postMediaUploadData:imageData fileName:fileName uploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        // nothing to do here
    } successBlock:^(NSDictionary *imageDictionary, NSString *mediaID, NSString *size) {
        [self.twitter postStatusUpdate:message inReplyToStatusID:nil
                              mediaIDs:[NSArray arrayWithObject:mediaID] latitude:nil longitude:nil placeID:nil displayCoordinates:@(NO) trimUser:nil
                          successBlock:^(NSDictionary *status) {
                              LogDebug(TAG, ([NSString stringWithFormat:@"Upload image (status) success: %@", status]));
                              success();
                          } errorBlock:^(NSError *error) {
                              LogError(TAG, ([NSString stringWithFormat:@"Upload image (status) error: %@", error]));
                              fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
                          }];
    } errorBlock:^(NSError *error) {
        LogError(TAG, ([NSString stringWithFormat:@"Upload image error: %@", error]));
        fail([NSString stringWithFormat:@"%ld: %@", (long)error.code, error.localizedDescription]);
    }];
}

- (void)like:(NSString *)pageId {
    
    NSString *baseURL = @"twitter:///user?screen_name=";
    
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:baseURL]])
    {
        baseURL = @"https://www.twitter.com/";
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseURL, pageId]]];
}

- (NSString *) getURLScheme {
    return [[NSString stringWithFormat:@"tw%@", self.consumerKey] lowercaseString];
}

//
// Private Methods
//


/*
 Helper methods for clearing callback blocks
 */

- (void)clearLoginBlocks {
    self.loginSuccess = nil;
    self.loginFail = nil;
    self.loginCancel = nil;
}

- (void)cleanTokensFromDB {
    [KeyValueStorage deleteValueForKey:[self getTwitterStorageKey:TWITTER_OAUTH_TOKEN]];
    [KeyValueStorage deleteValueForKey:[self getTwitterStorageKey:TWITTER_OAUTH_SECRET]];
}

- (BOOL) isEmptyString:(NSString *)target {
    return !target || ([target length] == 0);
}

- (NSString *) getTwitterStorageKey:(NSString *)postfix {
    return [NSString stringWithFormat:@"%@%@", DB_KEY_PREFIX, postfix];
}

- (BOOL)testLoggedIn:(socialActionFail)fail {
    if (![self isLoggedIn]) {
        fail(@"User did not login to Twitter, did you forget to login?");
        return NO;
    }
    
    return YES;
}

- (UserProfile *)parseUserProfile:(NSDictionary *)user {
    NSString *fullName = user[@"name"];
    NSString *firstName = @"";
    NSString *lastName = @"";
    if (fullName) {
        NSArray *names = [fullName componentsSeparatedByString:@" "];
        if (names && ([names count] > 0)) {
            firstName = names[0];
            if ([names count] > 1) {
                lastName = names[1];
            }
        }
    }
    
    // According to: https://dev.twitter.com/rest/reference/get/users/show
    //
    // - Twitter does not supply email access: https://dev.twitter.com/faq#26
    UserProfile *userProfile = [[UserProfile alloc] initWithProvider:TWITTER
                                                        andProfileId:user[@"id_str"]
                                                         andUsername:user[@"screen_name"]
                                                            andEmail:@""
                                                        andFirstName:firstName
                                                         andLastName:lastName];
    
    // No gender information on Twitter:
    // https://twittercommunity.com/t/how-to-find-male-female-accounts-in-following-list/7367
    userProfile.gender = @"";
    
    // No birthday on Twitter:
    // https://twittercommunity.com/t/how-can-i-get-email-of-user-if-i-use-api/7019/16
    userProfile.birthday = @"";
    
    userProfile.language = user[@"lang"];
    userProfile.location = user[@"location"];
    userProfile.avatarLink = user[@"profile_image_url"];
    return userProfile;
}

@end

#pragma clang diagnostic pop