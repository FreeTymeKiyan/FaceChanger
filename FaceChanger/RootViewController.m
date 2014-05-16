//
//  RootViewController.m
//  FaceChanger
//
//  Created by Kiyan Liu on 5/11/14.
//  Copyright (c) 2014 FreeTymeKiyan. All rights reserved.
//

#import "RootViewController.h"


@implementation RootViewController

- (IBAction)unwindToRootview:(UIStoryboardSegue *)segue
{
    ImageViewController *source = [segue sourceViewController];// 通过sourceViewController获取view
    UIImage *img = source.img;
    if (img != nil) {
        [self.chosenImage setImage:img];
    }
}

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
    imagePicker = [[UIImagePickerController alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)chooseFromAlbum:(id)sender {
    [_stateLabel setText:@"choose from album"];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        [self presentModalViewController:imagePicker animated:YES];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"failed to access photo library"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
    }

}

- (IBAction)chooseFromCamera:(id)sender {
    NSLog(@"choose from camera");
    [_stateLabel setText:@"choose from camera"];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
//        [self presentModalViewController:imagePicker animated:YES];
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"failed to camera"
                              message:@""
                              delegate:nil
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil];
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        [alert release];
    }
}

-(UIImage*)scaleImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];

//    NSData *imgData = UIImageJPEGRepresentation(sourceImage, 1);
//    NSLog(@"Size of Image(bytes):%d",[imgData length]);
//    if ([imgData length] > 3000000) {
//        CGFloat compression = 3000000.0 / [imgData length];
//        NSLog(@"compression:%f", compression);
//        imgData = UIImageJPEGRepresentation(sourceImage, compression);
//        NSLog(@"new size: %d", [imgData length]);
//        sourceImage = [UIImage imageWithData:imgData];
//    }
    
    CGSize imageSize = sourceImage.size;
    float scaleFactor = imageSize.height > imageSize.width ? imageSize.height : imageSize.width;
    scaleFactor /= 900;
    imageSize.height /= scaleFactor;
    imageSize.width /= scaleFactor;
    sourceImage = [self scaleImage:sourceImage scaledToSize:imageSize];
    
    UIImage *imageToDisplay = [self fixOrientation:sourceImage];
    [self performSelectorInBackground:@selector(detectWithImage:) withObject:[imageToDisplay retain]];
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

// Use facepp SDK to detect faces
-(void) detectWithImage: (UIImage*) image {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
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
        for (int i=0; i<face_count; i++) {
            double width = [[result content][@"face"][i][@"position"][@"width"] doubleValue];
            double height = [[result content][@"face"][i][@"position"][@"height"] doubleValue];
            CGRect rect = CGRectMake(([[result content][@"face"][i][@"position"][@"center"][@"x"] doubleValue] - width/2) * image_width,
                                     ([[result content][@"face"][i][@"position"][@"center"][@"y"] doubleValue] - height/2) * image_height,
                                     width * image_width,
                                     height * image_height);
            CGContextStrokeRect(context, rect);
            NSString *faceId = [[result content][@"face"][i] objectForKey:@"face_id"];
            NSLog(@"face_id: %@", faceId);
            FaceppResult *landmarks = [[FaceppAPI detection] landmarkWithFaceId:faceId andType:FaceppLandmark83P];
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
                
                self.leftEyePoints = [[NSMutableArray alloc] init];
                
                CGPoint p;
                NSValue* value;
                
                p = CGPointMake(x1, y1);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x2, y2);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x3, y3);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x4, y4);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x5, y5);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x6, y6);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x7, y7);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                p = CGPointMake(x8, y8);
                value = [NSValue valueWithCGPoint:p];
                [_leftEyePoints addObject:value];
                

                
                self.rightEyePoints = [[NSMutableArray alloc] init];
                p = CGPointMake(x9, y9);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x10, y10);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x11, y11);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x12, y12);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x13, y13);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x14, y14);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x15, y15);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
                p = CGPointMake(x16, y16);
                value = [NSValue valueWithCGPoint:p];
                [_rightEyePoints addObject:value];
//                NSLog(@"left eye: %@", leftEyePoints);
//                NSLog(@"right eye: %@", rightEyePoints);
            }
        }
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        float scale = 1.0f;
        scale = MIN(scale, 280.0f/newImage.size.width);
        scale = MIN(scale, 257.0f/newImage.size.height);
        [_chosenImage setFrame:CGRectMake(_chosenImage.frame.origin.x,
                                       _chosenImage.frame.origin.y,
                                       newImage.size.width * scale,
                                       newImage.size.height * scale)];
        [_chosenImage setImage:newImage];
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
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [pool release];
}
                                                        
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"root view prepare for segue");
    UINavigationController *navController = (UINavigationController *) segue.destinationViewController;
    ImageViewController *vc = (ImageViewController *)navController.topViewController;
    if([vc isKindOfClass:[ImageViewController class]]) {
        vc.img = [[self chosenImage] image];
        vc.leftEyePoints = self.leftEyePoints;
        vc.rightEyePoints = self.rightEyePoints;
//        NSLog(@"left eye:%@", vc.leftEyePoints);
    } else {
        
    }
}

- (void)dealloc {
    [imagePicker release];
    [_stateLabel release];
    [_chosenImage release];
    
    [_leftEyePoints release];
    [_rightEyePoints release];
    [super dealloc];
}
@end
