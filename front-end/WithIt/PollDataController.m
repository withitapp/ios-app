//
//  PollDataController.m
//  WithIt
//
//  Created by Francesca Nannizzi on 12/19/13.
//  Copyright (c) 2013 WithIt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataController.h"
#import "PollDataController.h"
#import "AppDelegate.h"
#import "Poll.h"
#import "User.h"
#import <FacebookSDK/FBSessionTokenCachingStrategy.h>

#define serverURL [NSURL URLWithString:@"http://api.withitapp.com"]
#define dummyURL [NSURL URLWithString:@"http://gist.githubusercontent.com/oguzbilgic/9283570/raw/9e63c13790a74ffc51c5ea4edb9004d7e5246622/polls.json"]
#define membershipURL [NSURL URLWithString:@"http://withitapp.com:3000/memberships"]
#define dummyPostURL [NSURL URLWithString:@"http://withitapp.com:3000/auth"]
#define userDataURL [NSURL URLWithString:@"http://withitapp.com:3000/users"]
#define pollDataURL [NSURL URLWithString:@"http://withitapp.com:3000/polls"]
#define userDataPopURL [NSURL URLWithString:@"http://withitapp.com:3000/users?id=1"]

//set to 1 for debug
static const NSInteger EXPIRE_TIME_DEBUG = 0;

@interface PollDataController () <NSURLConnectionDelegate>
- (id)init;
@end

@implementation PollDataController

// Ensure that only instance of PollDataController is ever instantiated
+ (PollDataController*)sharedInstance
{
    static PollDataController *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[PollDataController alloc] init];
    });
    return _sharedInstance;
}

- (void)loadData
{
    //at start of application post the user's facebook session token to database
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [[FBSessionTokenCachingStrategy alloc] init];
    FBAccessTokenData * fbtoken = [tokenCachingStrategy fetchFBAccessTokenData];
    self.userDataController = [UserDataController sharedInstance];
    [self postUser:fbtoken.accessToken fbID:appDelegate.userID];
    //get all the polls for the user
    [self retrievePolls];
}

- (void)initializeDefaultDataList {
    
    NSMutableArray *pollsList = [[NSMutableArray alloc] init];
    self.masterPollsList = pollsList;
    
    NSMutableArray *createdPollsList = [[NSMutableArray alloc] init];
    self.masterPollsCreatedList = createdPollsList;
    
    NSMutableArray *expiredPollsList = [[NSMutableArray alloc] init];
    self.masterPollsExpiredList = expiredPollsList;
}

- (void)setMasterPollsList:(NSMutableArray *)newList {
    if (_masterPollsList != newList) {
        _masterPollsList = [newList mutableCopy];
    }
}

- (void)setMasterPollsCreatedList:(NSMutableArray *)newList {
    if (_masterPollsCreatedList != newList) {
        _masterPollsCreatedList = [newList mutableCopy];
    }
}

- (void)setMasterPollsExpiredList:(NSMutableArray *)newList {
    if (_masterPollsExpiredList != newList) {
        _masterPollsExpiredList = [newList mutableCopy];
    }
}

- (id)init {
    semaphore = dispatch_semaphore_create(0);
    
    [self initializeDefaultDataList];

    return self;
}

- (Poll *)objectInListAtIndex:(NSUInteger)theIndex {
    return [self.masterPollsList objectAtIndex:theIndex];
}

- (void)addPollWithPoll:(Poll *)poll {
    [self.masterPollsList addObject:poll];
}

- (void)deleteObjectInListAtIndex:(NSUInteger)theIndex{
    if(theIndex < [self.masterPollsList count]){
        [self.masterPollsList removeObjectAtIndex:theIndex];
    }
}

- (Poll *)objectInCreatedListAtIndex:(NSUInteger)theIndex {
    return [self.masterPollsCreatedList objectAtIndex:theIndex];
}

- (void)addPollCreatedWithPoll:(Poll *)poll {
    Poll *responsePoll = [self postPoll:poll];
    [self.masterPollsCreatedList addObject:responsePoll];
}

- (void)deleteObjectInCreatedListAtIndex:(NSUInteger)theIndex {
    if(theIndex < [self.masterPollsCreatedList count]){
        [self.masterPollsCreatedList removeObjectAtIndex:theIndex];
    }
}

- (Poll *)objectInExpiredListAtIndex:(NSUInteger)theIndex {
    return [self.masterPollsExpiredList objectAtIndex:theIndex];
}

- (void)addPollExpiredWithPoll:(Poll *)poll {
    [self.masterPollsExpiredList addObject:poll];
}

- (void)deleteObjectInExpiredListAtIndex:(NSUInteger)theIndex {
    if(theIndex < [self.masterPollsExpiredList count]){
        [self.masterPollsExpiredList removeObjectAtIndex:theIndex];
    }
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
    NSURLRequest *newRequest = request;
    
    if (redirectResponse)
    {
        newRequest = nil;
    }
    return newRequest;
}

-(NSDictionary*) makeServerRequestWithRequest:(NSURLRequest *)request
{
    __block NSDictionary *dataDictionary;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSHTTPURLResponse *httpResponse = nil;
                               if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                   httpResponse = (NSHTTPURLResponse *) response;
                               }
                               
                               // NSURLConnection's completionHandler is called on the background thread.
                               // Prepare a block to show an alert on the main thread:
                               __block NSString *message = @"";
                               void (^showAlert)(void) = ^{
                                   [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                       [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                   }];
                               };
                               
                               // Check for error or non-OK statusCode:
                               if (error || httpResponse.statusCode != 200) {
                                   message = @"Error fetching data.";
                                   NSLog(@"URL error: %@", error);
                                   showAlert();
                                   // we should handle the error here
                                   dispatch_semaphore_signal(semaphore);
                                   return;
                               }
                               
                               // Get user data including polls
                               NSError *dataError;
                               //NSDictionary *dataDictionary;
                               @try{
                                    dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&dataError];
                               } @catch (NSException *NSInvalidArgumentException){
                                   NSLog(@"Got invalid data: %@", NSInvalidArgumentException);
                               }
                               if(dataError){
                                   NSLog(@"Error loading data JSON: %@", [dataError localizedDescription]);
                               }
                
                               dispatch_semaphore_signal(semaphore);
                           }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //JSON data returned from server
    return dataDictionary;
}

- (void)postUser:(NSString *)fbToken fbID:(NSString *)fbID
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:dummyPostURL];
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"fb_id=%@&fb_token=%@",fbID,fbToken];
    NSData *requestBodyData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBodyData];
    NSDictionary *users = [self makeServerRequestWithRequest:request];
    
    User *user;
    
    // Parse user data
    user = [[User alloc] init];
    user.ID = users[@"id"];
    user.created_at = users[@"created_at"];
    user.updated_at = users[@"updated_at"];
    user.username = users[@"username"];
    user.email = users[@"email"];
    user.first_name = users[@"first_name"];
    user.last_name = users[@"last_name"];
    user.fb_id = users[@"fb_id"];
    user.fb_token = users[@"fb_token"];
    user.fb_synced_at = users[@"fb_synced_at"];
    
    appDelegate.ID = user.ID;
    
    //retrieves friends from database
    [self.userDataController loadData];
}

- (Poll *)postPoll:(Poll *)poll
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'SS'Z'"];
    NSString *endDate = [dateFormatter stringFromDate:poll.endDate];
    NSString *createDate = [dateFormatter stringFromDate:poll.createDate];
    NSString *updateDate = [dateFormatter stringFromDate:poll.updatedAt];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pollDataURL];
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"created_at=%@&updated_at=%@&title=%@&description=%@&user_id=%@&ends_at=%@",createDate, updateDate, poll.title, poll.description, poll.creatorID, endDate];
    NSData *requestBodyData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBodyData];
    NSDictionary *pollFeedback = [[NSDictionary alloc] init];
    pollFeedback = [self makeServerRequestWithRequest:request];
    
    if(pollFeedback!=nil)
        poll.pollID = pollFeedback[@"id"]; //assign ID to poll
    
    //post memberships of members in poll
    for(NSNumber *n in poll.members){
        if([appDelegate.ID isEqualToNumber:n])
            [self.userDataController postMembership:poll user:n Response:@"true"];
        else
            [self.userDataController postMembership:poll user:n Response:@"false"];}
    
    return poll;
}

- (void)updatePoll:(Poll *)poll
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'SS'Z'"];
    NSString *endDate = [dateFormatter stringFromDate:poll.endDate];
    NSString *createDate = [dateFormatter stringFromDate:poll.createDate];
    NSString *updateDate = [dateFormatter stringFromDate:poll.updatedAt];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pollDataURL];
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"id=%@&created_at=%@&updated_at=%@&title=%@&description=%@&user_id=%@&ends_at=%@", poll.pollID,createDate, updateDate, poll.title, poll.description, poll.creatorID, endDate];
    NSData *requestBodyData = [postString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBodyData];
    NSDictionary *pollFeedback = [[NSDictionary alloc] init];
    pollFeedback = [self makeServerRequestWithRequest:request];
    if(pollFeedback!=nil)
        poll.pollID = pollFeedback[@"id"];
    
}

- (void)deletePoll:(Poll *)poll
{
    NSString *s = [NSString stringWithFormat:@"http://withitapp.com:3000/polls?id=%@", poll.pollID];
   
    // Create the request with an appropriate URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s]];
    [request setHTTPMethod:@"DELETE"];
    
    
    NSDictionary *pollFeedback = [[NSDictionary alloc] init];
    pollFeedback = [self makeServerRequestWithRequest:request];
    
    
    if(pollFeedback!=nil){
        for(NSNumber *n in poll.memberships){
            [self.userDataController deleteMembership:n];
        }
    }
   
}

// Retrieve poll data from the server
- (void)retrievePolls
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSString *s = [NSString stringWithFormat:@"http://withitapp.com:3000/mypolls?user_id=%@", appDelegate.ID];
    
    // Create the request with an appropriate URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:s]];
    
    [request setHTTPMethod:@"GET"];
    // Dispatch the request and save the returned data
    NSDictionary *polls = [self makeServerRequestWithRequest:request];
    NSNumber *creatorID = ((AppDelegate *)[UIApplication sharedApplication].delegate).ID;
    NSMutableArray *updatePollsList = [[NSMutableArray alloc] init];
    Poll *poll;
    
    for(NSDictionary *thePoll in polls){
        poll = [[Poll alloc] init];
        poll.pollID = thePoll[@"id"];
        poll.createDate = thePoll[@"created_at"];
        poll.updatedAt = thePoll[@"updated_at"];
        poll.title = thePoll[@"title"];
        poll.description = thePoll[@"description"];
        poll.creatorID = thePoll[@"user_id"];
        poll.endDate = [self convertJSONDate:thePoll[@"ends_at"]];
       
        [updatePollsList addObject:poll];
    }
    if([updatePollsList count]>0 && updatePollsList!=nil){
        [self.masterPollsCreatedList removeAllObjects];
        [self.masterPollsList removeAllObjects];
        [self.masterPollsExpiredList removeAllObjects];
    for( poll in updatePollsList){
        //check if the poll is new or not
        if([creatorID isEqualToNumber:poll.creatorID]){
            // NSLog(@"Poll %@ added to created list.", poll.title);
            [self.masterPollsCreatedList addObject:poll];
        }
        else{
            [self.masterPollsList addObject:poll];
        }
    }}
    [updatePollsList removeAllObjects];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    //NSLog(@"Got response in delegate method");
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    //NSLog(@"Got recieveData");
    [_responseData appendData:data];
}

- (NSDate *) convertJSONDate:(NSString *)dateString {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	NSDate *result = [dateFormatter dateFromString:dateString];
    //NSLog(@"Date from string is: %@", dateString );
	return result;
}

-(void) determineExpiredPoll
{
    NSDate *currentDate=[NSDate date];
    NSDate *pollEndDate;


    for(int d = 0; d < [_masterPollsList count];d++)
    {
        pollEndDate = [self objectInListAtIndex:d].endDate;
        if (EXPIRE_TIME_DEBUG == 1){
           // NSLog(@"Poll %d end time is %@ ",d, pollEndDate);
        }
        if([currentDate compare:pollEndDate] == NSOrderedDescending)
        {
           // NSLog(@"Expired Poll!!");
            [self addPollExpiredWithPoll:[self objectInListAtIndex:d]];
            [self deleteObjectInListAtIndex:d];
            d--;
        }
    }
    
    for(int d = 0; d < [_masterPollsCreatedList count];d++)
    {
        pollEndDate = [self objectInCreatedListAtIndex:d].endDate;
       // NSLog(@"Poll %d end time is %@ ",d, pollEndDate);
        if([currentDate compare:pollEndDate] == NSOrderedDescending)
        {
            [self addPollExpiredWithPoll:[self objectInCreatedListAtIndex:d]];
            [self deleteObjectInCreatedListAtIndex:d];
            d--;
        }
    }
}

//count the number of members attending poll
- (NSUInteger)countAttending:(Poll *)poll{
    NSUInteger attending = 0; // owner of poll is attending by default
    Membership *m1;
    
    for(Membership *m in poll.memberships){
        m1 = [poll.memberships objectForKeyedSubscript:m];
        
        if([m1.response isEqual: @(YES)]){
            attending++;
        }
        
    }
    return attending;
    
}

//count the number of members not attending to the poll
- (NSUInteger)countNotAttending:(Poll *)poll{
    NSUInteger notAttending = 0;
    Membership *m1;
    
    for(Membership *m in poll.memberships){
        m1 = [poll.memberships objectForKeyedSubscript:m];
        
        if([m1.response isEqual: @(YES)])
        {
            
        }
        else
        {
            notAttending++;
        }
        
    }
    return notAttending;
}

+ (NSString*)differenceBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSString* returnStr;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
  /*  [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
   */
    if ([fromDateTime compare:toDateTime] == NSOrderedDescending)
    {
        NSDateComponents *difference = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit) fromDate:toDateTime toDate:fromDateTime options:0];
        
        if ([difference year] > 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired %lu years ago",(long)[difference year]];
        }
        else if ([difference year] == 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired 1 year ago"];
        }
        
        else if ([difference month] > 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired %lu months ago",(long)[difference month]];
        }
        else if ([difference month] == 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired 1 month ago"];
        }
        
        else if ([difference day] > 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired %lu days ago",(long)[difference day]];
        }
        else if ([difference day] == 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired 1 day ago"];
        }
        
        else if ([difference hour] > 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired %lu hours ago",(long)[difference hour]];
        }
        else if ([difference hour] == 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired 1 hour ago"];
        }
        
        else if ([difference minute] > 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired %lu minutes ago",(long)[difference minute]];
        }
        else if ([difference minute] == 1)
        {
            returnStr = [[NSString alloc] initWithFormat:@"Expired 1 minute ago"];
        }
        else
        {
            returnStr = [[NSString alloc] initWithFormat:@"Happening now"];
        }
        
        return returnStr;
        
    }
   /* else if ([fromDate compare:toDate] != NSOrderedAscending) {
        return [[NSString alloc] initWithFormat:@"Happening now"];
        
    }*/
    
    NSDateComponents *difference = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit) fromDate:fromDateTime toDate:toDateTime options:0];
    
    if ([difference year] > 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In %lu years",(long)[difference year]];
    }
    else if ([difference year] == 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In 1 year"];
    }
    
    else if ([difference month] > 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In %lu months",(long)[difference month]];
    }
    else if ([difference month] == 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In 1 month"];
    }
    
    else if ([difference day] > 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In %lu days",(long)[difference day]];
    }
    else if ([difference day] == 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In 1 day"];
    }
    
    else if ([difference hour] > 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In %lu hours",(long)[difference hour]];
    }
    else if ([difference hour] == 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In 1 hour"];
    }
    
    else if ([difference minute] > 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In %lu minutes",(long)[difference minute]];
    }
    else if ([difference minute] == 1)
    {
        returnStr = [[NSString alloc] initWithFormat:@"In 1 minute"];
    }
    else
    {
        returnStr = [[NSString alloc] initWithFormat:@"Happening now"];
    }
    
    return returnStr;
}



@end
