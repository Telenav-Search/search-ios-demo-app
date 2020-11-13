//
//  FakeSearchService.swift
//  TelenavDemo
//
//  Created by Lera Mozgovaya on 13.11.2020.
//

import UIKit
import TelenavSDK

class FakeSearchGenerator: NSObject {

    func getSearchResult(query: String, completion: @escaping (TelenavSearch?, Error?) -> Void) {
        
        let searchResult = getSearchResultFromFakeJSON()
        
        completion(searchResult, nil)
    }
    
    private func getSearchResultFromFakeJSON() -> TelenavSearch? {
        
        guard let categoriesJSONURL = Bundle.main.url(forResource: "FakeSearchResults", withExtension: "json") else {
            return nil
        }
                
        do {
            let jsonData = try Data(contentsOf: categoriesJSONURL)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let search = try decoder.decode(TelenavSearch.self, from: jsonData)
            
            return search
        } catch {
            print(error.localizedDescription)
        }

        return nil
    }
}