//
//  RootViewController.h
//  FaceChanger
//
//  Created by Kiyan Liu on 5/11/14.
//  Copyright (c) 2014 FreeTymeKiyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "ImageViewController.h"
#import "GADBannerView.h"

@interface RootViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIScrollViewDelegate> {
    UIImagePickerController *imagePicker;
    GADBannerView *bannerView_;
}
@property (retain, nonatomic) IBOutlet UIScrollView *toolbarScrollView;
@property (retain, nonatomic) IBOutlet UIImageView *chosenImage;
@property (retain, nonatomic) UIImage *originalImg;

- (IBAction)unwindToRootview:(UIStoryboardSegue *) segue;

- (IBAction)addClicked:(id)sender;
- (IBAction)saveClicked:(id)sender;
- (IBAction)eyesClicked:(id)sender;
- (IBAction)sketchClicked:(id)sender;
- (IBAction)invertClicked:(id)sender;
- (IBAction)moreClicked:(id)sender;
- (IBAction)revertClicked:(id)sender;

@end
