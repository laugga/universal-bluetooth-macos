//
//  UniversalBluetoothPeripheral.h
//  UniversalBluetooth
//
//  Created by Luis Laugga on 12/19/16.
//  Copyright © 2016 Luis Laugga. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@interface UniversalBluetoothPeripheral: NSObject
{
}

@property (nonatomic, strong) CBPeripheral * peripheral;

@property (strong, nonatomic) CBCharacteristic * rxCharacteristic;
@property (strong, nonatomic) CBCharacteristic * txCharacteristic;

@end
