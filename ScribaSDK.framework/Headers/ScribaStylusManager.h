//
//  ScribaStylus2Manager.h
//
//  Created by Dublin Design Studio Ltd.
//  Copyright (c) 2015 Dublin Design Studio Ltd. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "ScribaStylusDevice.h"

static NSString * const WDStylusPrimaryButtonPressedNotification = @"WDStylusPrimaryButtonPressedNotification";
static NSString * const WDStylusSecondaryButtonPressedNotification = @"WDStylusSecondaryButtonPressedNotification";

static NSString * const WDStylusDidConnectNotification = @"WDStylusDidConnectNotification";
static NSString * const WDStylusDidDisconnectNotification = @"WDStylusDidDisconnectNotification";
static NSString * const WDStylusListUpdatedNotification = @"WDStylusListUpdatedNotification";

static NSString * const WDBlueToothStateChangedNotification = @"WDBlueToothStateChangedNotification";

static NSString * const WDSizeChangedNotification = @"WDSizeChangedNotification";
static NSString * const WDLockChangedNotification = @"WDLockChangedNotification";


static NSString * const BuzzNotification = @"BuzzNotification";

typedef NS_ENUM(NSUInteger,BuzzType)
{
    BuzzTypeOnce = 1,
    BuzzTypeTwice = 2,
    BuzzTypeTriple = 3
};

typedef void (^CompletionBlock)(NSError *error);


typedef NS_ENUM(NSUInteger,WDBlueToothState)
{
    WDBlueToothOff = 0,
    WDBlueToothLowEnergy
};

@protocol ScribaStylusBluetoothDelegate <NSObject>

@optional

-(void)bluetoothStatusChanged:(WDBlueToothState)state;

@end

@protocol ScribaStylusManagerDelegate <NSObject>

@optional
/*!
 * @discussion Callback method where a list of all available Scriba devices are found
 * @param A list of Scriba devices are returned.
 */
-(void)didFoundDevices:(NSArray*)devices;

/*!
 * @discussion Callback method when a Scriba device is connected.
 * @param device The Scriba device triggers this event
 * @param The CBCentralManager object
 */
-(void)didConnectedDevice:(ScribaStylusDevice*)device manager:(CBCentralManager*)manager;

/*!
 * @discussion Callback method when a Scriba device is disconnected.
 * @param device The scriba device triggers this event
 */
-(void)didDisconnectDevice:(ScribaStylusDevice*)device;


/*!
 * @discussion Callback method when the Scriba battery info is detected.
 * @param device The Scriba device triggers the event
 * @param batteryState The battery value is returned, as value between 0.0 and 1.0.
 */
-(void)didUpdatedBatteryStateForDevice:(ScribaStylusDevice*)device batteryState:(float)batteryState;


/*!
 * @discussion Callback method when depression value is changed
 * @param device The scriba device triggers the event
 * @param depression The depression value passes from Scriba device as a value between 0.0 and 1.0.
 */
-(void)didChangedDepressionForDevice:(ScribaStylusDevice*)device depression:(float)depression;


/*!
 * @discussion Callback method when the Squeeze Zone is changed
 * @param device The scriba device triggers the event
 * @param squeezeZone The squeeze zone level is returned as a value between 1 and 5, see the WIKI for further details
 */
-(void)didChangedSqueezeZoneForDevice:(ScribaStylusDevice*)device squeezeZone:(NSInteger)squeezeZone;

/*!
 * @discussion Callback method when a Single Click event is triggered
 * @param device The Scriba device triggers the event
 */
-(void)didSingleClickWithDevice:(ScribaStylusDevice*)device;

/*!
 * @discussion Callback method when Double Click event is triggered
 * @param device The Scriba device triggers the event
 */
-(void)didDoubleClickWithDevice:(ScribaStylusDevice*)device;

/*!
 * @discussion Callback method when Triple click event is triggered
 * @param device The Scriba device triggers the event
 */
-(void)didTrippleClickWithDevice:(ScribaStylusDevice*)device;

@end

@interface ScribaStylusManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (ScribaStylusManager *) sharedManager;

/*!
 * @brief A ScribaStylusManagerDelegate delegate
 */
@property (nonatomic, weak) id<ScribaStylusManagerDelegate> delegate;

/*!
 * @brief A bluetooth delegate
 */
@property (nonatomic, weak) id<ScribaStylusBluetoothDelegate> bluetoothDelegate;

/*!
 * @brief Connected Scriba device
 */
@property (nonatomic, strong) ScribaStylusDevice *connectedDevice;

/*!
 * @brief Current Scriba battery level
 */
@property (nonatomic, assign) float currentDeviceBatteryState;

/*!
 * @brief Current Scriba device depression level
 */
@property (nonatomic, assign) float currentDeviceButtonDepression;

/*!
 * @brief Current Scriba device depression value
 */
@property (nonatomic, assign) float currentDeviceButtonDepressionStrength;


/*!
 * @brief Set if automatically connecting to any discovered Scriba device. Default is YES.
 */
@property (nonatomic, assign) BOOL shouldAutoconnectDiscoveredScriba;

/*!
 * @brief Check Bluetooth to see if Bluetooth is currently enabled on iOS device
 */
@property (nonatomic, readonly) BOOL isBlueToothEnabled;

/*!
 * @brief Pop up alert when Connecting or Disconnecting a Scriba device
 */
@property (nonatomic) BOOL alertUserWhenScribaConnectionChanged;


#pragma mark - scriba device management

/*!
 * @discussion Start to scan any Scriba devices
 */
-(void)startScanning;

/*!
 * @discussion Stop scan for Scriba devices
 */
-(void)stopScanning;

/*!
 * @discussion Connecting to the found Scriba device
 * @param The found Scriba device
 */
-(void)tryConnectDevice:(ScribaStylusDevice*)device completion:(CompletionBlock)finishBlock;
//-(void)disconncectCurrentDevice;

/*!
 * @discussion Disconnect Scriba when app is not foreground app, this can be called at 'applicationDidEnterBackground' method
 */
-(void)disconnectCurrentDeviceCompletion:(CompletionBlock)finishBlock;
;

/*!
 * @discussion Automatically connect Scriba when the app is the foreground app, this can be called at 'applicationDidBecomeActive' method
 */
-(void)restoreLastDeviceConnection;


/*!
 * @discussion The Scriba SDK will store any found Scriba without the requirement for user intervention
 * @return Return a list of scriba devices found.
 */
-(NSArray*)getListOfScribaDevices;


#pragma mark - smart lock
/*!
 * @brief The Smart-Lock feature allows the SDK to detect when a user is maintaining a consistent depress of Scriba and will automatically lock the pressure at this value.  This is of particular benefit in detecting that a user wants to draw a line of consistent width. To enable the feature, call 'enableSmartLock:TRUE' otherwise this feature is disabled.
 * @discussion Check if the smart lock is enabled
 * @return TRUE if enabled, FALSE if disabled.
 */
-(BOOL)isSmartLockEnabled;

/*!
 * @discussion Set Smart-Lock enable status
 * @param Set TRUE to enable Smart-Lock, otherwise Smart-Lock is disabled.
 */
-(void)enableSmartLock:(BOOL)enableSmartLock;

/*!
 * @discussion Manually set brush or line thickness.  This feature only take effect when smart lock is triggered.
 * @param Specifies the brush size, and it should be between the maximum and minimum brush size, otherwise it is ignored.
 */
-(void)setBrushSizeInLockedMode:(float)brushSize;

/*!
 * @discussion Disable the Smart-Lock manually allowing Scriba depression to freely change brish size between maximum and minimum values.  This is usually achieved through a full depress of Scriba.
 *
 */
- (void)removeSmartLock;

/*!
 * @discussion Check if the Smart-Lock is on
 *
 */
- (BOOL)isSmartLockOn;

/*!
 * @discussion Enables haptic feedback feature if a 'Buzz' command is sent to Scriba
 *
 */
- (void)enableHapticsBuzz;

/*!
 * @discussion Disable haptic feedback functionality
 *
 */
- (void)disableHapticsBuzz;

#pragma mark - brush size
/*!
 * @discussion Set a maximum value for the brush size, The default value is 100 on iPads.
 * @param Specifies the maximum value
 */
- (void)setMaximumBrushSize:(float)brushSize;

/*!
 * @discussion Set a minimum value for the brush size.  The default value is 1.
 * @param Specifies the minmum value
 */
- (void)setMinimumBrushSize:(float)brushSize;

/*!
 * @discussion Reset the maximum brush size.
 */
- (void)resetMaximumBrushSize;

/*!
 * @discussion Reset the minimum brush size.
 */
- (void)resetMinimumBrushSize;

/*!
 * @discussion Identify whether Scriba is currently depressed.
 * @return TRUE if depress, FALSE if not depressed.
 */
- (BOOL)isScribaDepressed;


@end


