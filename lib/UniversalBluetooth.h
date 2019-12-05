//
//  UniversalBluetooth.h
//  UniversalBluetooth
//
//  Created by Luis Laugga on 12/19/16.
//  Copyright © 2016 Luis Laugga. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for UniversalBluetooth.
FOUNDATION_EXPORT double UniversalBluetoothVersionNumber;

//! Project version string for UniversalBluetooth.
FOUNDATION_EXPORT const unsigned char UniversalBluetoothVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <UniversalBluetooth/PublicHeader.h>

@import CoreBluetooth;

@protocol UniversalBluetoothDelegate;

@interface UniversalBluetoothPeripheral: NSObject
{
}

@property (nonatomic, strong) CBPeripheral * peripheral;

@property (strong, nonatomic) CBCharacteristic * rxCharacteristic;
@property (strong, nonatomic) CBCharacteristic * txCharacteristic;

@end

@interface UniversalBluetooth : NSObject <CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    double _filteredRSSI; // Low-pass filter
}

@property (strong, nonatomic) CBMutableCharacteristic * mutableRxCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic * mutableTxCharacteristic;
@property (strong, nonatomic) CBMutableService * service;

@property (nonatomic, strong) CBCentralManager * centralManager;
@property (nonatomic, strong) CBPeripheralManager * peripheralManager;

@property (nonatomic, strong) NSMutableSet<UniversalBluetoothPeripheral *> * peripherals;

@property (nonatomic, weak) id<UniversalBluetoothDelegate> delegate;

- (void)start;
- (void)stop;

- (void)sendObject:(NSDictionary *)object;

@end

@protocol UniversalBluetoothDelegate <NSObject>

- (void)UniversalBluetoothDidConnect:(UniversalBluetooth *)UniversalBluetooth;
- (void)UniversalBluetoothDidDisconnect:(UniversalBluetooth *)UniversalBluetooth;

- (void)UniversalBluetoothDidDisconnect:(UniversalBluetooth *)UniversalBluetooth peripheral:(UniversalBluetoothPeripheral *)peripheral;

- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didUpdateRSSI:(NSNumber *)RSSI;

- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didReceiveObject:(NSDictionary *)object;

@end
