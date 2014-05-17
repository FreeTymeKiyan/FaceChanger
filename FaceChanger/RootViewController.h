//
//  RootViewController.h
//  FaceChanger
//
//  Created by Kiyan Liu on 5/11/14.
//  Copyright (c) 2014 FreeTymeKiyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "FaceppAPI.h"
#import "ImageViewController.h"
#import <Social/Social.h>

@interface RootViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate> {
    UIImagePickerController *imagePicker;
}

@property (retain, nonatomic) IBOutlet UIImageView *chosenImage;
@property (retain, nonatomic) NSMutableArray *leftEyePoints;
@property (retain, nonatomic) NSMutableArray *rightEyePoints;

- (IBAction)unwindToRootview:(UIStoryboardSegue *) segue;

- (IBAction)addClicked:(id)sender;
- (IBAction)saveClicked:(id)sender;
- (IBAction)eyesClicked:(id)sender;
- (IBAction)sketchClicked:(id)sender;
- (IBAction)invertClicked:(id)sender;
- (IBAction)moreClicked:(id)sender;

@end
