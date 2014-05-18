//
//  ImageViewController.m
//  FaceChanger
//
//  Created by Kiyan Liu on 5/13/14.
//  Copyright (c) 2014 FreeTymeKiyan. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController ()

@end

@implementation ImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.processedImg setImage:self.img];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    if ([self.whichBtn isEqualToString:@"eyes"]) {
        [self.processButton setTitle:@"Eyes" forState:UIControlStateNormal];
        [self.processButton addTarget:self action:@selector(cropClicked:)
                     forControlEvents:UIControlEventTouchUpInside];
        self.progressView = [[MBProgressHUD alloc] initWithView:self.view];
        [self.progressView setLabelText:@"Analizing Human..."];
        [self.view addSubview:self.progressView];
        [self.progressView show:YES];

        [self performSelectorInBackground:@selector(detectWithImage:) withObject:self.img];
    } else if([self.whichBtn isEqualToString:@"sketch"]) {
        [self.processButton setTitle:@"Sketch" forState:UIControlStateNormal];
        [self.processButton addTarget:self action:@selector(sketchClicked:)
                     forControlEvents:UIControlEventTouchUpInside];
    } else if ([self.whichBtn isEqualToString:@"invert"]) {
        [self.processButton setTitle:@"Invert" forState:UIControlStateNormal];
        [self.processButton addTarget:self action:@selector(invertClicked:)
                     forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"111");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little 
// preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (sender != self.doneButton) return; //not done button
    self.img = [self.processedImg image];
}

- (IBAction)cropClicked:(id)sender
{
//    NSLog(@"crop clicked");
    UIImage *originalImg = self.img;
    UIImage *croppedImg = [self cropImg:originalImg path:self.cropPath];
    
    GPUImagePicture *picture1 = [[GPUImagePicture alloc] initWithImage:originalImg];
    GPUImagePicture *picture2 = [[GPUImagePicture alloc] initWithImage:croppedImg];
    
    GPUImageColorInvertFilter *filter1 = [[GPUImageColorInvertFilter alloc] init];
    GPUImageNormalBlendFilter *filter2 = [[GPUImageNormalBlendFilter alloc] init];
    
    [picture2 addTarget:filter1];
    [picture1 addTarget:filter2];
    [filter1 addTarget:filter2];

    [picture2 processImage];
    [filter1 useNextFrameForImageCapture];
    [picture1 processImage];
    [filter2 useNextFrameForImageCapture];

    UIImage *blendImage = [filter2 imageFromCurrentFramebuffer];
    
    [self.processedImg setImage:blendImage];
}

- (UIBezierPath *)arrayToBezierPaths:(NSMutableArray *) arr
{
    UIBezierPath* path = [UIBezierPath bezierPath];
    path.lineCapStyle = kCGLineCapRound; //线条拐角
    path.lineJoinStyle = kCGLineCapRound; //终点处理
    uint i = 0;
    for (NSValue *point in arr) {
        if (i == 0) {
            [path moveToPoint:point.CGPointValue];
        } else {
            [path addLineToPoint:point.CGPointValue];
        }
        i++;
    }
    [path closePath];
    return path;
}

- (UIImage *)cropImg:(UIImage *) originalImg path:(UIBezierPath *) path
{
    UIImage *result;
    
    UIGraphicsBeginImageContextWithOptions(originalImg.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);
    [path addClip];
    [originalImg drawAtPoint:CGPointZero];
    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

// Use facepp SDK to detect faces
-(void) detectWithImage: (UIImage*) image
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // face detection
    FaceppResult *result = [[FaceppAPI detection] detectWithURL:nil orImageData:UIImageJPEGRepresentation(image, 1) mode:FaceppDetectionModeNormal attribute:FaceppDetectionAttributeNone];
    if (result.success) {
        double image_width = [[result content][@"img_width"] doubleValue] *0.01f;
        double image_height = [[result content][@"img_height"] doubleValue] * 0.01f;
        
        UIGraphicsBeginImageContext(image.size);
        [image drawAtPoint:CGPointZero];
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
        CGContextSetLineWidth(context, image_width * 0.7f);
        
        // draw rectangle in the image
        int face_count = [[result content][@"face"] count];
        if (face_count == 0) {
            [self.progressView hide:YES];
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"No Face Detected"
                                  message:@"Please try with another picture."
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
            [alert release];
        } else {
            self.cropPath = [[UIBezierPath alloc] init];
            for (int i=0; i<face_count; i++) {
                //            double width = [[result content][@"face"][i][@"position"][@"width"] doubleValue];
                //            double height = [[result content][@"face"][i][@"position"][@"height"] doubleValue];
                //            CGRect rect = CGRectMake(([[result content][@"face"][i][@"position"][@"center"][@"x"] doubleValue] - width/2) * image_width, ([[result content][@"face"][i][@"position"][@"center"][@"y"] doubleValue] - height/2) * image_height, width * image_width, height * image_height);
                //            CGContextStrokeRect(context, rect);
                NSString *faceId = [[result content][@"face"][i] objectForKey:@"face_id"];
                //            NSLog(@"face_id: %@", faceId);
                FaceppResult *landmarks = [[FaceppAPI detection] landmarkWithFaceId:faceId andType:FaceppLandmark83P];
                // get face landmarks
                for (int j=0; j<[[landmarks content] [@"result"] count]; j++) {
                    // left eye
                    double x1 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_bottom"][@"x"] doubleValue] * image_width;
                    double y1 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_bottom"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x1, y1, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x2 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_lower_left_quarter"][@"x"] doubleValue] * image_width;
                    double y2 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_lower_left_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x2, y2, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x3 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_left_corner"][@"x"] doubleValue] * image_width;
                    double y3 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_left_corner"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x3, y3, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x4 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_upper_left_quarter"][@"x"] doubleValue] * image_width;
                    double y4 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_upper_left_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x4, y4, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x5 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_top"][@"x"] doubleValue] * image_width;
                    double y5 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_top"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x5, y5, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x6 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_upper_right_quarter"][@"x"] doubleValue] * image_width;
                    double y6 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_upper_right_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x6, y6, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x7 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_right_corner"][@"x"] doubleValue] * image_width;
                    double y7 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_right_corner"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x7, y7, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x8 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_lower_right_quarter"][@"x"] doubleValue] * image_width;
                    double y8 = [[landmarks content][@"result"][j][@"landmark"][@"left_eye_lower_right_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x8, y8, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    // right eye
                    double x9 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_bottom"][@"x"] doubleValue] * image_width;
                    double y9 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_bottom"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x9, y9, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x10 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_lower_left_quarter"][@"x"] doubleValue] * image_width;
                    double y10 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_lower_left_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x10, y10, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x11 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_left_corner"][@"x"] doubleValue] * image_width;
                    double y11 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_left_corner"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x11, y11, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x12 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_upper_left_quarter"][@"x"] doubleValue] * image_width;
                    double y12 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_upper_left_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x12, y12, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x13 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_top"][@"x"] doubleValue] * image_width;
                    double y13 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_top"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x13, y13, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x14 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_upper_right_quarter"][@"x"] doubleValue] * image_width;
                    double y14 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_upper_right_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x14, y14, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x15 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_right_corner"][@"x"] doubleValue] * image_width;
                    double y15 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_right_corner"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x15, y15, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    double x16 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_lower_right_quarter"][@"x"] doubleValue] * image_width;
                    double y16 = [[landmarks content][@"result"][j][@"landmark"][@"right_eye_lower_right_quarter"][@"y"] doubleValue] * image_height;
                    //                rect = CGRectMake(x16, y16, 1.0, 1.0);
                    //                CGContextStrokeRect(context, rect);
                    
                    NSMutableArray *leftEyePoints = [[NSMutableArray alloc] init];
                    
                    CGPoint p;
                    NSValue* value;
                    
                    p = CGPointMake(x1, y1);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x2, y2);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x3, y3);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x4, y4);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x5, y5);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x6, y6);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x7, y7);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    p = CGPointMake(x8, y8);
                    value = [NSValue valueWithCGPoint:p];
                    [leftEyePoints addObject:value];
                    
                    NSMutableArray *rightEyePoints = [[NSMutableArray alloc] init];
                    p = CGPointMake(x9, y9);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x10, y10);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x11, y11);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x12, y12);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x13, y13);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x14, y14);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x15, y15);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    p = CGPointMake(x16, y16);
                    value = [NSValue valueWithCGPoint:p];
                    [rightEyePoints addObject:value];
                    //                NSLog(@"left eye: %@", leftEyePoints);
                    //                NSLog(@"right eye: %@", rightEyePoints);
                    [self.cropPath appendPath:[self arrayToBezierPaths:leftEyePoints]];
                    [self.cropPath appendPath:[self arrayToBezierPaths:rightEyePoints]];
                }
            }
            UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            //        float scale = 1.0f;
            //        scale = MIN(scale, 280.0f/newImage.size.width);
            //        scale = MIN(scale, 257.0f/newImage.size.height);
            //        [_processedImg setFrame:CGRectMake(_processedImg.frame.origin.x,
            //                                           _processedImg.frame.origin.y,
            //                                           newImage.size.width * scale,
            //                                           newImage.size.height * scale)];
            [_processedImg setImage:newImage];
        }
    } else {
        // some errors occurred
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"error message: %@", [result error].message]
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
    }
    [image release];
    [pool release];
    [self.progressView hide:YES];
}


- (IBAction)sketchClicked:(id)sender
{
    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
    filter.edgeStrength = 0.5;
    UIImage *filteredImg = [filter imageByFilteringImage:self.img];
    [self.processedImg setImage:filteredImg];
    
    // The texel width and height factors tweak the appearance of the edges. By default, they match the inverse of the filter size in pixels
    //    CGFloat texelWidth;
    //    CGFloat texelHeight;
    
    // The filter strength property affects the dynamic range of the filter. High values can make edges more visible, but can lead to saturation. Default of 1.0.
    //    CGFloat edgeStrength;
    
}

- (IBAction)invertClicked:(id)sender
{
    GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
    UIImage *filteredImg = [filter imageByFilteringImage:self.img];
    [self.processedImg setImage:filteredImg];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc {
    [_doneButton release];
    [_processedImg release];
//    [_img release];
    [_processButton release];
    [_cropPath release];
    [_progressView release];
    [super dealloc];
}
@end
