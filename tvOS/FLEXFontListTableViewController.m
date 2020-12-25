
#import "FLEXFontListTableViewController.h"
#import "NSObject+FLEX_Reflection.h"
@interface FLEXFontListTableViewController ()
@property (nonatomic) NSArray *fonts;
@end

@implementation FLEXFontListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createAvailableFonts];
    //self.fonts = [self allFonts];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseID"];
   
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    if ([self darkMode]){
           self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
       } else {
           self.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
       }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (void)createAvailableFonts {
    NSMutableArray<NSString *> *unsortedFontsArray = [NSMutableArray new];
    for (NSString *eachFontFamily in UIFont.familyNames) {
        for (NSString *eachFontName in [UIFont fontNamesForFamilyName:eachFontFamily]) {
            [unsortedFontsArray addObject:eachFontName];
        }
    }
    self.fonts = [NSMutableArray arrayWithArray:[unsortedFontsArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
}


- (NSArray *)allFonts
{
    NSMutableArray *allFontArray = [[NSMutableArray alloc] init];
    NSArray *fontNames = [UIFont familyNames]; //all font family names
    for (NSString *fontFamily in fontNames) //cycle through
    {
        [allFontArray addObjectsFromArray:[UIFont fontNamesForFamilyName:fontFamily]]; //add all font names from the family names to the array
    }
    
    NSArray *sortedArray = [allFontArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]; //sort alphabetically
    
    return sortedArray;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self fonts].count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseID" forIndexPath:indexPath];
    

    NSString *currentFont = [self fonts][indexPath.row];
    cell.textLabel.text = currentFont;
    cell.textLabel.font = [UIFont fontWithName:currentFont size:45];
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *currentFont = [self fonts][indexPath.row];
    if (self.itemSelectedBlock){
        self.itemSelectedBlock(currentFont);
    }
}



@end
