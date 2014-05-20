//
//  RootViewController.m
//  FaceChanger
//
//  Created by Kiyan Liu on 5/11/14.
//  Copyright (c) 2014 FreeTymeKiyan. All rights reserved.
//

#import "RootViewController.h"
#define FROM_CAMERA 0
#define FROM_ALBUM 1
#define MY_BANNER_UNIT_ID @"ca-app-pub-3830008196770332/1800879607"

@implementation RootViewController
@synthesize originalImg;

- (IBAction)unwindToRootview:(UIStoryboardSegue *)segue
{
    ImageViewController *source = [segue sourceViewController];// 通过sourceViewController获取view
    UIImage *img = source.img;
    if (img != nil) {
        [self.chosenImage setImage:img];
        [img release];
        [originalImg retain];
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
    CGSize screenSize = [[UIScreen mainScreen]bounds].size;
    
    imagePicker = [[UIImagePickerController alloc] init];
    self.originalImg = [self.chosenImage image];
    [originalImg retain];

    bannerView_ = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    [bannerView_ setFrame:CGRectMake(0, screenSize.height - self.toolbarScrollView.frame.size.height - 50, screenSize.width, 50)];
    // Specify the ad unit ID.
    bannerView_.adUnitID = MY_BANNER_UNIT_ID;
    
    // Let the runtime know which UIViewController to restore after taking
    // the user wherever the ad goes and add it to the view hierarchy.
    bannerView_.rootViewController = self;
    [self.view addSubview:bannerView_];
    
    // Initiate a generic request to load it with an ad.

    GADRequest *request = [GADRequest request];
    request.testDevices = [NSArray arrayWithObjects:
                           @"3b9462c81bb3625a0fee115abbb10b30",
                           nil];
    [bannerView_ loadRequest:request];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGSize toolbarSize = [self.toolbarScrollView bounds].size;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    [self.toolbarScrollView setContentSize:CGSizeMake(screenSize.width * 1.5, toolbarSize.height)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"MMMMMMMMMMMMMMMMMMMM");
}

- (void)chooseFromAlbum
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
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

- (void)chooseFromCamera
{
//    NSLog(@"choose from camera");
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
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

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{


    UIImage *sourceImage = info[UIImagePickerControllerOriginalImage];
    
//  img compression
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
    
    [self.chosenImage setImage:imageToDisplay];
    self.originalImg = [self.chosenImage image];
    [originalImg retain];
    [imageToDisplay release];
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
    
    //    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //    [self performSelectorInBackground:@selector(detectWithImage:) withObject:[imageToDisplay retain]];
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
    if([segue.identifier isEqualToString:@"more"]) {
        
    } else {
        ImageViewController *vc = (ImageViewController *) segue.destinationViewController;
//        ImageViewController *vc = (ImageViewController *)navController.topViewController;
//        if ([vc isKindOfClass:[ImageViewController class]]) {
//            NSLog(@"111");
//        }
        vc.img = [[self chosenImage] image];
        vc.whichBtn = segue.identifier;
        //        NSLog(@"left eye:%@", vc.leftEyePoints);
    }
}

- (IBAction)addClicked:(id)sender;
{
    UIActionSheet *sheet=[[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"From Camera" otherButtonTitles: @"From Album", nil];
    [sheet showInView:self.view];
}

- (IBAction)saveClicked:(id)sender
{
    NSString *sharingWords = @"Test sharing";
    UIImage *sharingImg = [self.chosenImage image];
    
    NSArray *activityItems;
    if (sharingImg != nil) {
        activityItems = @[sharingWords, sharingImg];
    } else {
        activityItems = @[sharingWords];
    }
    UIActivityViewController *activityController =
    [[UIActivityViewController alloc] initWithActivityItems:activityItems  applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
    [activityController release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
//    NSString *string=[NSString stringWithFormat:@"%@ is clicked",[actionSheet buttonTitleAtIndex:buttonIndex]];
    switch (buttonIndex) {
        case FROM_CAMERA:
            [self chooseFromCamera];
            break;
        case FROM_ALBUM:
            [self chooseFromAlbum];
            break;
        default:
            break;
    }
}

- (IBAction)eyesClicked:(id)sender
{
    NSLog(@"eyes clicked");
}

- (IBAction)sketchClicked:(id)sender
{
    NSLog(@"sketch clicked");
}

- (IBAction)invertClicked:(id)sender
{
    NSLog(@"invert clicked");
}

- (IBAction)moreClicked:(id)sender
{
    NSLog(@"more clicked");
}

- (IBAction)revertClicked:(id)sender
{
    // confirm before reverting
    [self.chosenImage setImage:originalImg];
}

- (void)dealloc {
    // Don't release the bannerView_ if you are using ARC in your project
    [bannerView_ release];
    originalImg = nil;
    [imagePicker release];
    [_chosenImage release];
    [_toolbarScrollView release];
    [super dealloc];
}
@end
