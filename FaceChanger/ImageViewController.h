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

@interface ImageViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (retain, nonatomic) IBOutlet UIImageView *processedImg;

@property (retain, nonatomic) UIImage *img;
@property (retain, nonatomic) NSMutableArray *leftEyePoints;
@property (retain, nonatomic) NSMutableArray *rightEyePoints;

- (IBAction)multipleClicked:(id)sender;
- (IBAction)cropClicked:(id)sender;
- (IBAction)invertClicked:(id)sender;
- (IBAction)sketchClicked:(id)sender;

@end
