//
//  ScribaStylusDevice.m
//  Brushes
//
//  Created by Pawel Sikora on 15/05/15.
//  Copyright (c) 2015 Taptrix, Inc. All rights reserved.
//


#import "ScribaStylusDevice.h"

@interface ScribaStylusDevice()

//@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
/*
 * @discussion the value same as peripheral.identifier, this is part of NSCoding to remember last connected device
 */
@property (nonatomic, strong) NSUUID *identifier;

/*
 * @discussion this is part of NSCoding to remember last connected device's name
 */
@property (nonatomic, strong) NSString *scribaDeviceName;

//@property (nonatomic, weak) CBCentralManager *cbCenterManager;

@end

@implementation ScribaStylusDevice{
    
    BOOL recognized;
}

//+ (ScribaStylusDevice*) initWithPeripheral:(CBPeripheral*)peripheral andCenterManager:(CBCentralManager*)manager
//{
//    ScribaStylusDevice* scribaStylusDevice = [[ScribaStylusDevice alloc] init];
//    scribaStylusDevice.peripheral = peripheral;
//    scribaStylusDevice.cbCenterManager = manager;
//    scribaStylusDevice.status = status;
//    //[scribaStylusDevice refreshLastSeenTime];
//
//    return scribaStylusDevice;
//}

//only be called from initWithCoder
- (instancetype)initWithScribaDeviceIdentifier:(NSUUID*)uuid andName:(NSString*)name{
    
    self = [super init];
    if (self) {
        self.identifier = uuid;
        self.scribaDeviceName = name;
        recognized = YES;
    }
    
    return self;
}

-(NSString*)name
{
    if (self.scribaDeviceName) {
        return self.scribaDeviceName;
    }
    
    NSString* name = [self.peripheral name];
    if (!name) {
        return @"No name";
    }
    
    NSUUID *bleUUID = [self.peripheral identifier];
    
    NSString *suffix = @"";
    if (bleUUID.UUIDString.length >= 4) {
        suffix = [bleUUID.UUIDString substringFromIndex:bleUUID.UUIDString.length - 4];
    }
    
    return [NSString stringWithFormat:@"%@ %@",name,suffix];
}

- (float)getScribaDeviceVersion
{
    NSString *name = [self name];
    
    float version = 0;
    
    if (name)
    {
        NSString *filterString = @"ScribaV";
        
        NSRange range = [name rangeOfString:filterString];
        
        if (range.location != NSNotFound)
        {
            version = [[name substringFromIndex:range.length] floatValue];
        }
    }
    
    return version;
}

- (NSUUID*)getScribaDeviceIdentifier{
    
    NSUUID *retVal = nil;
    if (self.peripheral) {
        retVal = self.peripheral.identifier;
    }
    else if (self.identifier) {
        retVal = self.identifier;
    }
    
    return retVal;
}


-(BOOL)isEqual:(id)object
{
    ScribaStylusDevice* other = (ScribaStylusDevice*) object;
    return self.peripheral == other.peripheral;
}

- (BOOL)isRecognizedDevice
{
    return recognized;
}

- (void)setRecognizedDevice:(BOOL)recognizedDevice
{
    recognized = recognizedDevice;
}

#pragma mark NSCoding

#define kScribaNameKey          @"ScribName"
#define kScribaUUIDKey          @"ScribaUUID"

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:[self name] forKey:kScribaNameKey];
    [encoder encodeObject:[self peripheral].identifier forKey:kScribaUUIDKey];
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    NSString *name = [decoder decodeObjectForKey:kScribaNameKey];
    NSUUID *identifier = [decoder decodeObjectForKey:kScribaUUIDKey];

    ScribaStylusDevice *scribaStylusDevice = [[ScribaStylusDevice alloc] initWithScribaDeviceIdentifier:identifier andName:name];
    
    return scribaStylusDevice;
}

@end
