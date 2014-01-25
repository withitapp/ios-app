//
//  CreatePollViewController.m
//  WithIt
//
//  Created by Francesca Nannizzi on 12/19/13.
//  Copyright (c) 2013 WithIt. All rights reserved.
//

#import "CreatePollViewController.h"
#import "PublishPollViewController.h"
#import "AppDelegate.h"

@interface CreatePollViewController ()

@end

@implementation CreatePollViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}


//when clicking the return button in the keybaord
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSLog(@"Keyboard Return Working");
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad
{
    NSLog(@"Loading CreatePoll view.");
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    self.view.backgroundColor = [UIColor whiteColor];
    //Cancel Button
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(Cancel)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    //Next Page Button
    UIBarButtonItem *nextCreatePollButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(goPublishNewPoll)];
    self.navigationItem.rightBarButtonItem = nextCreatePollButton;
    
    [self.navigationController.navigationItem setTitle:@"WithIt"];
    
    //Add detailsView to the main view
    self.detailsView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, appDelegate.screenWidth, appDelegate.screenHeight)];
    [self.view addSubview:self.detailsView];
    
    //Add input text field for Poll Title
     NSLog(@"Before create Poll Title Text Field.");
    self.PollTitleTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 40, 150, 30)];
    self.PollTitleTextField.placeholder = @"Poll Title";
    self.PollTitleTextField.backgroundColor=[UIColor whiteColor];
    self.PollTitleTextField.textColor = [UIColor blackColor];
    self.PollTitleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.PollTitleTextField.returnKeyType = UIReturnKeyDone;
    self.PollTitleTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.PollTitleTextField.tag= 2;
    //self.PollTitleTextField.textAlignment = UITextAlignmentLeft;
    self.PollTitleTextField.delegate = self;
    [self.detailsView addSubview:self.PollTitleTextField];
      NSLog(@"Done create Poll Title Text Field.");
    
    
    //Add input text field for Poll Description
    NSLog(@"Before create Poll Description Text Field.");
    self.PollDescriptionTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 80, (appDelegate.screenWidth - 40), 30)];
    self.PollDescriptionTextField.placeholder = @"Poll Description";
    self.PollDescriptionTextField.backgroundColor=[UIColor whiteColor];
    self.PollDescriptionTextField.textColor = [UIColor blackColor];
    self.PollDescriptionTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.PollDescriptionTextField.returnKeyType = UIReturnKeyDone;
    self.PollDescriptionTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.PollDescriptionTextField.tag= 2;
    //self.PollDescriptionTextField.textAlignment = UITextAlignmentLeft;
    self.PollDescriptionTextField.delegate = self;
    [self.detailsView addSubview:self.PollDescriptionTextField];
    NSLog(@"Done create Poll Description Text Field.");
    
    //Add date selection label for Poll Expiration
    self.PollExpirationDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 100, 30)];
    self.PollExpirationDateLabel.textColor = [UIColor lightGrayColor];
    self.PollExpirationDateLabel.backgroundColor = [UIColor whiteColor];
    self.PollExpirationDateLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:(16.0)];
    [self.detailsView addSubview:self.PollExpirationDateLabel];
    self.PollExpirationDateLabel.text = [NSString stringWithFormat: @"Poll End At : "];

    
    //Add date selection datepicker for Poll Expiration
    self.PollExpirationDatePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(10, 155, (appDelegate.screenWidth - 20), 60)];
    self.PollExpirationDatePicker.datePickerMode = UIDatePickerModeDate;
    self.PollExpirationDatePicker.date = [NSDate date];
    //  [self.PollExpirationDatePicker addTarget:self
    //                action:@selector(changeDateInLabel:)
    //    forControlEvents:UIControlEventValueChanged];
    [self.detailsView addSubview:self.PollExpirationDatePicker];
    // [self.PollExpirationDatePicker release];
    
    
}

- (IBAction)Cancel
{
    NSLog(@"Cancelling poll creation.");
    [self.navigationController popViewControllerAnimated:YES];
}



//action for PollCreateButton pressed - going to the next create poll page
- (IBAction)goPublishNewPoll
{
    PublishPollViewController *publishPollViewController = [[PublishPollViewController alloc] init];
    [self.navigationController pushViewController:publishPollViewController animated:YES];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end