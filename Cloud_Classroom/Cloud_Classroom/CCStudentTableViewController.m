//
//  CCStudentTableViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/4/24.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCStudentTableViewController.h"
#import "CCClassTabBarController.h"
#import "CCMessage.h"
#import "CCConfiguration.h"
#import "CCMiscHelper.h"
#import "CCClassHelper.h"
#import "CCAppDelegate.h"
#import "UIBarButtonItem+Image.h"

@interface CCStudentTableViewController ()

@property (weak,atomic) CCMessageCenter *serverMC;

@property (strong, nonatomic) NSArray *studentNames;

@property (weak, nonatomic) IBOutlet UILabel *labelClassName;

@property (weak, nonatomic) IBOutlet UILabel *labelInstructor;

@property (weak, nonatomic) IBOutlet UILabel *labelStudentNumber;

@property (weak, nonatomic) IBOutlet UINavigationItem *studentTableNavigationItem;

@property (weak, nonatomic) IBOutlet UITableView *tableView;



@end

@implementation CCStudentTableViewController

- (void)refreshStudentTable {
    
    //[self.refreshControl beginRefreshing];
    self.labelStudentNumber.text = @"Loading...";
    [self.serverMC
     queryClassInfoWithClassID:((CCClassTabBarController *)self.tabBarController).classOnGoing.classID
     onCompletion:^(SendMessageResult sentResult,
                    NSString *status,
                    NSString *instructorName,
                    NSInteger numOfStudents,
                    NSArray *studentNames) {
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if(sentResult == SendMessageResultSucceeded){
                 if([status isEqualToString:SUCCESS]){
                     
                     NSLog(@"fetch class list succeeded. # of class: %d, classes count: %d",
                           (int)numOfStudents,(int)[studentNames count]);
                     
                     self.studentNames = studentNames;
                     self.labelStudentNumber.text = [NSString stringWithFormat:@"%lu",(unsigned long)[studentNames count]];
                     [self.tableView reloadData];
                     
                     if(numOfStudents < 1){
                         [CCMiscHelper showAlertWithTitle:@"No student"
                                               andMessage:@"Currently there is no student in class."];
                     }
                     
                 }else if([status isEqualToString:NOT_LOGIN]){
                     //no need to do things, since will be automatically logged out
                 }else if([status isEqualToString:INVALID_CLASS_ID]){
                     
                     //A possible reason that this will occur
                     //is because this client didn't recevied
                     //class dismissed notify
                     //Go back to class list
                     [(CCClassTabBarController *)(self.tabBarController) classDismissed];
                 
                 }else{
                     
                     NSLog(@"Unknown status received when query class info");

                 }
                 
             }else{ //Connection problems
                 
                 [CCMiscHelper showConnectionFailedAlertWithSendResult:sentResult];
                 
             }
             
             //[self.refreshControl endRefreshing];
             
         });

        
    }];
}

-(void)viewDidAppear:(BOOL)animated{
    
    [self refreshStudentTable];
        
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.serverMC = ((CCClassTabBarController *)(self.tabBarController)).serverMC;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
     

    
    //Add buttons programatically
     UIBarButtonItem *refreshBarButton = [[UIBarButtonItem alloc]
                                          initWithImageOnly:[UIImage imageNamed:@"refresh24"]
                                          target:self
                                          action:@selector(refreshStudentTable)];
        
    self.studentTableNavigationItem.rightBarButtonItems = @[refreshBarButton];
    self.studentTableNavigationItem.leftBarButtonItems = [CCClassHelper getConstClassLeftBarButtonItemsWithSender:self];
    
    
    self.labelClassName.text = ((CCClassTabBarController *)self.tabBarController).classOnGoing.className;
    self.labelInstructor.text = ((CCClassTabBarController *)self.tabBarController).classOnGoing.instructorName;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.studentNames = nil;
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
    return [self.studentNames count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    if (section == 0){
        return @"Student list";
    }else{
        return @"";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Student table cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *studnetName = self.studentNames[indexPath.row];
    
    cell.textLabel.text = studnetName;
    
    
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
