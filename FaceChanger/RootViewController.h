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

@interface RootViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    UIImagePickerController *imagePicker;
}

@property (retain, nonatomic) IBOutlet UIImageView *chosenImage;
@property (retain, nonatomic) IBOutlet UILabel *stateLabel;

- (IBAction)unwindToRootview:(UIStoryboardSegue *) segue;

@end
