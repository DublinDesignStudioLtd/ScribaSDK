//
//  SmartBrushHelper.h
//  Brushes
//
//  Created by Pawel Sikora on 29/04/15.
//  Copyright (c) 2015 Taptrix, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScribaBrushHelper : NSObject

+(float)sizeForPressureInPixel:(float)pressure;
+(float)pressureFromBrushSize:(float)brushSize;


@end
