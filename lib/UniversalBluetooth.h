//
//  UniversalBluetooth.h
//  UniversalBluetooth
//
//  Created by Luis Laugga on 12/19/16.
//  Copyright © 2016 Luis Laugga. All rights reserved.
//

//! Project version number for UniversalBluetooth.
FOUNDATION_EXPORT double UniversalBluetoothVersionNumber;

//! Project version string for UniversalBluetooth.
FOUNDATION_EXPORT const unsigned char UniversalBluetoothVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <UniversalBluetooth/PublicHeader.h>

@import CoreBluetooth;

@protocol UniversalBluetoothDelegate;

@interface UniversalBluetooth : NSObject <CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>
{
    double _filteredRSSI; // Low-pass filter
}

@property (strong, nonatomic) CBCharacteristic * rxCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic * mutableRxCharacteristic;
@property (strong, nonatomic) CBCharacteristic * txCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic * mutableTxCharacteristic;
@property (strong, nonatomic) CBMutableService * service;

@property (nonatomic, strong) CBCentralManager * centralManager;
@property (nonatomic, strong) CBPeripheralManager * peripheralManager;

@property (nonatomic, strong) CBPeripheral * peripheral;

@property (nonatomic, weak) id<UniversalBluetoothDelegate> delegate;

- (void)startAdvertising;
- (void)stopAdvertising;

- (void)startScanning;
- (void)stopScanning;

- (void)sendObject:(NSDictionary *)object;

@end

@protocol UniversalBluetoothDelegate <NSObject>

- (void)UniversalBluetoothDidConnect:(UniversalBluetooth *)UniversalBluetooth;
- (void)UniversalBluetoothDidDisconnect:(UniversalBluetooth *)UniversalBluetooth;

- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didUpdateRSSI:(NSNumber *)RSSI;

- (void)UniversalBluetooth:(UniversalBluetooth *)UniversalBluetooth didReceiveObject:(NSDictionary *)object;

@end
