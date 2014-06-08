//
//  Utilities.m
//  filterViewer
//
//  Created by earth on 6/9/14.
//  Copyright (c) 2014 filmhomage.net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilites.h"

@implementation Utilites

+(UIImage*)resizeImage:(UIImage*)inImage maxResolution:(int)inResolution
{
    CGImageRef imgRef = inImage.CGImage;
    CGBitmapInfo alphaInfo = CGImageGetBitmapInfo(imgRef);
    
    if(alphaInfo == kCGImageAlphaNone)
        alphaInfo = kCGBitmapAlphaInfoMask;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    int newWidth = 0;
    int newHeight = 0;
    CGFloat ratio = width/height;
    if (ratio > 1) {
        newWidth = inResolution;
        newHeight = newWidth / ratio;
    }
    else {
        newHeight = inResolution;
        newWidth = newHeight * ratio;
    }
    
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef tempContext = CGBitmapContextCreate(NULL,
                                                     newWidth,
                                                     newHeight,
                                                     8,
                                                     (4 * newWidth),
                                                     genericColorSpace,
                                                     alphaInfo);
    CGColorSpaceRelease(genericColorSpace);
    CGContextSetInterpolationQuality(tempContext, kCGInterpolationDefault);
    CGContextDrawImage(tempContext, CGRectMake(0, 0, newWidth, newHeight), imgRef);
    CGImageRef tempImage = CGBitmapContextCreateImage(tempContext);
    CGContextRelease(tempContext);
    
    UIImage* resultImage = [UIImage imageWithCGImage:tempImage scale:1.0 orientation:inImage.imageOrientation];
    CGImageRelease(tempImage);
    
    return resultImage;
}

@end