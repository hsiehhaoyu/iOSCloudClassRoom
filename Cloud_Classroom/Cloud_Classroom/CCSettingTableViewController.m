//
//  CCSettingTableViewController.m
//  Cloud_Classroom
//
//  Created by Hao-Yu Hsieh on 2014/5/6.
//  Copyright (c) 2014年 Hao-Yu Hsieh. All rights reserved.
//

#import "CCSettingTableViewController.h"
#import "CCConfiguration.h"
#import "CCLoginViewController.h"
#import "CCMiscHelper.h"

@interface CCSettingTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *serverURLTextField;

@property (weak, nonatomic) IBOutlet UITextField *serverPortTextField;

@end

@implementation CCSettingTableViewController


//Let keyboard disappear when user click enter
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Load server info from standardUserDefaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *serverURL = [userDefaults objectForKey:SERVER_URL];
    NSInteger serverPort = [userDefaults integerForKey:SERVER_PORT];

    if(!serverURL){ //cannot find the field 
        serverURL = DEFAULT_SERVER_URL;
        serverPort = DEFAULT_SERVER_PORT;
        NSLog(@"Error! Couldn't find the server info in standardUserDefaults in setting page. It should be generated when in login page");
    }
    
    self.serverURLTextField.delegate = self;
    self.serverPortTextField.delegate = self;
    self.serverURLTextField.text = serverURL;
    self.serverPortTextField.text = [NSString stringWithFormat:@"%d",(int)serverPort];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillDisappear:(BOOL)animated{
    
    NSInteger serverPort = [self.serverPortTextField.text integerValue];
    
    if([CCMiscHelper isStringEmpty:self.serverPortTextField.text] || serverPort < ALLOWED_MIN_PORT_NUM || serverPort > ALLOWED_MAX_PORT_NUM){
    
        [CCMiscHelper showAlertWithTitle:@"Invalid port number"
                              andMessage:[NSString stringWithFormat:@"Allowed port number is from %d to %d. The changes will not be saved.", ALLOWED_MIN_PORT_NUM, ALLOWED_MAX_PORT_NUM]];
        
    
    }else if([CCMiscHelper isStringEmpty:self.serverURLTextField.text] || ![NSURL URLWithString:self.serverURLTextField.text]){
        
        [CCMiscHelper showAlertWithTitle:@"Invalid URL/IP"
                              andMessage:@"URL/IP format is invalid. The changes will not be saved."];
        
    }else{
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:self.serverURLTextField.text forKey:SERVER_URL];
        [userDefaults setInteger:serverPort forKey:SERVER_PORT];
        [userDefaults synchronize];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
//}



/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
