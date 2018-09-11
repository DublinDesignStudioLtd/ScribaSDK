//
//  ScribaStylusDevice.h
//
//  Created by Dublin Design Studio Ltd.
//  Copyright (c) 2015 Dublin Design Studio Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSUInteger,ScribaDeviceState)
{
    ScribaDeviceStateDisconnected,
    ScribaDeviceStateConnected
};


@interface ScribaStylusDevice : NSObject <NSCoding>

@property (nonatomic, strong) CBPeripheral* peripheral;

@property (nonatomic, assign) BOOL enabledBatteryNotification;

/*
 *Return the current Scriba state
 */
@property (nonatomic) ScribaDeviceState state;

//+ (ScribaStylusDevice*) initWithPeripheral:(CBPeripheral*)peripheral andCenterManager:(CBCentralManager*)manager NS_DEPRECATEDNS_DEPRECATED (1_0, 1_4);

/*!
 * @discussion Return the Scriba name
 */
- (NSString*)name;

/*!
 * @discussion Return Scriba firmware version (i.e 1.29)
 */
- (float)getScribaDeviceVersion;

/*!
 * @discussion Return scriba identifier (== peripheral.identifier), this is also useful when a Scriba is unavailable, then retrieve the last connected Scriba identifier
 * uuid
 */
- (NSUUID*)getScribaDeviceIdentifier;

/*!
 * @discussion A recognized Scriba is a device that is either connected or the most recently connected Scriba.
 */
- (BOOL)isRecognizedDevice;
- (void)setRecognizedDevice:(BOOL)recognizedDevice;

@end

