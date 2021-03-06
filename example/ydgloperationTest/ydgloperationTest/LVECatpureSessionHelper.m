//
//  LVECatpureSessionHelper.m
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "LVECatpureSessionHelper.h"

@import AVFoundation;

@interface LVECatpureSessionHelper ()

@property(nonatomic,nullable,retain) AVCaptureSession *customCaptureSession;//

@property(nonatomic,nullable,retain) AVCaptureVideoDataOutput *videoDataOutput;//

@property(nonatomic,nullable,retain) AVCaptureDeviceInput *backVideoInput;//后置摄像头

@property(nonatomic,nullable,retain) AVCaptureDeviceInput *frontVideoInput;//前置摄像头

@property(nonatomic,nullable,assign) AVCaptureDeviceInput *currentVideoInput;//当前的摄像头摄像头

@end


@implementation LVECatpureSessionHelper


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self commonInitialization];
        
    }
    return self;
}

-(void)commonInitialization{
    
    AVCaptureSession *captureSession=[[AVCaptureSession alloc]init];
    
    captureSession.sessionPreset=AVCaptureSessionPreset640x480;
    
    AVCaptureVideoDataOutput *videoDataOutput=[[AVCaptureVideoDataOutput alloc]init];
    
    NSMutableDictionary *defaultSetting=[NSMutableDictionary dictionaryWithDictionary:[videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4]];
    
    //[defaultSetting setObject:@(20) forKey:AVVideoMaxKeyFrameIntervalKey];
    
    videoDataOutput.alwaysDiscardsLateVideoFrames=YES;
    
    BOOL supportsFullYUVRange=NO;
    
    NSArray *supportedPixelFormats = videoDataOutput.availableVideoCVPixelFormatTypes;
    
    for (NSNumber *currentPixelFormat in supportedPixelFormats)
    {
        if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        {
            supportsFullYUVRange = YES;
        }
    }
    
    if (supportsFullYUVRange)
    {
        [defaultSetting setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    }
    else
    {
        [defaultSetting setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    }

    [videoDataOutput setVideoSettings:defaultSetting];
    
    [captureSession addOutput:videoDataOutput];
    
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        
        switch (device.position) {
            case AVCaptureDevicePositionBack:{
                
                AVCaptureDeviceInput *videoInput=[AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
                self.backVideoInput=videoInput;
            }
                break;
                
            case AVCaptureDevicePositionFront:{
                
                AVCaptureDeviceInput *videoInput=[AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
                self.frontVideoInput=videoInput;
            }
                break;
                
            default:
                break;
        }
        
    }
    
    self.customCaptureSession=captureSession;
    self.videoDataOutput=videoDataOutput;
    
    [self setVideoInput:_frontVideoInput];
    
}

-(void)startRunning{
    
    [self.customCaptureSession startRunning];
}

-(void)setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)bufferDelegate queue:(dispatch_queue_t)queue{
    
    [self.videoDataOutput setSampleBufferDelegate:bufferDelegate queue:queue];
    
}

-(void)stopRunning{
    
    [self.customCaptureSession stopRunning];
}


-(void)swatchCamera{
    
    switch (_currentVideoInput.device.position) {
        case AVCaptureDevicePositionBack:
            
            [self setVideoInput:_frontVideoInput];
            
            break;
        case AVCaptureDevicePositionFront:
            [self setVideoInput:_backVideoInput];
            break;
            
        default:
            break;
    }
    
}

-(void)setVideoInput:(AVCaptureDeviceInput*)deviceInput{
    
    [self.customCaptureSession beginConfiguration];
    
    [self.customCaptureSession removeInput:_currentVideoInput];
    
    switch (_currentVideoInput.device.position) {
        case AVCaptureDevicePositionFront:
            
            _currentVideoInput=_backVideoInput;
            break;
        case AVCaptureDevicePositionBack:
            
            _currentVideoInput=_frontVideoInput;
            
            break;
            
        default:
            break;
    }
    
    [self.customCaptureSession addInput:deviceInput];
    
    _currentVideoInput=deviceInput;
    
    [self.customCaptureSession commitConfiguration];
    
    AVCaptureConnection *videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnection) {
        
        BOOL mirror = _currentVideoInput==_frontVideoInput;
        
        if ([videoConnection isVideoMirroringSupported]) {
            
            [videoConnection setVideoMirrored:mirror];
            [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        
    }
    
}

@end
