//
//  ViewController.m
//  play-transport-ble-mac
//
//  Created by Luis Laugga on 02.11.15.
//  Copyright © 2015 Luis Laugga. All rights reserved.
//

#import "ViewController.h"

#import <UniversalBluetooth/UniversalBluetooth.h>

@interface ViewController () <NSTextViewDelegate, UniversalBluetoothDelegate>

@property (nonatomic, strong) UniversalBluetooth * UniversalBluetooth;
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.string = @"Not connected. Bring the other device closer...";
    self.textView.editable = NO;
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    self.UniversalBluetooth = [[UniversalBluetooth alloc] init];
    self.UniversalBluetooth.delegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.UniversalBluetooth startAdvertising];
    });
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark -
#pragma mark UniversalBluetoothDelegate

- (void)UniversalBluetoothDidConnect:(UniversalBluetooth *)UniversalBluetooth
{
    self.textView.string = @"Connected :)";
    self.textView.editable = YES;
}

- (void)UniversalBluetoothDidDisconnect:(UniversalBluetooth *)UniversalBluetooth
{
    self.textView.string = @"Not connected. Bring the other device closer...";
    self.textView.editable = NO;
}

- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didUpdateRSSI:(NSNumber *)RSSI
{
    NSLog(@"UniversalBluetooth:didUpdateRSSI: %@", RSSI);
    
    //self.debubL
}

- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didReceiveObject:(NSDictionary *)object
{
    NSDictionary * message = object[@"message"];
    if (message) {
        NSString * text = message[@"text"];
        self.textView.string = text;
    }
}

#pragma mark -
#pragma mark NSTextViewDelegate

- (void)textDidChange:(NSNotification *)notification
{
    NSTextView *textView = [notification object];
    [textView setString:[[textView string] uppercaseString]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.UniversalBluetooth sendObject:@{@"type":@"message",@"message":@{@"text":textView.string, @"from":@"mac"}}];
    });
}

@end
