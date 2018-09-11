//
//  ScribaStylus2Manager.m
//  Brushes
//
//  Created by Pawel Sikora on 15/05/15.
//  Copyright (c) 2015 Taptrix, Inc. All rights reserved.
//

#import "ScribaStylusManager.h"
#import "CharacteristicReader.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScribaBrushHelper.h"
#import "UIViewController+Utils.h"
#import "ScribaActionNameView.h"


#define kScribaDeviceIdentity @"scribaDeviceIdentity"
#define kScribaErrorDomain @"ScribaErrorDomain"
#define numberOfLastValuesToUse 3
#define numberOfLastValuesToUseForExtreams 10

#define numberOfLastValuesToCheckForLock 90
#define lockAccurencyPercentage 0.05 //5%

#define numberOfLastValuesToUseForExtreams 10

static NSString * const smartLockOnUserDefaultsKey = @"isSmartLockOn";

static NSString * const bgmServiceUUIDString = @"00001808-0000-1000-8000-00805F9B34FB";
static NSString * const bgmGlucoseMeasurementCharacteristicUUIDString = @"00002A18-0000-1000-8000-00805F9B34FB";
static NSString * const bgmGlucoseMeasurementContextCharacteristicUUIDString = @"00002A34-0000-1000-8000-00805F9B34FB";
static NSString * const bgmRecordAccessControlPointCharacteristicUUIDString = @"00002A52-0000-1000-8000-00805F9B34FB";

static NSString * const bpmServiceUUIDString = @"00001810-0000-1000-8000-00805F9B34FB";
static NSString * const bpmBloodPressureMeasurementCharacteristicUUIDString = @"00002A35-0000-1000-8000-00805F9B34FB";
static NSString * const bpmIntermediateCuffPressureCharacteristicUUIDString = @"00002A36-0000-1000-8000-00805F9B34FB";

static NSString * const cscServiceUUIDString = @"00001816-0000-1000-8000-00805F9B34FB";
static NSString * const cscMeasurementCharacteristicUUIDString = @"00002A5B-0000-1000-8000-00805F9B34FB";

static NSString * const rscServiceUUIDString = @"00001814-0000-1000-8000-00805F9B34FB";
static NSString * const rscMeasurementCharacteristicUUIDString = @"00002A53-0000-1000-8000-00805F9B34FB";

static NSString * const hrsServiceUUIDString = @"0000180D-0000-1000-8000-00805F9B34FB";
static NSString * const hrsHeartRateCharacteristicUUIDString = @"00002A37-0000-1000-8000-00805F9B34FB";
static NSString * const hrsSensorLocationCharacteristicUUIDString = @"00002A38-0000-1000-8000-00805F9B34FB";


static NSString * const buzzer_ServiceUUIDString = @"00001530-1212-EFDE-1523-785FEABCD123";
static NSString * const buzzerCharacteristicUUIDString = @"00001531-1212-EFDE-1523-785FEABCD123";


static NSString * const htsServiceUUIDString = @"00001809-0000-1000-8000-00805F9B34FB";
static NSString * const htsMeasurementCharacteristicUUIDString = @"00002A1C-0000-1000-8000-00805F9B34FB";

static NSString * const proximityImmediateAlertServiceUUIDString = @"00001802-0000-1000-8000-00805F9B34FB";
static NSString * const proximityLinkLossServiceUUIDString = @"00001803-0000-1000-8000-00805F9B34FB";
static NSString * const proximityAlertLevelCharacteristicUUIDString = @"00002A06-0000-1000-8000-00805F9B34FB";

static NSString * const batteryServiceUUIDString = @"0000180F-0000-1000-8000-00805F9B34FB";
static NSString * const batteryLevelCharacteristicUUIDString = @"00002A19-0000-1000-8000-00805F9B34FB";

static NSString * const uartServiceUUIDString = @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString * const uartTXCharacteristicUUIDString = @"6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
static NSString * const uartRXCharacteristicUUIDString = @"6E400002-B5A3-F393-E0A9-E50E24DCCA9E";




@interface ScribaStylusManager ()

@property (nonatomic, strong) CBCentralManager *bluetoothManager;
@property (nonatomic, assign) NSInteger currentSqueezeZone;

//@property (nonatomic, assign) NSTimeInterval singleClickSpeed; //0.22 sec by default
@property (nonatomic, assign) NSTimeInterval doubleClickSpeed; //0.3 sec by default
@property (nonatomic, assign) NSTimeInterval thirdClickSpeed; //0.6 sec by Default

@property (nonatomic, assign) NSTimeInterval firstClickDuration;
@property (nonatomic, assign) NSTimeInterval doubleClickDuration;
@property (nonatomic, assign) NSTimeInterval tripleClickDuration;

@property (nonatomic, strong) NSMutableArray *devices;
@property (nonatomic, strong) NSDictionary *devicesStatusDict;

//off by default, repopen only full single/double/tripple click if on, reports all partial events when off
//@property (nonatomic, assign) BOOL clickFiltherEnabled;
@property (nonatomic, assign) NSInteger numberOfSqueezeZones; // disabled (= NSNotFound) by default
@property (nonatomic, assign) float bottomRangeMargin; //0.15 by default
@property (nonatomic, assign) float topRangeMargin; //0.1 by default
@property (nonatomic) WDBlueToothState blueToothState;



@end

@implementation ScribaStylusManager
{
    CompletionBlock completionBlock;
    
    BOOL scanning;
    BOOL shouldStartScanningAfterBlouetoothOn;
    BOOL startToSingleClick;
    NSDate *startToSingleClickDate;
//    NSTimer *pinReadTimer;
//    NSTimer *batteryReadTimer;

    //moinitor device either broadcasting or dead (go slient)
    NSTimer *scribaDevicesMonitorTimer;
    
    BOOL firstReadingTaken;
    
    float smoothenedMinimumValueRegistered;
    float smoothenedMaximumValueRegistered;
    
    NSMutableArray *lastPressureValuesForExtreams;
    NSMutableArray *lastPressureValues;
    NSMutableArray *lastClickValuesWithTime;
    
    //battery services    
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
    
    //hr services
    CBUUID *HR_Service_UUID; //will be used for pressure
    CBUUID *HR_Measurement_Characteristic_UUID;
    CBUUID *HR_Location_Characteristic_UUID;
    
    //buzz services
    CBUUID *Legacy_DFU_ServiceUUID;
    CBUUID *Buzzer_Characteristic_UUID;
    
    CBCharacteristic *buzzChacteristic;
    
    NSMutableArray *lastPressureValuesForLock;
    
    BOOL smartLockEnabled;
    BOOL smartLockedPressure;
    float smartLockedPressureValue;
    float pressureMaxValue;
    float pressureMinValue;
    NSInteger clickCounter;
    BOOL singleClicked;
    
    //changing device
    ScribaStylusDevice *temporaryDisconnectedDevice;
    
    NSDate *previousClickTime;
    BOOL wasPreviousReadindFullDepression;
    BOOL alreadyReportedSingleClick;
    BOOL alreadyReportedDoubleClick;
    BOOL fullDepressionInvalid; //whether full depression invalid
    BOOL hapticBuzzEnabled;
    
    BOOL restoreLastDeviceConnectionWaitingForUpdate;
    
}

@synthesize blueToothState;
@synthesize isBlueToothEnabled;

+ (ScribaStylusManager *) sharedManager
{
#if TARGET_IPHONE_SIMULATOR
    return nil;
#endif
    
    static ScribaStylusManager *_stylusManager = nil;
    
    if (!_stylusManager) {
        _stylusManager = [[ScribaStylusManager alloc] init];
    }
    
    return _stylusManager;
}


- (void)dealloc
{
    [self removeObserver];
    [self invalidDevicesMonitorTimer];
}

-(id)init{
    self = [super init];
    if(self){
        
        [self registerObserver];
        
        lastPressureValues = [NSMutableArray new];
        lastPressureValuesForLock = [NSMutableArray new];
        lastPressureValuesForExtreams = [NSMutableArray new];
        lastClickValuesWithTime = [NSMutableArray new];
        
        //        self.singleClickSpeed = 0.15;
        self.doubleClickSpeed = 0.3;
        self.thirdClickSpeed = 0.6;
        //        self.clickFiltherEnabled = NO;
        
        self.firstClickDuration = 0.6;
        self.doubleClickDuration = 0.85;
        self.tripleClickDuration = 1.0;
        
        self.bottomRangeMargin = 0.15;
        self.topRangeMargin = 0.1;
        
        pressureMaxValue = 1.0f;
        pressureMinValue = 0.0f;
        
        //[MBLMetaWearManager sharedManager].minimumRequiredVersion = MBLFirmwareVersion1_0_3;
        self.devices = [NSMutableArray new];
        self.devicesStatusDict = [NSMutableDictionary new];
        
        self.currentDeviceBatteryState = 0.0; //temp
        self.currentDeviceButtonDepression = 0.0; //temp
        
        HR_Service_UUID = [CBUUID UUIDWithString:hrsServiceUUIDString];
        HR_Measurement_Characteristic_UUID = [CBUUID UUIDWithString:hrsHeartRateCharacteristicUUIDString];
        HR_Location_Characteristic_UUID = [CBUUID UUIDWithString:hrsSensorLocationCharacteristicUUIDString];
        
        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
        
        Legacy_DFU_ServiceUUID = [CBUUID UUIDWithString:buzzer_ServiceUUIDString];
        Buzzer_Characteristic_UUID = [CBUUID UUIDWithString:buzzerCharacteristicUUIDString];

        dispatch_queue_t centralQueue = dispatch_queue_create("com.scriba.ScribaSDK", DISPATCH_QUEUE_SERIAL);
        self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue options:@{CBCentralManagerOptionShowPowerAlertKey:[NSNumber numberWithBool:NO]}];
        
        smartLockEnabled = YES;
        
        self.shouldAutoconnectDiscoveredScriba = YES;
        
        hapticBuzzEnabled = NO;
        
        scribaDevicesMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(monitoringDevices) userInfo:nil repeats:YES];
    }
    return self;
}

-(void)resetStylusValues
{
    smoothenedMinimumValueRegistered = 0;
    smoothenedMaximumValueRegistered = 0;
    
    firstReadingTaken = NO;
    
    self.currentDeviceBatteryState = 0;
    self.currentDeviceButtonDepression = 0.0;
}

-(void)startScanning
{
    NSLog(@"Scanning devices...");
    if (self.bluetoothManager.state != CBCentralManagerStatePoweredOn)
    {
        NSLog(@"not powered");
        return;
    }
    
    if(scanning)
    {
        return;
    }
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self->scanning = YES;
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        [self.bluetoothManager scanForPeripheralsWithServices:nil options:options];
    });
    
}

-(void)stopScanning
{
    NSLog(@"stopping scan");
    scanning = NO;
    [self.bluetoothManager stopScan];
}

#pragma mark - devices creation && monitoring

- (ScribaStylusDevice*) stylusDeviceCreateWithPeripheral:(CBPeripheral*)peripheral
{
    ScribaStylusDevice* scribaStylusDevice = [[ScribaStylusDevice alloc] init];
    scribaStylusDevice.peripheral = peripheral;

    return scribaStylusDevice;
}

- (void)monitoringDevices
{
    NSMutableArray *devicesToBeRemoved = [[NSMutableArray alloc] init];
    NSArray *allkeys = [self.devicesStatusDict allKeys];
    
    for (ScribaStylusDevice *device in self.devices)
    {
        if (device.state != ScribaDeviceStateConnected)
        {
            NSString *key = device.peripheral.identifier.UUIDString;
            if([allkeys containsObject:key])
            {
                NSDate *broadcastingDate = self.devicesStatusDict[device.peripheral.identifier.UUIDString];
                
                if (!broadcastingDate)
                {
                    [devicesToBeRemoved addObject:device];
                }
                else
                {
                    NSTimeInterval diff = -[broadcastingDate timeIntervalSinceNow];
//                    NSLog(@"diff %f , and broadcasting time %@",diff,[broadcastingDate description]);
                    if (diff > 1)
                    {
                        //device should be removed since it is dead (not in broadcasting)
                        [devicesToBeRemoved addObject:device];
                    }
                }
            }
        }
    }
    
    for (ScribaStylusDevice *item in devicesToBeRemoved) {
        [self.devices removeObject:item];

        //invoke delegate callback
        if([self.delegate respondsToSelector:@selector(didFoundDevices:)]){
            [self.delegate didFoundDevices:self.devices];
        }
    }
}

- (void)invalidDevicesMonitorTimer{
    [scribaDevicesMonitorTimer invalidate];
    scribaDevicesMonitorTimer = nil;
}

#pragma mark - conneting devices
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if ([[advertisementData objectForKey:CBAdvertisementDataIsConnectable] boolValue])
    {
        NSString *advertisingName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
        
        //Filter for "scriba"
        if(advertisingName && [advertisingName.lowercaseString rangeOfString:@"scriba"].location != NSNotFound){
            
//            discovered scriba: {
//                kCBAdvDataIsConnectable = 1;
//                kCBAdvDataLocalName = "Scriba V2.00";
//                kCBAdvDataServiceUUIDs =     (
//                                              "Heart Rate",
//                                              Battery,
//                                              "Device Information"
//                                              );
//            }, peripheral name D2FA5C60-B5DD-4D9B-9EC1-9BF1157E45A8
            
            //NSLog(@"discovered scriba: %@, peripheral name %@", advertisementData, peripheral.identifier);
            
            // Add the sensor to the list and reload deta set
            ScribaStylusDevice* device = [self stylusDeviceCreateWithPeripheral:peripheral];
            if (![self.devices containsObject:device])
            {
                [self.devices addObject:device];
                
                if(self.shouldAutoconnectDiscoveredScriba)
                {
                    self.shouldAutoconnectDiscoveredScriba = NO;
                    [self tryConnectDevice:device completion:nil];
                }
                
                //call delegate callback whenever devices list changed
                if([self.delegate respondsToSelector:@selector(didFoundDevices:)]){
                    [self.delegate didFoundDevices:self.devices];
                }
            }
//            else
//            {
//                device = [self.devices objectAtIndex:[self.devices indexOfObject:device]];
//            }
            
            NSDate *nowDate = [NSDate dateWithTimeIntervalSinceNow:0];
            [self.devicesStatusDict setValue:nowDate forKey:peripheral.identifier.UUIDString];
            
            
        } else {
            //NSLog(@"Non Scriba device name: %@ / name %@", peripheral.identifier, advertisingName);
        }
    }
    else{
         //NSLog(@"can not connectable wrong device name: %@ ", peripheral.identifier);
    }
}

- (NSMutableArray*)scribaDevicesListcontainPeriphal:(CBPeripheral*)peripheral{

    NSMutableArray *retVal = [[NSMutableArray alloc] initWithArray:self.devices];
    for (int index = 0; index < self.devices.count; index++) {
        ScribaStylusDevice *device = self.devices[index];
        if([[device.peripheral.identifier UUIDString] isEqualToString:[peripheral.identifier UUIDString]]){
            [retVal removeObjectAtIndex:index];
            break;
        }
    }

    return retVal;
}

- (void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    NSLog(@"did retrieve connected peripherials");
}

- (void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    NSLog(@"did retrieve peripherials");
}


-(void)tryConnectDevice:(ScribaStylusDevice*)device completion:(CompletionBlock)finishBlock
{
    if(device.state == ScribaDeviceStateConnected)
    {
        return;
    }
    
    if(!device)
    {
        return;
    }
    
    completionBlock = [finishBlock copy];
    
    // The sensor has been selected, connect to it
    device.peripheral.delegate = self;
    
    [self.bluetoothManager connectPeripheral:device.peripheral options:nil];
    
//    NSInteger delay = 1.8;
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
//        //called after 1.5 seconds to determine if connection is successful or not
//        if (self.connectedDevice == nil || self.connectedDevice != device) {
//
//            [self.bluetoothManager cancelPeripheralConnection:device.peripheral];
//
//            NSError *error = [NSError errorWithDomain:kScribaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not connect to the Scriba device, you have to active it"}];
//
//            if (completionBlock)
//            {
//                completionBlock(error);
//                completionBlock = nil;
//            }
//
//        }
//    });
    
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        self.blueToothState = WDBlueToothLowEnergy;
    }
    else
    {
        self.blueToothState = WDBlueToothOff;
    }

    [self.bluetoothDelegate bluetoothStatusChanged:self.blueToothState];
    
    if (restoreLastDeviceConnectionWaitingForUpdate)
    {
        [self restoreLastDeviceConnection];
        restoreLastDeviceConnectionWaitingForUpdate = false;
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSArray *devices = [self getListOfScribaDevices];
    for (ScribaStylusDevice *device in devices) {
        if ([[device.peripheral identifier] isEqual:peripheral.identifier]) {
            self.connectedDevice = device;
            break;
        }
    }
    
    if (self.connectedDevice == nil) {
        NSLog(@"connected device can not be nil");
        
        ScribaStylusDevice* device = [self stylusDeviceCreateWithPeripheral:peripheral];
        if (![self.devices containsObject:device])
        {
            [self.devices addObject:device];
        }
        
        self.connectedDevice = device;
    }
    else{
        
        if (![self.devices containsObject:self.connectedDevice])
        {
            [self.devices addObject:self.connectedDevice];
        }
    }

    self.connectedDevice.state = ScribaDeviceStateConnected;
    
    //save scriba device UUID string
    [self saveScribaDevice:self.connectedDevice];
    
    //check if more than two devices are connected
    ScribaStylusDevice *disconnectedDevice = nil;
    for (ScribaStylusDevice *device in self.devices) {
        if (device != self.connectedDevice && (device.state == ScribaDeviceStateConnected)) {
            disconnectedDevice = device;
        }
    }
    
    if (disconnectedDevice) {
        
        temporaryDisconnectedDevice = disconnectedDevice;

        //should disconnect this device
        [self disconnectScribaDeviceCompletion:temporaryDisconnectedDevice completion:^(NSError *error) {
            if (error) {
                NSLog(@"Error on disconnect the device %@",error.localizedDescription);
            }
        }];
    }
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{

        if ([self.delegate respondsToSelector:@selector(didConnectedDevice: manager:)]) {
            
            if (self.alertUserWhenScribaConnectionChanged)
            {
                [[ScribaActionNameView sharedInstance] setConnectedDeviceName:peripheral.name inViewController:[UIViewController currentViewController]];
            }

            [self.delegate didConnectedDevice:self.connectedDevice manager:self.bluetoothManager];
        }
        
        peripheral.delegate = self;
        [peripheral discoverServices:nil];
        
        if (self->completionBlock)
        {
            self->completionBlock(nil);
            self->completionBlock = nil;
        }
        
    });
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.connectedDevice = nil;

    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(didDisconnectDevice:)]) {
            
            if (self.alertUserWhenScribaConnectionChanged)
            {
                [[ScribaActionNameView sharedInstance] setDisconnectedDeviceName:peripheral.name
                                                                inViewController:[UIViewController currentViewController]];
            }
            
            [self.delegate didDisconnectDevice:self.connectedDevice];
        }
        
        if (self->completionBlock) {
            self->completionBlock(error);
            self->completionBlock = nil;
        }
        
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    temporaryDisconnectedDevice.state = ScribaDeviceStateDisconnected;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([self.delegate respondsToSelector:@selector(didDisconnectDevice:)])
        {
            
            if (self.alertUserWhenScribaConnectionChanged)
            {
                [[ScribaActionNameView sharedInstance] setDisconnectedDeviceName:peripheral.name
                                                                inViewController:[UIViewController currentViewController]];
            }
            
            [self.delegate didDisconnectDevice:self.connectedDevice];
        }
        
        if(!self->temporaryDisconnectedDevice){
            [self resetStylusValues];
        }
        
        if (self->completionBlock)
        {
            self->completionBlock(error);
            self->completionBlock = nil;
        }
        
    });
    
}


#pragma mark -
#pragma mark Peripheral delegate methods

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        [self.bluetoothManager cancelPeripheralConnection:self.connectedDevice.peripheral];
        return;
    }
    
    for (CBService *service in peripheral.services)
    {
        
        if ([service.UUID isEqual:HR_Service_UUID])
        {
            NSLog(@"HR service found");
            [peripheral discoverCharacteristics:nil forService:service];
            
        }
        else if ([service.UUID isEqual:batteryServiceUUID])
        {
            NSLog(@"Battery service found");
            [peripheral discoverCharacteristics:@[batteryLevelCharacteristicUUID] forService:service];
        }
        else if ([service.UUID isEqual:Legacy_DFU_ServiceUUID])
        {
            NSLog(@"Legacy DFU service Found");
            [peripheral discoverCharacteristics:@[Buzzer_Characteristic_UUID] forService:service];
        }
        else
        {
            NSLog(@"Device Information service %@",service.UUID.UUIDString);
        }
    }
    
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:HR_Service_UUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:HR_Measurement_Characteristic_UUID])
            {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic ];
            }
            else if ([characteristic.UUID isEqual:HR_Location_Characteristic_UUID])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
        
    }
    else if ([service.UUID isEqual:batteryServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID])
            {
                // Read the current battery value
                [peripheral readValueForCharacteristic:characteristic];
                break;
            }
        }
    }
    else if([service.UUID isEqual:Legacy_DFU_ServiceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:Buzzer_Characteristic_UUID])
            {
                buzzChacteristic = characteristic;
                break;
            }
        }
    }
    else
    {
//        NSLog(@"other service UUID = %@",service.UUID.UUIDString);
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        // Decode the characteristic data
        NSData *data = characteristic.value;
        uint8_t *array = (uint8_t*) data.bytes;
        
        if ([characteristic.UUID isEqual:self->batteryLevelCharacteristicUUID])
        {
            UInt8 batteryLevel = [CharacteristicReader readUInt8Value:&array];
            
            self.currentDeviceBatteryState = 0.01 * batteryLevel;
            
            if([self.delegate respondsToSelector:@selector(didUpdatedBatteryStateForDevice:batteryState:)] ) {
                [self.delegate didUpdatedBatteryStateForDevice:self.connectedDevice batteryState:self.currentDeviceBatteryState];
            }
            
            if (!self.connectedDevice.enabledBatteryNotification){
                // If battery level notifications are available, enable them
                if (([characteristic properties] & CBCharacteristicPropertyNotify) > 0)
                {
                    self.connectedDevice.enabledBatteryNotification = YES; //mark that this is alredy enabled
                    // Enable notification on data characteristic
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
        
        if ([characteristic.UUID isEqual:self->HR_Measurement_Characteristic_UUID]) {
            
            float depression = [self getCalibratedDepression:[self decodeHRValue:characteristic.value]];
            [self recordDepression:depression];
        }
        else if ([characteristic.UUID isEqual:self->HR_Location_Characteristic_UUID]) {
            
            NSLog(@"HR location: %@", [self decodeHRLocation:characteristic.value]);
        }
//        else if([characteristic.UUID isEqual:HR_Buzzer_Characteristic_UUID]){
//            
//            NSLog(@"Buzzer %@",characteristic.value);
//        }
        
    });
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Writing value error: %@", [error localizedDescription]);
}

-(float)getCalibratedDepression:(int)reading
{
    reading = [self registerReading:reading];
    
    float depression;
    if([self minimumReading] != [self maximumReading]){
        depression = 1.0 - 1.0*(reading - [self minimumReading])/([self maximumReading] - [self minimumReading]);
    } else {
        depression = 0.0;
    }
    
    return depression;
    
}

-(float)registerReading:(int)reading
{
    [lastPressureValuesForExtreams addObject:@(reading)];
    while(lastPressureValuesForExtreams.count > numberOfLastValuesToUseForExtreams)
    {
        [lastPressureValuesForExtreams removeObjectAtIndex:0];
    }
    
    float roundedReading = 0;
    for(NSNumber *value in lastPressureValuesForExtreams)
    {
        roundedReading += [value floatValue];
    }
    roundedReading = roundedReading/lastPressureValuesForExtreams.count;
    
    if(!firstReadingTaken)
    {
        firstReadingTaken = YES;
        smoothenedMaximumValueRegistered = roundedReading;
        smoothenedMinimumValueRegistered = roundedReading;
    } else if(roundedReading > smoothenedMaximumValueRegistered)
    {
        smoothenedMaximumValueRegistered = roundedReading;
    } else if (roundedReading < smoothenedMinimumValueRegistered)
    {
        smoothenedMinimumValueRegistered = roundedReading;
    }
    
    
    if(reading > [self maximumReading])
    {
        return [self maximumReading];
    }
    else if (reading < [self minimumReading])
    {
        return [self minimumReading];
    }
    else
    {
        return reading;
    }
}

-(void)checkClicksWithValue:(float)value
{
    if (value < 0.5 && clickCounter == 0) {
        //clicks is supposed to be starting from value less than 0.5
        startToSingleClick = YES;
        startToSingleClickDate = [NSDate dateWithTimeIntervalSinceNow:0];

    }
    //NSLog(@" check clicks clicks %ld, %f ",clickCounter,value);
    //NSLog(@"value %f  , clickCounter = %l",value,clickCounter);

    BOOL isFullDepresion = value >= 0.97;
    if(!isFullDepresion && wasPreviousReadindFullDepression)
    {
        if(previousClickTime != nil && ([previousClickTime timeIntervalSinceNow] >= -self.thirdClickSpeed))
        {
            clickCounter++;
            
            if (clickCounter == 2) {
                alreadyReportedSingleClick = NO;
                alreadyReportedDoubleClick = YES;
            }
            else if(clickCounter == 3){
                alreadyReportedSingleClick = NO;
                alreadyReportedDoubleClick = NO;
                clickCounter = 0;
                
                NSTimeInterval diffs = -[startToSingleClickDate timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceNow:0]];
                //NSLog(@"diffs %f , tripleClickDuration %f",diffs,self.tripleClickDuration);
                if([self.delegate respondsToSelector:@selector(didTrippleClickWithDevice:)] && startToSingleClick && diffs <= self.tripleClickDuration)
                {
                    NSLog(@" triple clicks ");
                    [self.delegate didTrippleClickWithDevice:self.connectedDevice];
                }
                
                startToSingleClick = NO;
            }
        }
        else
        {
            clickCounter = 1;
            alreadyReportedSingleClick = YES;
//            NSTimeInterval diffs = -[self->startToSingleClickDate timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceNow:0]];
            //NSLog(@"testing single clicks %f",diffs);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.doubleClickSpeed * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                if(self->alreadyReportedSingleClick)
                {
                    self->alreadyReportedSingleClick = NO;
                    self->alreadyReportedDoubleClick = NO;
                    self->clickCounter = 0;

                    NSTimeInterval diffs = -[self->startToSingleClickDate timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceNow:0]];
                    NSLog(@"diffs %f , singleClickDuration %f",diffs,self.firstClickDuration);
                    if ([self.delegate respondsToSelector:@selector(didSingleClickWithDevice:)] && self->startToSingleClick  && diffs <= self.firstClickDuration)
                    {
                        NSLog(@" single clicks");
                        [self.delegate didSingleClickWithDevice:self.connectedDevice];
                    }
                    
                    self->startToSingleClick = NO;
                }
            });
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.thirdClickSpeed * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                if (self->alreadyReportedDoubleClick)
                {
                    self->alreadyReportedSingleClick = NO;
                    self->alreadyReportedDoubleClick = NO;
                    self->clickCounter = 0;
                    
                    NSTimeInterval diffs = -[self->startToSingleClickDate timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceNow:0]];
                    NSLog(@"diffs %f , doubleClickDuration %f",diffs,self.doubleClickDuration);
                    if ([self.delegate respondsToSelector:@selector(didDoubleClickWithDevice:)] && self->startToSingleClick && diffs <= self.doubleClickDuration)
                    {
                        NSLog(@" double clicks ");
                        [self.delegate didDoubleClickWithDevice:self.connectedDevice];
                    }
                    
                    self->startToSingleClick = NO;

                }
            });
        }
        
        previousClickTime = [NSDate date];
        wasPreviousReadindFullDepression = NO;
    }
    else{
        
        if(isFullDepresion)
        {
            wasPreviousReadindFullDepression = !fullDepressionInvalid;
            
            //if full press takes more than double click speed time, set the fullDepression to YES.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.doubleClickSpeed * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self->clickCounter == 0)
                {
                    self->fullDepressionInvalid = YES;
                }
            });
        }
        else
        {
            wasPreviousReadindFullDepression = NO;
            fullDepressionInvalid = NO;
        }
    }
    
}


-(float)minimumReading{
    return smoothenedMinimumValueRegistered;
}

-(float)maximumReading{
    return smoothenedMaximumValueRegistered;
}

-(void)recordDepression:(float)depression
{
    self.currentDeviceButtonDepressionStrength = depression;
    
    float finalValue;
    if(depression <= self.bottomRangeMargin)
    {
        finalValue = 0.0;
    }
    else if (depression >= 1.0-self.topRangeMargin)
    {
        finalValue = 1.0;
    }
    else
    {
        finalValue = (depression - self.bottomRangeMargin)/(1.0 - self.bottomRangeMargin - self.topRangeMargin);
    }
    
    [lastPressureValues addObject:@(finalValue)];
    while(lastPressureValues.count > numberOfLastValuesToUse)
    {
        [lastPressureValues removeObjectAtIndex:0];
    }
    
    float sum = 0;
    for(NSNumber *value in lastPressureValues)
    {
        sum += value.floatValue;
    }
    
    __block float finalSmoothedValue = sum/lastPressureValues.count;
    
     [self checkClicksWithValue:finalSmoothedValue];
    
    if (finalSmoothedValue != self.currentDeviceButtonDepression)
    {
        self.currentDeviceButtonDepression = finalSmoothedValue;
        //NSLog(@"Scriba Depression %f",finalSmoothedValue);
        if([self.delegate respondsToSelector:@selector(didChangedDepressionForDevice:depression:)])
        {
            [self.delegate didChangedDepressionForDevice:self.connectedDevice depression:finalSmoothedValue];
        }
        
        [self reportSqueezeZoneDepression:finalSmoothedValue];

    }
    
    //lock checks
    if(!smartLockEnabled)
    {
        self.currentDeviceButtonDepression = [self calculatePressureValue:finalValue];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDSizeChangedNotification object:@([ScribaBrushHelper sizeForPressureInPixel:self.currentDeviceButtonDepression])];
        
        return;
    }
    
    if(finalValue < 1.0 && finalValue > 0.0)
    {
        if(!smartLockedPressure){
            
//            NSLog(@"final value %f",finalValue);
            
            [lastPressureValuesForLock addObject:@(finalValue)];
            while (lastPressureValuesForLock.count > numberOfLastValuesToCheckForLock) {
                [lastPressureValuesForLock removeObjectAtIndex:0];
            }
            
            if (lastPressureValuesForLock.count == numberOfLastValuesToCheckForLock) {
                
                //average form last 90 values
                float sum = 0;
                for(NSNumber *value in lastPressureValuesForLock){
                    sum += value.floatValue;
                }
                
                float average = sum/lastPressureValuesForLock.count;
                //check if any of the values exceeds the average by more then specyfied %
                
                BOOL shouldLock = YES;
                for(NSNumber *value in lastPressureValuesForLock){
                    if(fabs(value.floatValue - average) > lockAccurencyPercentage){
                        shouldLock = NO;
                        break;
                    }
                }
                
                if(shouldLock)
                {
                    //locking!
                    smartLockedPressure = YES;
                    average = [self wdClamp:average];
                    smartLockedPressureValue = average;
                    
                    self.currentDeviceButtonDepression = smartLockedPressureValue;
                    
                    BOOL isLockEnabled = [ScribaStylusManager sharedManager].isSmartLockEnabled;
                    if (isLockEnabled)
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:WDLockChangedNotification object:@(smartLockedPressure)];
                    }
                }
                else
                {
                    self.currentDeviceButtonDepression = finalSmoothedValue;
                }
                
            } else
            {
                self.currentDeviceButtonDepression = finalSmoothedValue; //don't have enough values yet to estimate the lock;
            }
        }
        else {
            //keep locked
            self.currentDeviceButtonDepression = smartLockedPressureValue;
        }
        
        //NSLog(@"depression: %f %% (base: %f %%)" , self.currentDeviceButtonDepression*100.0, baseValue*100.0);
    } else if (finalValue >= 0.99) { //full depression, removing the lock
        [lastPressureValuesForLock removeAllObjects];
        smartLockedPressure = NO;
        self.currentDeviceButtonDepression = finalSmoothedValue;
        
        BOOL isLockEnabled = [ScribaStylusManager sharedManager].isSmartLockEnabled;
        if (isLockEnabled) {
            smartLockedPressureValue = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:WDLockChangedNotification object:@(smartLockedPressure)];
        }
    } else { // 0.0 - not checking for lock in that position, just keeping last state
        
        if(!smartLockedPressure){
            self.currentDeviceButtonDepression = finalSmoothedValue;
        } else{
            self.currentDeviceButtonDepression = smartLockedPressureValue;
        }
    }
    
    if (!smartLockedPressure) {
        self.currentDeviceButtonDepression = [self calculatePressureValue:finalValue];
        
//        self.currentDeviceButtonDepression = [self calculatePressureValue:finalSmoothedValue];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDSizeChangedNotification object:@([ScribaBrushHelper sizeForPressureInPixel:self.currentDeviceButtonDepression])];
    
}

- (float)wdClamp:(float)finalSmoothValue{
    
    return finalSmoothValue * (pressureMaxValue - pressureMinValue) + pressureMinValue;
    
}

- (float)calculatePressureValue:(float)finalSmoothedValue{
    
    return pressureMinValue + (pressureMaxValue - pressureMinValue) * finalSmoothedValue;
}

//Zone 0 - This is the default resting value of Scriba without applied pressure.  This zone also allows a degree of tolerance for accidental squeezes.
//Zone 1 - A light pressure, this ‘third’ corresponds to depression values of 0.1 to 0.37
//Zone 2 - Medium applied pressure, mid zone, corresponds to depression values of 0.37 to 0.63
//Zone 3 - Heavier pressure, this ‘third’ corresponds to depression values of 0.63 to 1
//Zone 4 - Full depress. This zone also allows a degree of tolerance for incomplete full squeezes.
-(void)reportSqueezeZoneDepression:(float)depression{
    
//    if (clickCounter > 0) {
//        return;
//    }
    
    NSInteger squeezeZone;
    if(depression >= 0.0 && depression < 0.1){
        squeezeZone = 0;
    }
    else if(depression >= 0.1 && depression < 0.39){
        squeezeZone = 1;
    }
    else if(depression >= 0.39 && depression < 0.67) {
        squeezeZone = 2;
    }
    else if(depression >= 0.67 && depression < 0.95){
        squeezeZone = 3;
    }
    else{
        squeezeZone = 4;
    }
    
    if(self.currentSqueezeZone != squeezeZone){
        self.currentSqueezeZone = squeezeZone;
        if([self.delegate respondsToSelector:@selector(didChangedSqueezeZoneForDevice:squeezeZone:)]){
            [self.delegate didChangedSqueezeZoneForDevice:self.connectedDevice squeezeZone:squeezeZone];
        }
    }

    //    When the squeeze transitions between Zone 1 and Zone 2 (in both directions)
    //    When the squeeze transitions between Zone 2 and Zone 3 (in both directions)
    //only make buzz if enabled
    if (hapticBuzzEnabled) {
        if ((self.currentSqueezeZone == 1 && squeezeZone == 2) || (self.currentSqueezeZone == 2 && squeezeZone == 1)) {
            [self buzz:nil];
        }
        else if((self.currentSqueezeZone == 2 && squeezeZone == 3) || (self.currentSqueezeZone ==3 && squeezeZone == 2)){
            [self buzz:nil];
        }
    }
    
}


-(int) decodeHRValue:(NSData *)data
{
    const uint8_t *value = [data bytes];
    
    int bpmValue = 0;
    if ((value[0] & 0x01) == 0) {
        bpmValue = value[1];
    }
    else {
        bpmValue = CFSwapInt16LittleToHost(*(uint16_t *)(&value[1]));
    }
    
    return bpmValue;
}

-(NSString *) decodeHRLocation:(NSData *)data
{
    const uint8_t *location = [data bytes];
    NSString *hrmLocation;
    switch (location[0]) {
        case 0:
            hrmLocation = @"Other";
            break;
        case 1:
            hrmLocation = @"Chest";
            break;
        case 2:
            hrmLocation = @"Wrist";
            break;
        case 3:
            hrmLocation = @"Finger";
            break;
        case 4:
            hrmLocation = @"Hand";
            break;
        case 5:
            hrmLocation = @"Ear Lobe";
            break;
        case 6:
            hrmLocation = @"Foot";
            break;
        default:
            hrmLocation = @"Invalid";
            break;
    }
    //NSLog(@"HRM location is %@",hrmLocation);
    return hrmLocation;
}

-(void)disconnectScribaDeviceCompletion:(ScribaStylusDevice*)device completion:(CompletionBlock)finishBlock{
    
    if (device && device.state == ScribaDeviceStateConnected)
    {
        completionBlock = [finishBlock copy];
        temporaryDisconnectedDevice = device;
        [self saveScribaDevice:device];
        
        [self.bluetoothManager cancelPeripheralConnection:device.peripheral];
        
    }
    else
    {
        NSError *error = [NSError errorWithDomain:kScribaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Could not disconnect current device, due to current Scriba device either disconnected already or not available!"}];
        
        finishBlock(error);
    }
}

-(void)disconnectCurrentDeviceCompletion:(CompletionBlock)finishBlock
{
    [self disconnectScribaDeviceCompletion:self.connectedDevice completion:finishBlock];
}

- (void)saveScribaDevice:(ScribaStylusDevice*)device
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:device];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:kScribaDeviceIdentity];
    [defaults synchronize];
}

- (ScribaStylusDevice*)retrieveLastScribaDevice
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:kScribaDeviceIdentity];
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(void)restoreLastDeviceConnection{
    
//    restoreLastDeviceConnectionWaitingForUpdate = true;
    
    if (self.blueToothState == WDBlueToothOff) {
        return;
    }

    if (!temporaryDisconnectedDevice) {

        ScribaStylusDevice *scribaDevice = [self retrieveLastScribaDevice];
        if (scribaDevice)
        {
            NSArray *peripherals = [self.bluetoothManager retrievePeripheralsWithIdentifiers:@[[scribaDevice getScribaDeviceIdentifier]]];
            if ([peripherals count] > 0)
            {
                temporaryDisconnectedDevice = [self stylusDeviceCreateWithPeripheral:peripherals[0]];
                if ([scribaDevice isRecognizedDevice]) {
                    [temporaryDisconnectedDevice setRecognizedDevice:YES];
                }
                
                if (![self.devices containsObject:temporaryDisconnectedDevice])
                {
                    [self.devices addObject:temporaryDisconnectedDevice];
                }
            }
        }
    }
    
    if(!temporaryDisconnectedDevice)
    {
        return;
    }

    NSDate *nowDate = [NSDate dateWithTimeIntervalSinceNow:0];
    
    [self.devicesStatusDict setValue:nowDate forKey:[temporaryDisconnectedDevice getScribaDeviceIdentifier].UUIDString];

    [self tryConnectDevice:temporaryDisconnectedDevice completion:nil];
    
    if([self.delegate respondsToSelector:@selector(didFoundDevices:)]){
        [self.delegate didFoundDevices:self.devices];
    }

}

#pragma mark - oberserver
- (void)registerObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buzz:) name:BuzzNotification object:nil];
}

- (void)removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BuzzNotification object:nil];
}


#pragma mark - privates


- (void)buzz:(NSNotification*)notify
{
    NSInteger buzzNum = [notify.object integerValue];
    
    if (buzzNum < BuzzTypeOnce || buzzNum > BuzzTypeTriple)
    {
        buzzNum = BuzzTypeOnce;
    }

    double delay = 0.2;
    
    for (int count = 0; count < buzzNum; count++)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * count * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self doBuzz];
        });
    }
}

- (void)doBuzz
{
    ///uint8_t val = 04;
//    NSData* valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
//    [self.connectedDevice.peripheral writeValue:valData forCharacteristic:buzzChacteristic type:CBCharacteristicWriteWithResponse];
    
    [self.connectedDevice.peripheral setNotifyValue:YES forCharacteristic:buzzChacteristic];
}


-(NSArray*)getListOfScribaDevices{
    
    return self.devices;
}

- (void)removeScribaDeviceFromList:(ScribaStylusDevice*)device{
    
    if ([self.devices containsObject:device]) {
        [self.devices removeObject:device];
    }
}

#pragma mark - Haptics
- (void)enableHapticsBuzz{
    hapticBuzzEnabled = YES;
}

- (void)disableHapticsBuzz{
    hapticBuzzEnabled = NO;
}

#pragma mark - smart lock
- (void)setBrushSizeInLockedMode:(float)brushSize{
    
    float size = [ScribaBrushHelper pressureFromBrushSize:brushSize];
    smartLockedPressure = YES;
    if (size <= pressureMaxValue && size >= pressureMinValue)
    {
        smartLockedPressureValue = size;
    }
    
}

- (void)removeSmartLock
{
    [lastPressureValuesForLock removeAllObjects];
    smartLockedPressure = NO;
}

- (BOOL)isSmartLockOn
{
    return smartLockedPressure;
}

- (void)setMaximumBrushSize:(float)brushSize
{
    
    pressureMaxValue = [ScribaBrushHelper pressureFromBrushSize:brushSize];
}

- (void)setMinimumBrushSize:(float)brushSize
{
    
    pressureMinValue = [ScribaBrushHelper pressureFromBrushSize:brushSize];
}

- (void)resetMaximumBrushSize
{
    pressureMaxValue = 1.0f;
}

- (void)resetMinimumBrushSize
{
    pressureMinValue = 0.0f;
}

- (BOOL)isScribaDepressed
{
    return self.currentDeviceButtonDepression > 0.1;
}

#pragma mark - smart lock settings

-(BOOL)isSmartLockEnabled
{
    return smartLockEnabled;
}

-(void)enableSmartLock:(BOOL)enableSmartLock
{
    smartLockEnabled = enableSmartLock;
}


#pragma mark - Bluetooth related
- (BOOL) isBlueToothEnabled
{
    //centralManagerDidUpdateState will update the status of Bluetooth
    //however this method might be called before the centralManagerDidUpdateState() method called
    //so it needs to add a around 300 millisecond gap before returning the status
    return self.blueToothState != WDBlueToothOff;
}

- (void) setBlueToothState:(WDBlueToothState)inBlueToothState
{
    if (inBlueToothState == self.blueToothState)
    {
        return;
    }
    
    blueToothState = inBlueToothState;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDBlueToothStateChangedNotification object:self];
}


@end
