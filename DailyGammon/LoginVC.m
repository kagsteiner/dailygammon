//
//  Login.m
//  DailyGammon
//
//  Created by Peter on 27.11.18.
//  Copyright © 2018 Peter Schneider. All rights reserved.
//

#import "LoginVC.h"
#import "Design.h"
#import "TopPageCV.h"
#import "NSDictionary+PercentEncodeURLQueryValue.h"
#import "AppDelegate.h"
#import <SafariServices/SafariServices.h>
#import "DGButton.h"

@interface LoginVC ()<NSURLSessionDataDelegate>

@property (weak, nonatomic) IBOutlet UILabel *header;

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet DGButton *loginButton;

@property (weak, nonatomic) IBOutlet UILabel *accountLabel;
@property (weak, nonatomic) IBOutlet DGButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UILabel *faqLabel;
@property (weak, nonatomic) IBOutlet DGButton *faqButton;

@property (readwrite, retain, nonatomic) NSURLConnection *downloadConnection;

@end

@implementation LoginVC

@synthesize design;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorNamed:@"ColorViewBackground"];;
    design = [[Design alloc] init];
        
    // Clear session cookies - code generated by ChatGPT and checked by kha
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    
    // Clear stored login information - code generated by ChatGPT and checked by kha
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"user"];
    [defaults removeObjectForKey:@"password"];
    [defaults synchronize];

    [self.username setDelegate:self];
    [self.password  setDelegate:self];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [self layoutObjects];

}

- (BOOL)textFieldShouldReturn:(UITextView *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (IBAction)loginAction:(id)sender
{
    NSString *userName = self.username.text;
    NSString *userPassword = self.password.text;
    
    NSString *post               = [NSString stringWithFormat:@"login=%@&password=%@",userName,userPassword];
    NSData *postData             = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength         = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://dailygammon.com/bg/login"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];

}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    NSDictionary *fields = [HTTPResponse allHeaderFields];
    NSString *cookie = [fields valueForKey:@"Set-Cookie"];
    XLog(@"Connection begonnen %@", cookie);
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    XLog(@"Connection didReceiveData");
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error)
    {
        XLog(@"Connection didFailWithError %@", error.localizedDescription);
        return;
    }

    XLog(@"Connection Finished");
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        NSLog(@"name: '%@'\n",   [cookie name]);
        NSLog(@"value: '%@'\n",  [cookie value]);
        NSLog(@"domain: '%@'\n", [cookie domain]);
        NSLog(@"path: '%@'\n",   [cookie path]);
        if([[cookie value] isEqualToString:@"N/A"])
        {
            XLog(@"login nicht ok");
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"Message"
                                         message:@"We cannot validate the user name and password entered"
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* yesButton = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                        }];
            UIAlertAction* helpButton = [UIAlertAction
                                         actionWithTitle:@"Need help"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                              NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.dailygammon.com/help/index.html#pw"]];
                                              if ([SFSafariViewController class] != nil) {
                                                  SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL];
                                                  [self presentViewController:sfvc animated:YES completion:nil];
                                              } else {
                                                  [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
                                              }

                                         }];

            [alert addAction:yesButton];
            [alert addAction:helpButton];

            [self presentViewController:alert animated:YES completion:nil];

        }
        else
        {
            XLog(@"login ok");
            [[NSUserDefaults standardUserDefaults] setValue:self.username.text forKey:@"user"];
            [[NSUserDefaults standardUserDefaults] setValue:self.password.text forKey:@"password"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            TopPageCV *vc = [[UIStoryboard storyboardWithName:@"iPad" bundle:nil]  instantiateViewControllerWithIdentifier:@"TopPageCV"];
            [self.navigationController pushViewController:vc animated:NO];
        }
    }
    NSArray *cookie = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    if(cookie.count < 1)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"Message"
                                     message:@"An error has occured processing your login"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Try again"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                    }];
        
        UIAlertAction* helpButton = [UIAlertAction
                                     actionWithTitle:@"Need help"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action)
                                     {
                                          NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.dailygammon.com/help/index.html#pw"]];
                                          if ([SFSafariViewController class] != nil) {
                                              SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL];
                                              [self presentViewController:sfvc animated:YES completion:nil];
                                          } else {
                                              [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
                                          }

                                     }];

        [alert addAction:yesButton];
        [alert addAction:helpButton];

        [self presentViewController:alert animated:YES completion:nil];

    }
    XLog(@"%@", [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]);
}

- (IBAction)createAccountAction:(id)sender
{
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://dailygammon.com/bg/create"]];
    if ([SFSafariViewController class] != nil) {
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL];
        [self presentViewController:sfvc animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    }
}
- (IBAction)faqAction:(id)sender
{
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://dailygammon.com/help"]];
    if ([SFSafariViewController class] != nil) {
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL];
        [self presentViewController:sfvc animated:YES completion:nil];
    } else {
        [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    }

}

#pragma mark - Email
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (error)
    {
        XLog(@"Error MFMailComposeViewController: %@", error);
    }
    [controller dismissViewControllerAnimated:YES completion:NULL];
}
#pragma mark - autoLayout
-(void)layoutObjects
{
    UIView *superview = self.view;
    UILayoutGuide *safe = superview.safeAreaLayoutGuide;
    float edge = 5.0;
    float gap = 5.0;

#pragma mark header autoLayout
    [self.header setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.header.topAnchor constraintEqualToAnchor:safe.topAnchor constant:10.0].active = YES;
    [self.header.heightAnchor constraintEqualToConstant:40].active = YES;
    [self.header.leftAnchor constraintEqualToAnchor:safe.leftAnchor constant:edge].active = YES;
    [self.header.rightAnchor constraintEqualToAnchor:safe.rightAnchor constant:-edge].active = YES;

#pragma mark user & password autoLayout

    [self.usernameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.username setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.loginButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    CGFloat labelWidth  = 100.0;
    CGFloat labelHeigth = 35.0;

    [self.usernameLabel.widthAnchor constraintEqualToConstant:labelWidth].active = YES;
    [self.usernameLabel.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.usernameLabel.topAnchor constraintEqualToAnchor:self.header.bottomAnchor constant:20.0].active = YES;

    [self.username.widthAnchor constraintEqualToConstant:labelWidth*2].active = YES;
    [self.username.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.username.topAnchor constraintEqualToAnchor:self.header.bottomAnchor constant:20.0].active = YES;

    // Center label and text field horizontally together
    CGFloat totalWidth = (labelWidth * 3)+ gap;
    [self.usernameLabel.leadingAnchor constraintEqualToAnchor:superview.centerXAnchor constant:-totalWidth / 2.0f].active = YES;
    [self.username.trailingAnchor constraintEqualToAnchor:superview.centerXAnchor constant:totalWidth / 2.0f].active = YES;
    

    [self.passwordLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.password setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.passwordLabel.widthAnchor constraintEqualToConstant:labelWidth].active = YES;
    [self.passwordLabel.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.passwordLabel.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:20.0].active = YES;

    [self.password.widthAnchor constraintEqualToConstant:labelWidth*2].active = YES;
    [self.password.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.password.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:20.0].active = YES;

    // Center label and text field horizontally together
    [self.passwordLabel.leadingAnchor constraintEqualToAnchor:superview.centerXAnchor constant:-totalWidth / 2.0f].active = YES;
    [self.password.trailingAnchor constraintEqualToAnchor:superview.centerXAnchor constant:totalWidth / 2.0f].active = YES;

    
    [self.loginButton.widthAnchor constraintEqualToConstant:150].active = YES;
    [self.loginButton.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.loginButton.topAnchor constraintEqualToAnchor:self.passwordLabel.bottomAnchor constant:20.0].active = YES;
    [self.loginButton.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor].active = YES;

#pragma mark faq autoLayout

    [self.faqLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.faqButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.faqButton.widthAnchor constraintEqualToConstant:150].active = YES;
    [self.faqButton.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.faqButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-gap].active = YES;
    [self.faqButton.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor].active = YES;

    [self.faqLabel.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.faqLabel.bottomAnchor constraintEqualToAnchor:self.faqButton.topAnchor constant:-gap].active = YES;
    [self.faqLabel.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor].active = YES;

#pragma account autoLayout

    [self.accountLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.createAccountButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.createAccountButton.widthAnchor constraintEqualToConstant:150].active = YES;
    [self.createAccountButton.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.createAccountButton.bottomAnchor constraintEqualToAnchor:self.faqLabel.topAnchor constant:-gap].active = YES;
    [self.createAccountButton.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor].active = YES;

    [self.accountLabel.heightAnchor constraintEqualToConstant:labelHeigth].active = YES;
    [self.accountLabel.bottomAnchor constraintEqualToAnchor:self.createAccountButton.topAnchor constant:-gap].active = YES;
    [self.accountLabel.centerXAnchor constraintEqualToAnchor:superview.centerXAnchor].active = YES;

}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         // Code to be executed during the animation
        
     } completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         // Code to be executed after the animation is completed
     }];

    XLog(@"Neue Breite: %.2f, Neue Höhe: %.2f", size.width, size.height);
    
}

@end
