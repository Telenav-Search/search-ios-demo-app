//
//  FakeContentGenerator.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import Foundation
import TelenavSDK

class FakeCategoriesGenerator {
    
    func getStaticCategories(completion: @escaping ([TelenavStaticCategory]?, Error?) -> Void) {
        
        completion(staticCategories, nil)
    }
        
    func getAllCategories(completion: @escaping ([TelenavCategoryDisplayModel]?, Error?) -> Void) {
        
        let categories = getCategoriesFromFakeJSON()
        
        let cats = mappedCats(categories)
        
        completion(cats, nil)
    }
    
    func mappedCats(_ categories: [TelenavCategory]) -> [TelenavCategoryDisplayModel] {
        
        var dispCats = [TelenavCategoryDisplayModel]()
        
        for cat in categories {
            let dispCategory = TelenavCategoryDisplayModel(category: cat, catLevel: 0)
            
            dispCats.append(dispCategory)
        }
        
        return dispCats
    }
    
    private func getCategoriesFromFakeJSON() -> [TelenavCategory] {
        
        guard let categoriesJSONURL = Bundle.main.url(forResource: "FakeCategories", withExtension: "json") else {
            return []
        }
                
        do {
            let jsonData = try Data(contentsOf: categoriesJSONURL)
            
            let decoder = JSONDecoder()
            
            let presets = try decoder.decode([TelenavCategory].self, from: jsonData)
            
            return presets
        } catch {
            print(error.localizedDescription)
        }

        return []
    }
    
    private var staticCategories: [TelenavStaticCategory] {
        let food = TelenavStaticCategory(name: "Food")
        let coffee = TelenavStaticCategory(name: "Coffee")
        let groccery = TelenavStaticCategory(name: "Grocery")
        let shopping = TelenavStaticCategory(name: "Shopping")
        let parking = TelenavStaticCategory(name: "Parking")
        let banksAtms = TelenavStaticCategory(name: "Banks/ATMs")
        let hotels = TelenavStaticCategory(name: "Hotels/Motels")
        let attractions = TelenavStaticCategory(name: "Attractions")
        let fuel = TelenavStaticCategory(name: "Fuel")
        let electricVehicleCharge = TelenavStaticCategory(name: "Electric Vehicle Charge station")
        
        return [food, coffee, groccery, shopping, parking, banksAtms, hotels, attractions, fuel, electricVehicleCharge]
    }
    
}
