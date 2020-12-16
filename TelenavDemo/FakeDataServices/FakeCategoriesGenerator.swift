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
        let food = TNEntityStaticCategory(name: "Food", id: "2040")
        let coffee = TNEntityStaticCategory(name: "Coffee", id: "241")
        let groccery = TNEntityStaticCategory(name: "Grocery", id: "221")
        let shopping = TNEntityStaticCategory(name: "Shopping", id: "4090")
        let parking = TNEntityStaticCategory(name: "Parking", id: "600")
        let banksAtms = TNEntityStaticCategory(name: "Banks/ATMs", id: "374")
        let hotels = TNEntityStaticCategory(name: "Hotels/Motels", id: "595")
        let attractions = TNEntityStaticCategory(name: "Attractions", id: "605")
        let fuel = TNEntityStaticCategory(name: "Fuel", id: "811")
        let electricVehicleCharge = TNEntityStaticCategory(name: "EV Charge station", id: "771")
        
        return [food, coffee, groccery, shopping, parking, banksAtms, hotels, attractions, fuel, electricVehicleCharge]
    }
    
}
