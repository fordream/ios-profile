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

#import "SoomlaGooglePlus.h"
#import "UserProfile.h"
#import "SoomlaUtils.h"
#import <GoogleOpenSource/GoogleOpenSource.h>

@implementation SoomlaGooglePlus

@synthesize loginSuccess, loginFail, loginCancel, logoutSuccess, logoutFail, socialActionSuccess, socialActionFail, clientId;

static NSString *TAG = @"SOOMLA SoomlaGooglePlus";

- (id)init{
    self = [super init];
    
    if (!self)
        return nil;
    
    LogDebug(TAG, @"addObserver kUnityOnOpenURL notification");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(innerHandleOpenURL:)
                                                 name:@"kUnityOnOpenURL"
                                               object:nil];
    
    return self;
}

- (void)applyParams:(NSDictionary *)providerParams{
    if (providerParams){
        clientId = [providerParams objectForKey:@"clientId"];
    }
}

- (void)login:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel{
    LogDebug(TAG, @"Login");
    
    [self setLoginBlocks:success fail:fail cancel:cancel];
    
    NSString *authParamsCheckResult = [self checkAuthParams];
    
    if (authParamsCheckResult){
        fail([NSString stringWithFormat:@"Authentication params check failed: %@", authParamsCheckResult]);
        return;
    }
    
    [self startGooglePlusAuth];
}

//sets scopes and additional flags for google plus connection
//and triggers authentication
- (void)startGooglePlusAuth{
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    GPPShare *share = [GPPShare sharedInstance];
    NSArray* scopes = [NSArray arrayWithObjects:kGTLAuthScopePlusLogin,kGTLAuthScopePlusUserinfoProfile, nil];
    
    signIn.shouldFetchGoogleUserEmail = YES;
    signIn.shouldFetchGooglePlusUser = YES;
    signIn.attemptSSO = YES; // tries to use other installed Google apps
    signIn.clientID = self.clientId;
    signIn.scopes = scopes;
    
    signIn.delegate = self;
    share.delegate = self;
    
    [signIn authenticate];
}

//callback for GPPSignIn end of authentication process
- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error {
    if (error) {
        if ([error code] == -1)
            self.loginCancel();
        else
            self.loginFail([error localizedDescription]);
    } else {
        [self refreshInterfaceBasedOnSignIn];
    }
}

//check if authentication status and update
-(void)refreshInterfaceBasedOnSignIn {
    if ([[GPPSignIn sharedInstance] authentication]) {
        // The user is signed in.
        self.loginSuccess(GOOGLE);
    } else {
        [self clearLoginBlocks];
        self.loginFail(@"GooglePlus Authentication failed.");
    }
}

- (void)getUserProfile:(userProfileSuccess)success fail:(userProfileFail)fail{
    LogDebug(TAG, @"getUserProfile");
    GTLServicePlus* plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;
    [plusService setAuthorizer:[GPPSignIn sharedInstance].authentication];
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    [plusService executeQuery:query
            completionHandler:^(GTLServiceTicket *ticket,
                                GTLPlusPerson *person,
                                NSError *error) {
                if (error) {
                    LogError(TAG, @"Failed getting user profile");
                    fail([error localizedDescription]);
                } else {
                    UserProfile *userProfile = [self parseGoogleContact:person];
//                    userProfile.email = [[[GPPSignIn sharedInstance] authentication]userEmail];
                    success(userProfile);
                }
            }];
}

- (void)logout:(logoutSuccess)success fail:(logoutFail)fail{
    LogDebug(TAG, @"logout");
    self.logoutSuccess = success;
    self.logoutFail = fail;
    [[GPPSignIn sharedInstance] disconnect];
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        self.logoutFail([error localizedDescription]);
    } else {
        // The user is signed out and disconnected.
        [self clearLoginBlocks];
        self.logoutSuccess();
    }
}

- (BOOL)isLoggedIn{
    LogDebug(TAG, @"isLoggedIn");
    return ([GPPSignIn sharedInstance].authentication != nil);
}

- (BOOL)tryHandleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    return [GPPURLHandler handleURL:url
           sourceApplication:sourceApplication
                         annotation:annotation];
}

- (void)updateStatus:(NSString *)status success:(socialActionSuccess)success fail:(socialActionFail)fail{
    LogDebug(TAG, @"updateStatus");
    [self setSocialActionBlocks:success fail:fail];
    id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    [shareBuilder setPrefillText:status];
    [shareBuilder open];
}

- (void)updateStatusWithProviderDialog:(NSString *)link success:(socialActionSuccess)success fail:(socialActionFail)fail{
    LogDebug(TAG, @"updateStatus");
    [self setSocialActionBlocks:success fail:fail];
    id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    [shareBuilder setURLToShare:[NSURL URLWithString:link]];
    [shareBuilder open];
}

- (void)updateStoryWithMessage:(NSString *)message
                       andName:(NSString *)name
                    andCaption:(NSString *)caption
                andDescription:(NSString *)description
                       andLink:(NSString *)link
                    andPicture:(NSString *)picture
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail
{
    [self setSocialActionBlocks:success fail:fail];
    id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    [shareBuilder setPrefillText:message];
    [shareBuilder setURLToShare:[NSURL URLWithString:link]];
    [shareBuilder open];
}

- (void)updateStoryWithMessageDialog:(NSString *)name
                          andCaption:(NSString *)caption
                      andDescription:(NSString *)description
                             andLink:(NSString *)link
                          andPicture:(NSString *)picture
                             success:(socialActionSuccess)success
                                fail:(socialActionFail)fail
{
    fail(@"updateStoryWithMessageDialog is not implemented");
}

- (void)uploadImageWithMessage:(NSString *)message
                   andFilePath:(NSString *)filePath
                       success:(socialActionSuccess)success
                          fail:(socialActionFail)fail
{
    LogDebug(TAG, @"uploadImage");
    [self setSocialActionBlocks:success fail:fail];
    [GPPShare sharedInstance].delegate = self;
    id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    [shareBuilder setPrefillText:message];
    [shareBuilder attachImage:[UIImage imageWithContentsOfFile:filePath]];
    [shareBuilder open];
}

//callback for GPPShare end of share
- (void)finishedSharingWithError:(NSError *)error {
    
    if (!error) {
        self.socialActionSuccess();
    } else if (error.code == kGPPErrorShareboxCanceled) {
        self.socialActionFail(@"Social Action Cancelled");
    } else {
        self.socialActionFail([NSString stringWithFormat:@"Social Action Failed (%@)", [error localizedDescription]]);
    }
    [self clearSocialActionBlocks];
}

- (void)getContacts:(contactsActionSuccess)success fail:(contactsActionFail)fail{
    LogDebug(TAG, @"getContacts");
    GTLServicePlus* plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;
    [plusService setAuthorizer:[GPPSignIn sharedInstance].authentication];
    
    GTLQueryPlus *query =
    [GTLQueryPlus queryForPeopleListWithUserId:@"me"
                                    collection:kGTLPlusCollectionVisible];
    [plusService executeQuery:query
            completionHandler:^(GTLServiceTicket *ticket,
                                GTLPlusPeopleFeed *peopleFeed,
                                NSError *error) {
                if (error) {
                    LogError(TAG, @"Failed getting contacts");
                    fail([error localizedDescription]);
                } else {
                    // Get an array of people from GTLPlusPeopleFeed
                    NSArray* rawContacts = peopleFeed.items;
                    
                    NSMutableArray *contacts = [NSMutableArray array];
                    
                    for (GTLPlusPerson *rawContact in rawContacts) {
                        UserProfile *contact = [self parseGoogleContact:rawContact];
                        
                        [contacts addObject:contact];
                    }
                    
                    success(contacts);
                }
            }];
}

- (void)getFeed:(feedsActionSuccess)success fail:(feedsActionFail)fail{
    LogDebug(TAG, @"getFeed");
    fail(@"getFeed is not implemented!");
}

- (Provider)getProvider {
    return GOOGLE;
}

- (void)like:(NSString *)pageName{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"https://plus.google.com/+", pageName]];
    [[UIApplication sharedApplication] openURL:url];
}

-(UserProfile *) parseGoogleContact: (GTLPlusPerson *)googleContact{
    NSString* displayName = googleContact.displayName;
    NSString* firstName, *lastName;
    
    if (displayName)
    {
        NSArray *names = [displayName componentsSeparatedByString:@" "];
        if (names && ([names count] > 0)) {
            firstName = names[0];
            if ([names count] > 1) {
                lastName = names[1];
            }
        }
    }
    
    GTLPlusPersonEmailsItem *email = [googleContact.emails objectAtIndex:0];
    UserProfile * profile =
    [[UserProfile alloc] initWithProvider:GOOGLE
                             andProfileId:[self parseGoogleContactInfoString:googleContact.identifier]
                              andUsername: @""
                                 andEmail:[self parseGoogleContactInfoString:[email value]]
                             andFirstName:firstName
                              andLastName:lastName];
    
    profile.username = @"";
    profile.gender = [self parseGoogleContactInfoString:googleContact.gender];
    profile.birthday = [self parseGoogleContactInfoString:googleContact.birthday];
    profile.location = [self parseGoogleContactInfoString:googleContact.currentLocation];
    profile.avatarLink = [self parseGoogleContactInfoString:[googleContact.image url]];
    profile.language = [self parseGoogleContactInfoString:googleContact.language];
    
    return profile;
}

- (NSString *)parseGoogleContactInfoString:(NSString * )orig{
    return (orig) ? orig : @"";
}

-(void)setLoginBlocks:(loginSuccess)success fail:(loginFail)fail cancel:(loginCancel)cancel{
    self.loginSuccess = success;
    self.loginFail = fail;
    self.loginCancel = cancel;
}

-(void)setSocialActionBlocks:(socialActionSuccess)success fail:(socialActionFail)fail{
    self.socialActionSuccess = success;
    self.socialActionFail = fail;
}

- (void)clearLoginBlocks {
    self.loginSuccess = nil;
    self.loginFail = nil;
    self.loginCancel = nil;
}

- (void)clearSocialActionBlocks {
    self.socialActionSuccess = nil;
    self.socialActionFail = nil;
}

- (NSString *)checkAuthParams{
    if (!clientId)
        return @"Missing client id";
    return nil;
}

- (void)innerHandleOpenURL:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"kUnityOnOpenURL"]) {
        LogDebug(TAG, @"Successfully received the kUnityOnOpenURL notification!");
        
        NSURL *url = [[notification userInfo] valueForKey:@"url"];
        NSString *sourceApplication = [[notification userInfo] valueForKey:@"sourceApplication"];
        id annotation = [[notification userInfo] valueForKey:@"annotation"];
        BOOL urlWasHandled = [GPPURLHandler handleURL:url
                                    sourceApplication:sourceApplication
                                           annotation:annotation];
        
        LogDebug(TAG,
                 ([NSString stringWithFormat:@"urlWasHandled: %@",
                   urlWasHandled ? @"True" : @"False"]));
    }
}

- (void)dealloc {
    LogDebug(TAG, @"removeObserver kUnityOnOpenURL notification");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end