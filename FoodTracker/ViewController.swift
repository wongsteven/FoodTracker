//
//  ViewController.swift
//  FoodTracker
//
//  Created by steven wong on 8/17/15.
//  Copyright (c) 2015 steven.w. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    /* 
    UISearchBarDelegate - Changes made to search bar. Call backs or functions called in VC. ie. typing in the moment, end typing, cancel, etc.
    UISearchControllerDelegate - This is going to give us access to functions.
    UISearchResultsUpdating - What are we doing with our search results. 
    */
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    let kAppId = "3bf6cb98"
    let kAppKey = "2a65d108977ab1acbd9b5e90af22cb5f"
    
    //  New to iOS8 that can only be added programatically and not through XCode
    var searchController: UISearchController!

    var suggestedSearchFoods:[String] = []
    var filteredSuggestedSearchFoods:[String] = []
    
    var scopeButtonTitles = ["Recommended", "Search Results", "Saved"]
    
    //  Save json response as a property and run it into the data controller
    //  Property to store json response
    var jsonResponse:NSDictionary!
    
    //  Array is set up to store tuple from the data controller
    var apiSearchForFoods:[(name: String, idValue: String)] = []
    
    var favoritedUSDAItems:[USDAItem] = []
    var filteredFavoritedUSDAItems:[USDAItem] = []
    
    //  Set up instance of dataController
    var dataController = DataController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Initialize instance
        self.searchController = UISearchController(searchResultsController: nil)
        
        //  Set up property for UISearchResultsUpdating
        self.searchController.searchResultsUpdater = self
        
        self.searchController.dimsBackgroundDuringPresentation = false
        
        //  Do not want to hide the nav bar
        self.searchController.hidesNavigationBarDuringPresentation = false
        
        //  Set up searchbar. Search bar is fine except it doesn't know how high it should be.
        self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0)
        
        //  Tell searchbar where it should go inside VC
        self.tableView.tableHeaderView = self.searchController.searchBar
        
        //  This will display the scope button titles
        self.searchController.searchBar.scopeButtonTitles = scopeButtonTitles
        
        //  Access to callbacks - begins editing, ends editing, etc.
        self.searchController.searchBar.delegate = self
        
        //  SearchResultsController is presented in the current VC
        self.definesPresentationContext = true
        
        self.suggestedSearchFoods = ["apple", "bagel", "banana", "beer", "bread", "carrots", "cheddar cheese", "chicken breast", "chili with beans", "chocolate chip cookie", "coffee", "cola", "corn", "egg", "graham cracker", "granola bar", "green beans", "ground beef patty", "hot dog", "ice cream", "jelly doughnut", "ketchup", "milk", "mixed nuts", "mustard", "oatmeal", "orange juice", "peanut butter", "pizza", "pork chop", "potato", "potato chips", "pretzels", "raisins", "ranch salad dressing", "red wine", "rice", "salsa", "shrimp", "spaghetti", "spaghetti sauce", "tuna", "white wine", "yellow cake"]
        
        //  This VC is now listening and anytime we fire off that message from DataController, a cunction inside of the VC usdaItemDidComplete will occur.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "usdaItemDidComplete:", name: kUSDAItemCompleted, object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toDetailVCSegue" {
            if sender != nil {
                var detailVC = segue.destinationViewController as DetailViewController
                detailVC.usdaItem = sender as? USDAItem
            }
        }
    }
    
    //  There's one more thing we need to do in the main viewController and the detailViewController before we are ready to start testing. NSNotificationCenter isn't managed by ARC (Automatic Reference Counting).
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //  Display information on tableView
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        
        var foodName : String
        
        //  Getting current index that the scope button is on
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        if selectedScopeButtonIndex == 0 {
            if self.searchController.active && self.searchController.searchBar.text != "" {
                foodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                foodName = suggestedSearchFoods[indexPath.row]
            }
        }
        else if selectedScopeButtonIndex == 1 {
            foodName = apiSearchForFoods[indexPath.row].name
        }
        else {
            if self.searchController.active && self.searchController.searchBar.text != "" {
                foodName = self.filteredFavoritedUSDAItems[indexPath.row].name
            }
            else {
                foodName = self.favoritedUSDAItems[indexPath.row].name
            }
        }
        cell.textLabel?.text = foodName
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //  If we're currently searching, we use filteredSuggestedSearchFoods and if we do not click into the search bar, then use suggestedSearchFoods (all).
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            if self.searchController.active && self.searchController.searchBar.text != "" {
                return self.filteredSuggestedSearchFoods.count
            }
            else {
                return self.suggestedSearchFoods.count
            }
        }
        else if selectedScopeButtonIndex == 1 {
            return self.apiSearchForFoods.count
        }
        else {
            if self.searchController.active && self.searchController.searchBar.text != "" {
                return self.filteredFavoritedUSDAItems.count
            }
            else {
                return self.favoritedUSDAItems.count
            }
        }
    }
    //  MARK - UITableViewDelegate - Display what what happen if user selects row. We are going to set up the control flow for what would happen when the user is in each selected scope button.
    //  selectedScopeButtonIndex, searchFoodName
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        if selectedScopeButtonIndex == 0 {
            var searchFoodName:String
            if self.searchController.active {
                searchFoodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                searchFoodName = suggestedSearchFoods[indexPath.row]
            }
            self.searchController.searchBar.selectedScopeButtonIndex = 1
            makeRequest(searchFoodName)
        }
        else if selectedScopeButtonIndex == 1 {
            
            //  We want our segue to occur when we select an item from our second scope button.
            self.performSegueWithIdentifier("toDetailVCSegue", sender: nil)
            
            //  Need idValue in order to call our function saveUSDAItemForId
            let idValue = apiSearchForFoods[indexPath.row].idValue
            self.dataController.saveUSDAItemForId(idValue, json: jsonResponse)
        }
        else if selectedScopeButtonIndex == 2 {
            //  We will figure out how to pass a usda item from our main view controller to our detail view controller. However, when we create search results, the information will be coming from the data controller, so we will implement that as well.
            if self.searchController.active && self.searchController.searchBar.text != "" {
                let usdaItem = filteredFavoritedUSDAItems[indexPath.row]
                self.performSegueWithIdentifier("toDetailVCSegue", sender: usdaItem)
            }
            else {
                let usdaItem = favoritedUSDAItems[indexPath.row]
                self.performSegueWithIdentifier("toDetailVCSegue", sender: usdaItem)
            }
        }
    }
    
    // MARK - UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        //  Text inputted from searchbar
        let searchString = self.searchController.searchBar.text
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        self.filterContentForSearch(searchString, scope: selectedScopeButtonIndex)
        self.tableView.reloadData()
    }
    
    //  Helper to filter out the search. Scope bar are options below the searchbar.
    func filterContentForSearch (searchText: String, scope: Int) {
        if scope == 0 {
            self.filteredSuggestedSearchFoods = self.suggestedSearchFoods.filter({ (food : String) -> Bool in
                
                //  Does searchText exist (rangeOfString) in the array. If it is in there, then add it to the filteredSuggestedFoods.
                var foodMatch = food.lowercaseString.rangeOfString(searchText)
                
                //  !=nil = there's a match
                return foodMatch != nil
            })
        } else if scope == 2 {
            self.filteredFavoritedUSDAItems = self.favoritedUSDAItems.filter({ (item: USDAItem) -> Bool in
                var stringMatch = item.name.lowercaseString.rangeOfString(searchText)
                return stringMatch != nil
            })
        }
    }
    //  MARK - UISearchBarDelegate - This function gets called when we press search in the search bar
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //  When we press the search button, we want to change the scope button so that we're moving from 1st to 2nd scope button
        self.searchController.searchBar.selectedScopeButtonIndex = 1
        makeRequest(searchBar.text)
    }
    
    //  Allow table to update each time we select a different scope button
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        //  Make a request everytime the user presses the "Saved" button from the app
        if selectedScope == 2 {
            requestFavoritedUSDAItems()
        }
        self.tableView.reloadData()
    }
    
    //  makeRequest, searchString, url, task
    func makeRequest (searchString : String) {
        
        //  How to make a HTTP Get Request
//        let url = NSURL(string: "https://api.nutritionix.com/v1_1/search/\(searchString)?results=0%3A20&cal_min=0&cal_max=50000&fields=item_name%2Cbrand_name%2Citem_id%2Cbrand_id&appId=\(kAppId)&appKey=\(kAppKey)")
//        
//        //  NSURLSession downloads content via HTTP.
//        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
//            
//            //  This will convert data into NSString
//            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
//            println(data)
//            println(response)
//        })
//        task.resume()
        
        //  Mutable meaning it's changeable
        var request = NSMutableURLRequest(URL: NSURL(string: "https://api.nutritionix.com/v1_1/search/")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        var params = [
            "appId" : kAppId,
            "appKey" : kAppKey,
            "fields" : ["item_name", "brand_name", "keywords", "usda_fields"],
            "limit"  : "50",
            "query"  : searchString,
            "filters": ["exists":["usda_fields": true]]]
        var error: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &error)
        
        //  Specify that this is application / json. Helping out the request that this is json.
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //  Network activity indicator (loading animation in the top left hand of the screen)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        //  Create HTTP call request. Call completion handler when this is complete.
        var task = session.dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in
            
            //  Convert data into readable string - Not needed since we are using the dictionary
//            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
//            println(stringData)
            
            //  Convert string into dictionary
            var conversionError: NSError?
            var jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves, error: &conversionError) as? NSDictionary
            println(jsonDictionary)
            
            //  Error handling
            if conversionError != nil {
                println(conversionError!.localizedDescription)
                let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("Error in Parsing \(errorString)")
            }
            else {
                if jsonDictionary != nil {
                    //  store jsonDictionary to jsonResponse
                    self.jsonResponse = jsonDictionary!
                    //  Use DataController to set up apiSearchForFoods
                    self.apiSearchForFoods = DataController.jsonAsUSDAIdAndNameSearchResults(jsonDictionary!)
                    
                    //  Network activity indicator (loading animation in the top left hand of the screen)
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    //  Update on main thread as opposed to back thread.
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                }
                else {
                    let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error Could not Parse JSON \(errorString)")
                }                
            }
        })
        task.resume()
    }
    //  MARK - Setup CoreData
    func requestFavoritedUSDAItems () {
        let fetchRequest = NSFetchRequest(entityName: "USDAItem")
        let appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        let managedObjectContext = appDelegate.managedObjectContext
        self.favoritedUSDAItems = managedObjectContext?.executeFetchRequest(fetchRequest, error: nil) as [USDAItem]
    }
    
    // Mark - NSNotificationCenter - When users click on "Save", it will call the helper function and refresh the data. If there were changes made such as an additional USDAItem added, we would get the information in requestFavoritedUSDAItems() and then we would reload the table.
    func usdaItemDidComplete(notification : NSNotification) {
        println("usdaItemDidComplete in ViewController")
        requestFavoritedUSDAItems()
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        if selectedScopeButtonIndex == 2 {
            self.tableView.reloadData()
        }
    }
}
