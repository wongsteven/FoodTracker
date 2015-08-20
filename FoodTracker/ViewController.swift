//
//  ViewController.swift
//  FoodTracker
//
//  Created by steven wong on 8/17/15.
//  Copyright (c) 2015 steven.w. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    /* 
    UISearchBarDelegate - Changes made to search bar. Call backs or functions called in VC. ie. typing in the moment, end typing, cancel, etc.
    UISearchControllerDelegate - This is going to give us access to functions.
    UISearchResultsUpdating - What are we doing with our search results. 
    */
    
    @IBOutlet weak var tableView: UITableView!
    
    //  New to iOS8 that can only be added programatically and not through XCode
    var searchController: UISearchController!

    var suggestedSearchFoods:[String] = []
    
    var scopeButtonTitles = ["Recommended", "Search Results", "Saved"]
    
    var filteredSuggestedSearchFoods:[String] = []
    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Mark - UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //  Display information on tableView
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        
        var foodName : String
        if self.searchController.active {
            foodName = filteredSuggestedSearchFoods[indexPath.row]
        }
        else {
            foodName = suggestedSearchFoods[indexPath.row]
        }
        
        //  Update cell
        cell.textLabel?.text = foodName
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //  If we're currently searching, we use filteredSuggestedSearchFoods and if we do not click into the search bar, then use suggestedSearchFoods (all).
        if self.searchController.active {
            return self.filteredSuggestedSearchFoods.count
        }
        else {
            return self.suggestedSearchFoods.count
        }
    }
    
    // Mark - UISearchResultsUpdating
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        //  Text inputted from searchbar
        let searchString = self.searchController.searchBar.text
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        self.filterContentForSearch(searchString, scope: selectedScopeButtonIndex)
        self.tableView.reloadData()
    }
    
    //  Helper to filter out the search. Scope bar are options below the searchbar.
    func filterContentForSearch (searchText: String, scope: Int) {
        self.filteredSuggestedSearchFoods = self.suggestedSearchFoods.filter({ (food : String) -> Bool in
            
            //  Does searchText exist (rangeOfString) in the array. If it is in there, then add it to the filteredSuggestedFoods.
            var foodMatch = food.rangeOfString(searchText)
            
            //  !=nil = there's a match
            return foodMatch != nil
        })
    }
    //  Mark - UISearchBarDelegate - This function gets called when we press search in the search bar
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        makeRequest(searchBar.text)
    }
    
    //  makeRequest, searchString, url, task
    func makeRequest (searchString : String) {
        let url = NSURL(string: "https://api.nutritionix.com/v1_1/search/\(searchString)?results=0%3A20&cal_min=0&cal_max=50000&fields=item_name%2Cbrand_name%2Citem_id%2Cbrand_id&appId=3bf6cb98&appKey=2a65d108977ab1acbd9b5e90af22cb5f")
        
        //  NSURLSession downloads content via HTTP.
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            //  This will convert data into NSString
            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
            println(data)
            println(response)
        })
        task.resume()
    }
}

