//
//  CreatePollViewController.h
//  WithIt
//
//  Created by Francesca Nannizzi on 12/19/13.
//  Copyright (c) 2013 WithIt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreatePollViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) UIView *detailsView;

//For input data
@property (strong, nonatomic) UITextField *PollTitleTextField;
@property (strong, nonatomic) UITextField *PollDescriptionTextField;
@property (strong, nonatomic) UIDatePicker *PollExpirationDatePicker;

//Labels
@property (strong, nonatomic) UILabel *PollExpirationDateLabel;




@end