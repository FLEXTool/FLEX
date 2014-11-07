//
//  AAPLNetworkViewController.m
//  UICatalog
//
//  Created by Dal Rupnik on 06/11/14.
//  Copyright (c) 2014 f. All rights reserved.
//

#import "AAPLNetworkViewController.h"

@interface AAPLNetworkViewController () <NSURLConnectionDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *methodSegmentedControl;
@property (weak, nonatomic) IBOutlet UITextView *responseTextView;

@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation AAPLNetworkViewController

- (void)viewDidLoad
{
    self.urlTextField.text = @"http://www.arvystate.net";
    self.methodSegmentedControl.selectedSegmentIndex = 0;
}

- (IBAction)sendRequestButtonTap:(UIButton *)sender
{
    NSURL *url = [NSURL URLWithString:self.urlTextField.text];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init];
    [urlRequest setURL:url];
    
    switch (self.methodSegmentedControl.selectedSegmentIndex)
    {
        case 1:
            [urlRequest setHTTPMethod:@"POST"];
            break;
        case 2:
            [urlRequest setHTTPMethod:@"PUT"];
            break;
        case 3:
            [urlRequest setHTTPMethod:@"DELETE"];
            break;
        default:
            [urlRequest setHTTPMethod:@"GET"];
            break;
    }
    
    self.responseData = [NSMutableData data];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.responseTextView.text = [error localizedDescription];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the instance variable you declared
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *string = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    
    self.responseTextView.text = string;
    
}

@end
