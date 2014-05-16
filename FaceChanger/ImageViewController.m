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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (sender != self.doneButton) return; //不是点击done按钮
    self.img = [self.processedImg image];
}

- (IBAction)multipleClicked:(id)sender
{
    NSLog(@"multiple clicked");
    
//    GPUImageSketchFilter *stillImageFilter2 = [[GPUImageSketchFilter alloc] init];
    GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
//    filter.brightness= -1.0;
    UIImage *quickFilteredImage = [filter imageByFilteringImage:[self.processedImg image]];
//    UIImage *quickFilteredImage = [self.processedImg image];
    
    UIImage *inputImage = self.img;
    
    GPUImagePicture *picture1 = [[GPUImagePicture alloc] initWithImage:quickFilteredImage];
    GPUImagePicture *picture2 = [[GPUImagePicture alloc] initWithImage:inputImage];
    
    GPUImageAlphaBlendFilter *blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    [picture1 addTarget:blendFilter];
    [blendFilter useNextFrameForImageCapture];
    [picture1 processImage];
    [picture2 addTarget:blendFilter];
    [blendFilter useNextFrameForImageCapture];
    [picture2 processImage];
    
    UIImage* blendImage = [blendFilter imageFromCurrentFramebuffer];
    [self.processedImg setImage:blendImage];
}

- (IBAction)cropClicked:(id)sender
{
    NSLog(@"crop clicked");
    UIImage *originalImg = self.img;
    
    UIImage *result = [self cropImg:originalImg];
    [self.processedImg setImage:result];
}

- (IBAction)invertClicked:(id)sender
{
    GPUImageColorInvertFilter *filter = [[GPUImageColorInvertFilter alloc] init];
    UIImage *filteredImg = [filter imageByFilteringImage:self.img];
    [self.processedImg setImage:filteredImg];
}

- (IBAction)sketchClicked:(id)sender
{
    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
    UIImage *filteredImg = [filter imageByFilteringImage:self.img];
    [self.processedImg setImage:filteredImg];
}

- (UIImage *)cropImg:(UIImage *) originalImg
{
    UIImage *result;
    // construct bezier path
    UIBezierPath *path1 = [self arrayToBezierPaths:self.leftEyePoints];
    UIBezierPath *path2 = [self arrayToBezierPaths:self.rightEyePoints];
    
    UIGraphicsBeginImageContextWithOptions(originalImg.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, NO);
    CGContextSetAllowsAntialiasing(context, NO);
//    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
//    CGContextSetLineWidth(context, 0);

    [path1 appendPath:path2]; // append path2 to path1
    [path1 addClip];
    
    [originalImg drawAtPoint:CGPointZero];

    result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
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

- (void)dealloc {
    [_doneButton release];
    [_processedImg release];
    [super dealloc];
}
@end
