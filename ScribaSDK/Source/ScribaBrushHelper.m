//
//  SmartBrushHelper.m
//  Brushes
//
//  Created by Pawel Sikora on 29/04/15.
//  Copyright (c) 2015 Taptrix, Inc. All rights reserved.
//

#define MIN_SIZE     1.0;
#define MAX_SIZE     100;//150.0*1.25;

#import "ScribaBrushHelper.h"


static NSString * const smartBrushOnUserDefaultsKey = @"isSmartBrushOn";

@implementation ScribaBrushHelper

+(float)sizeForPressureInPixel:(float)pressure{

    
    if(pressure > 0.01){
        return pressure * 100.0;
    } else {
        return 1.0;
    }
    
    float minSize = MIN_SIZE;
    float maxSize = MAX_SIZE;
    float curveExponentialRatio = 1.1;
    
    pressure = fabs(pressure);
    
    float fraction = (pressure<0.0001) ? 0.0 : -powf(2, -curveExponentialRatio * pressure/1) + 1;
    
    float size = minSize + fraction * (maxSize - minSize);
    
    return size;
}

+(float)pressureFromBrushSize:(float)brushSize{
    
    float minSize = MIN_SIZE;
    float maxSize = MAX_SIZE;
    
    if (brushSize <= minSize) {
        return 0;
    }
    
    if (brushSize >= maxSize) {
        return 1.0f;
    }
    
    return brushSize * 1.0f / (maxSize - minSize);

}


@end
