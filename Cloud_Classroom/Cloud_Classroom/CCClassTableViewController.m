//
//  CCClassTableViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCClassTableViewController.h"
#import "CCMessageCenter.h"
#import "CCAppDelegate.h"
#import "CCConfiguration.h"
#import "CCClass.h"
#import "CCMiscHelper.h"
#import "CCClassTabBarController.h"

@interface CCClassTableViewController ()

@property (strong,atomic) CCMessageCenter *serverMC;

@property (strong, nonatomic) NSArray *classes;

//could be created by you or others
//Note: cannot call it "class", or it will fail silently when you use statement like [CCTableV... class]
@property (strong, nonatomic) CCClass *classToGo;

//since we use modal, so create out own navigation bar
@property (weak, nonatomic) IBOutlet UINavigationItem *classTableNavigationItem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation CCClassTableViewController

- (IBAction)refreshClassTable {

    //[self.refreshControl beginRefreshing];
    
    //start to fetch the list from server
    [self.serverMC listClassesAndOnCompletion:^(SendMessageResult sentResult,
                                                NSString *status,
                                                NSInteger numOfClasses,
                                                NSArray *classes) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            if(sentResult == SendMessageResultSucceeded){
                if([status isEqualToString:SUCCESS]){
                    
                    NSLog(@"Fetch class list succeeded. # of class: %ld, classes count: %lu",
                          numOfClasses, (unsigned long)[classes count]);
                    
                    self.classes = classes;
                    [self.tableView reloadData];
                    
                    if(numOfClasses < 1){
                        
                        [CCMiscHelper showAlertWithTitle:@"No class"
                                              andMessage:@"Currently there is no class opened."];
                        
                    }
                    
                    
                }else if([status isEqualToString:NOT_LOGIN]){
                    //no need to do things, since will be automatically logged out
                }else{
                    NSLog(@"Unknown status received when list classes");
                }
            
            }else{ //Connection problems
                
                [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
            
            }
            
            //[self.refreshControl endRefreshing];
            
        });
        
    }];

}

-(void)createClassButtonClicked{
    
    //show a dialog box
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Create class"
                          message:@"Please input class name:"
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Create",nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 0; //used to identify which alert after clicking a button
    [alert show];
    alert = nil;
    
}

//send create class message
-(void)createClassWithName:(NSString *)className{

    [self.serverMC createClassWithName:className
                          onCompletion:^(SendMessageResult sentResult, NSString *status, NSString *classID) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  if(sentResult == SendMessageResultSucceeded){
                                      if([status isEqualToString:SUCCESS]){
                                          
                                          self.classToGo = [[CCClass alloc] init];
                                          self.classToGo.className = className;
                                          self.classToGo.classID = classID;
                                          self.classToGo.instructorName = self.userID;
                                          [self performSegueWithIdentifier:@"Enter class" sender:self];
                                      
                                      }else if([status isEqualToString:NOT_LOGIN]){
                                       
                                          //no need to do things here, will be logged out automatically
                                          
                                      }else{
                                          
                                          NSString *creationFailedReason;
                                          
                                          if([status isEqualToString:NO_PERMISSION])
                                              creationFailedReason = @"You don't have permission to create a class.";
                                          else if([status isEqualToString:DUPLICATE_NAME])
                                              creationFailedReason = @"The name has been used.";
                                          else
                                              creationFailedReason = @"Unknown reason...";
                                        
                                          
                                          [CCMiscHelper showAlertWithTitle:@"Creation failed"
                                                                andMessage:creationFailedReason];
                                      
                                      }
                                      
                                  }else{
                                      [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
                                  }

                              });
    }];
    
}

//
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if(alertView.tag == 0){ //create class alert
        
        if(buttonIndex == 1){ //"Create" clicked
            [self createClassWithName:[alertView textFieldAtIndex:0].text];
        }
        
    }else{
        NSLog(@"Weired, where is this alert clicked event come from???");
    }

}

- (IBAction)logoutButtonClicked:(UIBarButtonItem *)sender {
    [self.serverMC logoutAndTriggerLogoutBlock:YES onCompletion:nil];
}


//
-(void)askForJoinClass:(CCClass *)class{

    //use different thread so it won't block the return value of shouldPerformSegue
    dispatch_queue_t queryClassInfo = dispatch_queue_create("queryClassInfo", NULL);
    dispatch_async(queryClassInfo, ^{
        
        [self.serverMC
         joinClassWithClassID:class.classID
         onCompletion:^(SendMessageResult sentResult, NSString *status,
                        NSString *classID, NSString *className) {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 if(sentResult == SendMessageResultSucceeded){
                     if([status isEqualToString:SUCCESS] || [status isEqualToString:ALREADY_IN_CLASS]){
                         
                         self.classToGo = class;
                         
                         [self performSegueWithIdentifier:@"Enter class" sender:self];
                         
                     }else if([status isEqualToString:NOT_LOGIN]){
                         
                         //no need to do things here, will be logged out automatically
                         
                     }else if ([status isEqualToString:INVALID_CLASS_ID]){
                         
                         //very likely that the class is over, so refresh the table
                         [CCMiscHelper showAlertWithTitle:@"Can't join the class"
                                               andMessage:@"Sorry, the class is over."];
                         [self refreshClassTable];
                         
                     }else if([status isEqualToString:NO_PERMISSION] || [status isEqualToString:DENIED]){
                         
                         [CCMiscHelper showAlertWithTitle:@"Can't join the class"
                                               andMessage:@"Sorry, you don't have permission to join."];
                     
                     }else{
                         NSLog(@"Unknown status received when asking to join the class");
                     }
                     
                 }else{
                     
                     [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
                     
                 }
                 
             });
             
        }];
        
    });
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    
    if([identifier isEqualToString:@"Enter class"]){
        if (sender == self) { //we perform segue manually
            return YES;
        }else{ //user clicked at a table cell
            
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            [self askForJoinClass:self.classes[indexPath.row]];
            
        }
    }
    return NO;

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"Enter class"]){
        
        if([segue.destinationViewController isKindOfClass:[CCClassTabBarController class]]){
            
            CCClassTabBarController *classTBC = (CCClassTabBarController *)segue.destinationViewController;
            classTBC.userID = self.userID;
            classTBC.classOnGoing = self.classToGo;
            
        }else{
            NSLog(@"Not CCClassTabBarController, it's : %@", [[segue.destinationViewController class] description]);
        }
    }else{
        NSLog(@"Not Enter class segue, it's: %@", segue.identifier);
    }
}

-(void)viewDidAppear:(BOOL)animated{

    [self refreshClassTable];

}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Get the MessageCenter in AppDelegate 
    CCAppDelegate *appDelegate = (CCAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.serverMC = appDelegate.serverMessageCenter;

    //Since we need more than one right button, so do it programatically
    //refresh button (although you can use pull down refresh)
    UIBarButtonItem *refreshBarButton = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                         target:self
                                         action:@selector(refreshClassTable)];
    UIBarButtonItem *addClassBarButton = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                         target:self
                                         action:@selector(createClassButtonClicked)];
    
    self.classTableNavigationItem.rightBarButtonItems = @[addClassBarButton, refreshBarButton];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.classes = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.classes count];
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Class table cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    CCClass *class = self.classes[indexPath.row];
    
    cell.textLabel.text = class.className;
    cell.detailTextLabel.text = class.instructorName;
    
    return cell;
    
}






/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
