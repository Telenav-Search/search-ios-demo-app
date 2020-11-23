//
//  FakeContentGenerator.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import Foundation
import TelenavEntitySDK

class FakeCategoriesGenerator {
    
    func getStaticCategories(completion: @escaping ([TNEntityStaticCategory]?, Error?) -> Void) {
        
        completion(staticCategories, nil)
    }
        
    func getAllCategories(completion: @escaping ([TelenavCategoryDisplayModel]?, Error?) -> Void) {
        
        let categories = getCategoriesFromFakeJSON()
        
        let cats = mappedCats(categories)
        
        completion(cats, nil)
    }
    
    func mappedCats(_ categories: [TNEntityCategory]) -> [TelenavCategoryDisplayModel] {
        
        var dispCats = [TelenavCategoryDisplayModel]()
        
        for cat in categories {
            let dispCategory = TelenavCategoryDisplayModel(category: cat, catLevel: 0)
            
            dispCats.append(dispCategory)
        }
        
        return dispCats
    }
    
    private func getCategoriesFromFakeJSON() -> [TNEntityCategory] {
        
        guard let categoriesJSONURL = Bundle.main.url(forResource: "FakeCategories", withExtension: "json") else {
            return []
        }
                
        do {
            let jsonData = try Data(contentsOf: categoriesJSONURL)
            
            let decoder = JSONDecoder()
            
            let presets = try decoder.decode([TNEntityCategory].self, from: jsonData)
            
            return presets
        } catch {
            print(error.localizedDescription)
        }

        return []
    }
    
    private var staticCategories: [TNEntityStaticCategory] {
        let food = TNEntityStaticCategory(name: "Food")
        let coffee = TNEntityStaticCategory(name: "Coffee")
        let groccery = TNEntityStaticCategory(name: "Grocery")
        let shopping = TNEntityStaticCategory(name: "Shopping")
        let parking = TNEntityStaticCategory(name: "Parking")
        let banksAtms = TNEntityStaticCategory(name: "Banks/ATMs")
        let hotels = TNEntityStaticCategory(name: "Hotels/Motels")
        let attractions = TNEntityStaticCategory(name: "Attractions")
        let fuel = TNEntityStaticCategory(name: "Fuel")
        let electricVehicleCharge = TNEntityStaticCategory(name: "Electric Vehicle Charge station")
        
        return [food, coffee, groccery, shopping, parking, banksAtms, hotels, attractions, fuel, electricVehicleCharge]
    }
    
}
