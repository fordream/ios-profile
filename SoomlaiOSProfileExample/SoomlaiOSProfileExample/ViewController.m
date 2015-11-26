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

#import "ViewController.h"
#import "AppDelegate.h"
#import "SoomlaProfile.h"
#import "ProfileEventHandling.h"
#import "SoomlaEventHandling.h"
#import "SoomlaUtils.h"
#import "UserProfile.h"


@implementation ViewController

static NSString* TAG = @"SOOMLA ViewController";
static Provider TARGET_PROVIDER = FACEBOOK;

BOOL isLoginState = YES;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginStarted:) name:EVENT_UP_LOGIN_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:EVENT_UP_LOGIN_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFailed:) name:EVENT_UP_LOGIN_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginCancelled:) name:EVENT_UP_LOGIN_CANCELLED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutFinished:) name:EVENT_UP_LOGOUT_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getContactsFinished:) name:EVENT_UP_GET_CONTACTS_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getContactsFailed:) name:EVENT_UP_GET_CONTACTS_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getFeedFinished:) name:EVENT_UP_GET_FEED_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getFeedFailed:) name:EVENT_UP_GET_FEED_FAILED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(socialActionFinished:) name:EVENT_UP_SOCIAL_ACTION_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rewardGiven:) name:EVENT_REWARD_GIVEN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileInitialized:) name:EVENT_UP_PROFILE_INITIALIZED object:nil];

    NSDictionary* providerParams = @{ @(TWITTER) :
                                          @{ @"consumerKey": @"[YOUR CONSUMER KEY]",
                                             @"consumerSecret": @"[YOUR CONSUMER SECRET]" },
                                      @(GOOGLE) :
                                          @ {@"clientId": @"[YOUR CLIENT ID"} };
    [[SoomlaProfile getInstance] initialize:providerParams];

    if ([[SoomlaProfile getInstance] isLoggedInWithProvider:TARGET_PROVIDER]) {
        [self setLoginVisibility:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)buttonTouched:(id)sender {

    if ([[SoomlaProfile getInstance] isLoggedInWithProvider:TARGET_PROVIDER] && !isLoginState) {

        [[SoomlaProfile getInstance] logoutWithProvider:TARGET_PROVIDER];
    } else {
        TARGET_PROVIDER = FACEBOOK;
        [self loginToCurrentProvider];
    }
}

- (IBAction)loginTwitterButtonTouched:(id)sender {
    TARGET_PROVIDER = TWITTER;
    [self loginToCurrentProvider];
}

- (IBAction)loginGoogleButtonTouched:(id)sender {
    TARGET_PROVIDER = GOOGLE;
    [self loginToCurrentProvider];
}

- (void) loginToCurrentProvider {
    // Retrieve the app delegate
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

    [[SoomlaProfile getInstance] loginWithProvider:TARGET_PROVIDER andPayload:@"" andReward:nil];
}

- (IBAction)backTouched:(id)sender {
    [self setLoginVisibility:YES];
}

- (IBAction)shareStatusButtontouched:(id)sender {

    // Retrieve the app delegate
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

    [[SoomlaProfile getInstance] updateStatusWithProvider:TARGET_PROVIDER andStatus:@"Test status" andReward:nil];

    // Or with dialog
    //[[SoomlaProfile getInstance] updateStatusWithProviderDialog:TARGET_PROVIDER andLink:@"http://www.soom.la" andPayload:@"status" andReward:appDelegate.updateStatusReward];
}

- (IBAction)updateStoryButtonTouched:(id)sender {

    // Retrieve the app delegate
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

    [[SoomlaProfile getInstance] updateStoryWithProvider:TARGET_PROVIDER
                                              andMessage:@"Message"
                                                 andName:@"Name"
                                              andCaption:@"Caption"
                                          andDescription:@"Description"
                                                 andLink:@"https://developers.facebook.com/docs/ios/share/"
                                              andPicture:@"http://i.imgur.com/g3Qc1HN.png"
                                               andReward:nil];
    // Or with dialog
    // [[SoomlaProfile getInstance] updateStoryWithProviderDialog:TARGET_PROVIDER
    //                                             andName:@"Name"
    //                                          andCaption:@"Caption"
    //                                      andDescription:@"Description"
    //                                             andLink:@"http://www.soom.la"
    //                                          andPicture:@"http://i.imgur.com/g3Qc1HN.png"
    //                                          andPayload:@"story"
    //                                           andReward:appDelegate.updateStatusReward];
}

- (void)loginStarted:(NSNotification*)notification {
    NSString* provider = [UserProfileUtils providerEnumToString:[notification.userInfo[DICT_ELEMENT_PROVIDER] intValue]];
    LogDebug(TAG, ([NSString stringWithFormat:@"Login started with provider: %@", provider]));
}

- (void)loginFinished:(NSNotification*)notification {
    LogDebug(TAG, @"Login Success: you are now logged in to Facebook");
    // TODO: extract user profile object from notification
    // NSDictionary* userInfo = notification.userInfo;

    [self setLoginVisibility:NO];

//    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
//    if (appDelegate.likeReward.canGive == YES) {
//        [[SoomlaProfile getInstance] like:TARGET_PROVIDER andPageId:@"The.SOOMLA.Project" andReward:appDelegate.likeReward];
//    }
}

- (void)loginFailed:(NSNotification*)notification {
    LogError(TAG, ([NSString stringWithFormat:@"Login Failed: %@", notification.userInfo[DICT_ELEMENT_MESSAGE]]));
    [self setLoginVisibility:YES];
}

- (void)loginCancelled:(NSNotification*)notification {
    LogDebug(TAG, @"Login Cancelled: you cancelled the login process");
    [self setLoginVisibility:YES];
}

- (void)logoutFinished:(NSNotification*)notification {
    [self setLoginVisibility:YES];
}

- (void)setLoginVisibility:(BOOL)visible {
    if (!visible) {
        if ([[SoomlaProfile getInstance] isLoggedInWithProvider:TARGET_PROVIDER]) {
            [self.loginButton setTitle:@"Logout" forState:UIControlStateNormal];
        }
    }
    else {
        [self.loginButton setTitle:@"Login with Facebook to earn 100 coins" forState:UIControlStateNormal];
    }

    [self.loginTwitterButton setHidden:!visible];
    [self.loginGoogleButton setHidden:!visible];

    [self.updateStatusButton setHidden:visible];
    [self.updateStoryButton setHidden:visible];
    [self.uploadImageButton setHidden:visible];
    [self.getContactsButton setHidden:visible];
    [self.getFeedButton setHidden:visible];
    [self.backButton setHidden:visible];

    isLoginState = visible;
}

- (void)currencyBalanceChanged:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    self.currencyLabel.text = [NSString stringWithFormat:@"Coins: %d", [[userInfo objectForKey:@"balance"] intValue]];
}

- (void)getContactsFinished:(NSNotification*)notification {
    NSArray* contacts = notification.userInfo[DICT_ELEMENT_CONTACTS];
    for (int i = 0; i < [contacts count]; i++)
    {
        UserProfile* current = [contacts objectAtIndex:i];
        NSLog(@"%@", [current getFullName]);
    }
}

- (void)getContactsFailed:(NSNotification*)notification {
    NSLog(@"%@ Failed: %@", notification.userInfo[DICT_ELEMENT_SOCIAL_ACTION_TYPE], notification.userInfo[DICT_ELEMENT_MESSAGE]);
}

- (void)getFeedFinished:(NSNotification*)notification {
    NSArray* feeds = notification.userInfo[DICT_ELEMENT_FEEDS];
    for (int i = 0; i < [feeds count]; i++)
    {
        NSString* current = [feeds objectAtIndex:i];
        NSLog(@"%@", current);
    }
}

- (void)getFeedFailed:(NSNotification*)notification {
    NSLog(@"%@ Faild: %@", notification.userInfo[DICT_ELEMENT_SOCIAL_ACTION_TYPE], notification.userInfo[DICT_ELEMENT_MESSAGE]);
}

- (void)rewardGiven:(NSNotification*)notification {
    NSLog(@"Reward Given: %@", notification.userInfo[DICT_ELEMENT_REWARD]);
}

- (void)profileInitialized:(NSNotification*)notification {
    NSLog(@"PROFILE was initalized!");
}

- (void)socialActionFinished:(NSNotification*)notification {
    LogDebug(TAG, ([NSString stringWithFormat:@"Social action %@ was finished!", notification.userInfo[DICT_ELEMENT_SOCIAL_ACTION_TYPE]]));
}

- (IBAction)uploadImageTouched:(id)sender {
    // Open the image picker and set this class as the delegate
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];

    NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath =  [docDirPath stringByAppendingPathComponent:@"tmp.png"];
    NSLog (@"File Path = %@", filePath);
    // Get PNG data from following method
    NSData *myData =     UIImagePNGRepresentation(img);
    // It is better to get JPEG data because jpeg data will store the location and other related information of image.
    [myData writeToFile:filePath atomically:YES];

    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [[SoomlaProfile getInstance] uploadImageWithProvider:TARGET_PROVIDER andMessage:@"Text photo message" andFilePath:filePath andReward:nil];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)getContactsButtonTouched:(id)sender {
    [[SoomlaProfile getInstance] getContactsWithProvider:TARGET_PROVIDER andReward:nil];
}

- (IBAction)getFeedTouched:(id)sender {
    [[SoomlaProfile getInstance] getFeedWithProvider:TARGET_PROVIDER andReward:nil];
}

@end
