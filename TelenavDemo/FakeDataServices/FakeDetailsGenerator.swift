//
//  FakeDetailsGenerator.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import Foundation
import TelenavSDK

class FakeDetailsGenerator {
        
    func getDetails(id: String, completion: @escaping ([TelenavEntity]?, Error?) -> Void) {
        
        let detail = getDetailFromFakeJSON()
        
        completion(detail, nil)
    }
    
    private func getDetailFromFakeJSON() -> [TelenavEntity] {
        
        guard let categoriesJSONURL = Bundle.main.url(forResource: "FakeDetails", withExtension: "json") else {
            return  []
        }
                
        do {
            let jsonData = try Data(contentsOf: categoriesJSONURL)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let details = try decoder.decode([TelenavEntity].self, from: jsonData)
            
            return details
        } catch {
            print(error.localizedDescription)
        }

        return []
    }
}
