//
//  HealthStoreConstant.swift
//  FoodTracker
//
//  Created by steven wong on 9/4/15.
//  Copyright (c) 2015 steven.w. All rights reserved.
//

import Foundation
import HealthKit

//  Users will be able to get HKHealthStore from this class
class HealthStoreConstant {
    let healthStore: HKHealthStore? = HKHealthStore()
}