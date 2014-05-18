//
//  ImageViewController.h
//  FaceChanger
//
//  Created by Kiyan Liu on 5/13/14.
//  Copyright (c) 2014 FreeTymeKiyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"
#import "GPUImage.h"
#import "FaceppAPI.h"
#import "MBProgressHUD.h"
#import <CoreImage/CoreImage.h>

@interface ImageViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *processBtn;
@property (retain, nonatomic) IBOutlet UIImageView *processedImg;
@property (retain, nonatomic) MBProgressHUD *progressView;

@property (retain, nonatomic) UIImage *img;
@property (retain, nonatomic) NSString *whichBtn;
@property (retain, nonatomic) UIBezierPath *cropPath;

- (IBAction)cropClicked:(id)sender;
- (IBAction)invertClicked:(id)sender;
- (IBAction)sketchClicked:(id)sender;

@end
