//
//  DataController.swift
//  FoodTracker
//
//  Created by steven wong on 8/20/15.
//  Copyright (c) 2015 steven.w. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//  Convert dictionary from VC into an array of keywords in the search results.
class DataController {
    
    //  We use idValue to index into the dictionary to save elements to CoreData.
    class func jsonAsUSDAIdAndNameSearchResults (json : NSDictionary) -> [(name: String, idValue: String)] {
        
        var usdaItemsSearchResults:[(name : String, idValue: String)] = []
        var searchResult: (name: String, idValue : String)
        
        if json["hits"] != nil {
            let results:[AnyObject] = json["hits"]! as [AnyObject]
            for itemDictionary in results {
                if itemDictionary["_id"] != nil {
                    if itemDictionary["fields"] != nil {
                        let fieldsDictionary = itemDictionary["fields"] as NSDictionary
                        if fieldsDictionary["item_name"] != nil {
                            let idValue:String = itemDictionary["_id"]! as String
                            let name:String = fieldsDictionary["item_name"]! as String
                            searchResult = (name : name, idValue : idValue)
                            usdaItemsSearchResults += [searchResult]
                        }
                    }
                }
            }
        }
        return usdaItemsSearchResults
    }
}












