//
//  FakeSuggestionsGenerator.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 12.11.2020.
//

import Foundation
import TelenavEntitySDK

class FakeSuggestionsGenerator {
        
    func getSuggestions(completion: @escaping ([TelenavSuggestionResult]?, Error?) -> Void) {
        
        let suggestions = getSuggesstionsFromFakeJSON()
        
        completion(suggestions, nil)
    }
    
    private func getSuggesstionsFromFakeJSON() -> [TelenavSuggestionResult] {
        
        guard let categoriesJSONURL = Bundle.main.url(forResource: "FakeSuggestions", withExtension: "json") else {
            return []
        }
                
        do {
            let jsonData = try Data(contentsOf: categoriesJSONURL)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let presets = try decoder.decode([TelenavSuggestionResult].self, from: jsonData)
            
            return presets
        } catch {
            print(error.localizedDescription)
        }

        return []
    }
}
