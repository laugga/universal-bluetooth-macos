//
//  UniversalBluetooth.m
//  Universal
//
//  Created by Luis Laugga on 02.11.15.
//  Copyright © 2015 Luis Laugga. All rights reserved.
//

#import "UniversalBluetooth.h"

#define SERVICE_UUID @"8ebdb2f3-7817-45c9-95c5-c5e9031aaa47"
#define TX_CHARACTERISTIC_UUID @"08590F7E-DB05-467E-8757-72F6FAEB13D4"
#define RX_CHARACTERISTIC_UUID @"08590F7E-DB05-467E-8757-72F6FAEB13D5"

@interface UniversalBluetooth ()

- (void)startAdvertising;
- (void)stopAdvertising;

- (void)startScanning;
- (void)stopScanning;

@end

@implementation UniversalBluetooth

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _filteredRSSI = -100.0;
        
        // Advertise
        CBPeripheralManager * peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        self.peripheralManager = peripheralManager;
        
        // Scan for all available CoreBluetooth LE devices
        //CBCentralManager * centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        //self.centralManager = centralManager;
    }
    
    return self;
}

- (void)startAdvertising
{
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:SERVICE_UUID]], CBAdvertisementDataLocalNameKey:@"universal-bluetooth" }];
}

- (void)stopAdvertising
{
    [self.peripheralManager stopAdvertising];
}

- (void)startScanning
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
}

- (void)stopScanning
{
    [self.centralManager stopScan];
}

- (void)start
{
    // Scan and advertise simultaneously
    [self startScanning];
    [self startAdvertising];
}

- (void)stop
{
    [self stopScanning];
    [self stopAdvertising];
}

#pragma mark -
#pragma mark Read / Write

- (void)sendString:(NSString *)string
{
    NSLog(@"sendString: %@", string);
    
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length)
    {
        [self sendData:data];
    }
}

- (void)sendData:(NSData *)data
{
    NSLog(@"sendData: %@", data);
    
    if (self.peripheral && self.rxCharacteristic)
    {
        // Act as central
        // IMPORTANT use the RX characteristic of peripheral
        [self.peripheral writeValue:data forCharacteristic:self.rxCharacteristic type:CBCharacteristicWriteWithResponse];
        
    }
    else if (self.mutableTxCharacteristic)
    {
        // Act as peripheral
        [self.peripheralManager updateValue:data forCharacteristic:self.mutableTxCharacteristic onSubscribedCentrals:nil];
    }
}

- (void)didReceiveString:(NSString *)string
{
    NSLog(@"didReceiveString: %@", string);
    
    if ([self.delegate respondsToSelector:@selector(UniversalBluetooth:didReceiveString:)])
    {
        [self.delegate UniversalBluetooth:self didReceiveString:string];
    }
}

- (void)didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData: %@", data);
    
    NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string)
    {
        [self didReceiveString:string];
    }
}

- (void)didConnect
{
    if ([self.delegate respondsToSelector:@selector(UniversalBluetoothDidConnect:)])
    {
        [self.delegate UniversalBluetoothDidConnect:self];
    }
}

- (void)didDisconnect
{
    if ([self.delegate respondsToSelector:@selector(UniversalBluetoothDidDisconnect:)])
    {
        [self.delegate UniversalBluetoothDidDisconnect:self];
    }
    
    [self startScanning];
}

#pragma mark -
#pragma mark Signal, Distance

- (void)updateFilteredRSSI:(double)RSSI
{
    static double const kLowPassFilterFactor = 0.3;
    _filteredRSSI = (RSSI * kLowPassFilterFactor) + (_filteredRSSI * (1.0 - kLowPassFilterFactor));
}

#pragma mark -
#pragma mark CBPeripheralManagerDelegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    NSLog(@"peripheralManagerDidUpdateState: %@", peripheralManager);
    
    // Determine the state of the peripheral
    if ([peripheralManager state] == CBCentralManagerStatePoweredOff)
    {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([peripheralManager state] == CBCentralManagerStateUnauthorized)
    {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([peripheralManager state] == CBCentralManagerStateUnknown)
    {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([peripheralManager state] == CBCentralManagerStateUnsupported)
    {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
    else if ([peripheralManager state] == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
        
        // TX CBMutableCharacteristic
        CBMutableCharacteristic * mutableTxCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify|CBCharacteristicPropertyWrite|CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsWriteable|CBAttributePermissionsReadable];
        
        // RX CBMutableCharacteristic
        CBMutableCharacteristic * mutableRxCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify|CBCharacteristicPropertyWrite|CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsWriteable|CBAttributePermissionsReadable];
        
        // CBMutableService
        self.service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID] primary:YES];
    
        // Add the characteristic to the service
        self.service.characteristics = @[mutableTxCharacteristic, mutableRxCharacteristic];
        self.mutableTxCharacteristic = mutableTxCharacteristic;
        self.mutableRxCharacteristic = mutableRxCharacteristic;
        
        // And service to the peripheral manager
        [self.peripheralManager addService:self.service];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising:error: %@", error);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"peripheralManager:central: %@ didSubscribeToCharacteristic:", central);
    
    if (self.rxCharacteristic == characteristic)
    {
        self.rxCharacteristic = characteristic;
    }
    else if (self.txCharacteristic == characteristic)
    {
        self.txCharacteristic = characteristic;
    }
    
    // TODO Improve
    [self didConnect];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"peripheralManager:central:didUnsubscribeFromCharacteristic:");
    
    if (self.rxCharacteristic == characteristic)
    {
        self.rxCharacteristic = nil;
    }
    else if (self.txCharacteristic == characteristic)
    {
        self.txCharacteristic = nil;
    }
    
    // TODO Improve
    [self didDisconnect];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"peripheralManager: %@ didReceiveWriteRequests: %@", peripheralManager, requests);
    
    for (CBATTRequest * request in requests)
    {
        CBCharacteristic * characteristic = request.characteristic;
        
        NSData * data = request.value;
        if (data.length)
        {
            
            if (characteristic == self.mutableRxCharacteristic)
            {
                [self didReceiveData:data];
            }
            
            // Reply with success
            [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        }
    }
}

#pragma mark -
#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState: %@", central);
    
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff)
    {
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }
    else if ([central state] == CBCentralManagerStateUnauthorized)
    {
        NSLog(@"CoreBluetooth BLE state is unauthorized");
    }
    else if ([central state] == CBCentralManagerStateUnknown)
    {
        NSLog(@"CoreBluetooth BLE state is unknown");
    }
    else if ([central state] == CBCentralManagerStateUnsupported)
    {
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
    else if ([central state] == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"centralManager:didConnectPeripheral: %@", peripheral);
    
    [self stopScanning];
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"centralManager:didFailToConnectPeripheral:error: %@", error);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"centralManager:didDiscoverPeripheral: %@ advertisementData: %@ RSSI: %@", peripheral, advertisementData, RSSI);
    
    if (RSSI.integerValue > -80)
    { // TODO low pass filter

        NSString * localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        if ([localName length] > 0)
        {
            NSLog(@"Found the device: %@ RSSI: %@", localName, RSSI);
            [self stopScanning]; // TODO improve
            self.peripheral = peripheral;
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"centralManager:didDisconnectPeripheral:");
    
    [self didDisconnect];
}

#pragma mark -
#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"peripheral:didDiscoverServices: %@", error);
    
    for (CBService *service in peripheral.services)
    {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID], [CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"peripheral:didDiscoverCharacteristicsForService: %@ error: %@", service, error);
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic * characteristic in service.characteristics)
    {
        // And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID]])
        {
            // ACT AS CENTRAL
            // Peripheral's RX is Central's TX
            self.rxCharacteristic = characteristic;
            
            if (self.txCharacteristic)
            {
                [self didConnect];
            }
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID]])
        {
            self.txCharacteristic = characteristic;
            
            // ACT AS CENTRAL
            // Relative to PERIPHERAL - Subscribe to TX - If it is, subscribe to it
            // Peripheral's TX is Central's RX
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            if (self.rxCharacteristic)
            {
                [self didConnect];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"peripheral: %@ didUpdateValueForCharacteristic: %@ error: %@", peripheral, characteristic, error);
    
    NSData * data = characteristic.value;
    if (data.length)
    {
        [self didReceiveData:data];
    }
    
    // Update RSSI
    [peripheral readRSSI];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"peripheral:didUpdateNotificationStateForCharacteristic: %@ error: %@", characteristic, error);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"peripheral: %@ didWriteValueForCharacteristic: %@ error: %@", peripheral, characteristic, error);
    
    // TODO retry write if it fails
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"peripheralDidUpdateRSSI: %@ error: %@", peripheral, error);
    
    if (peripheral.RSSI)
    {
        [self updateFilteredRSSI:peripheral.RSSI.doubleValue];
        
        if ([self.delegate respondsToSelector:@selector(UniversalBluetooth:didUpdateRSSI:)])
        {
            [self.delegate UniversalBluetooth:self didUpdateRSSI:@(_filteredRSSI)];
        }
    }
}

@end
