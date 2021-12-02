//
//  SearchEngine.swift
//  TelenavDemo
//
//  Created by Evgeniy Netepa on 18.11.2021.
//

import VividDriveSessionSDK
import TelenavEntitySDK

class SearchEngine : VNSearchEngine {
  
  var currentLocation: VNGeoPoint?
  
  // TNEntityStaticCategory(name: "Fuel", id: "811")
  override func search(withDisplayContent displayContent: [String]!,
                       searchBox: [VNGeoPoint]!,
                       maxResultCount: Int32,
                       language: String!) -> [VNPoiSearchEntity]!
  {
    var entityGeoPoints = [TNEntityGeoPoint]()
    for geoPoint in searchBox {
      entityGeoPoints.append(TNEntityGeoPoint.point(lat: geoPoint.latitude,
                                                    lon: geoPoint.longitude))
    }
    
    let searchOptions = TNEntitySearchOptions(intent: .around, showAddressLines: false)
    
    let currentFilter = TNEntitySearchFilter()
    let geoFilter = TNEntityPolygonGeoFilter()
    geoFilter.polygon.points = entityGeoPoints
    currentFilter.geoFilter = geoFilter
    
    let categoryFilter = TNEntitySearchCategoryFilter()
    categoryFilter.categories = displayContent
    currentFilter.categoryFilter = categoryFilter
    
    let searchParams = TNEntitySearchParamsBuilder()
        .limit(Int(maxResultCount))
        .location(TNEntityGeoPoint.point(lat: currentLocation?.latitude ?? 0.0,
                                         lon: currentLocation?.longitude ?? 0.0))
        .filters(currentFilter)
        .searchOptions(searchOptions)
        .build()
    
    var searchResult = [VNPoiSearchEntity]()
    
    let group = DispatchGroup()
    group.enter()
    
    TNEntityClient.search(params: searchParams) { [self] (telenavSearch, err) in
      guard let searchResults = telenavSearch?.results else {
        group.leave()
        return
      }
      
      for result in searchResults {
        let entity = VNPoiSearchEntity.init(
          location: CLLocationCoordinate2DMake(result.place?.address?.geoCoordinates?.latitude ?? 0.0,
                                               result.place?.address?.geoCoordinates?.longitude ?? 0.0),
          image: makeEntityAnnotationIcon(by: "\(result.place?.name ?? "")")
        )
        searchResult.append(entity)
      }
      group.leave()
    }
    
    group.wait()
    
    return searchResult
  }
  
  private func makeEntityAnnotationIcon(by text: String) -> UIImage? {
      let textColor = UIColor.black
      let textFont = UIFont.systemFont(ofSize: 24)
      guard let entityAnnotationImage = UIImage(named: "map-fuel") else {
          return nil
      }
    
      let textFontAttributes = [
        NSAttributedString.Key.font: textFont,
        NSAttributedString.Key.foregroundColor: textColor,
        ] as [NSAttributedString.Key : Any]
    
      let textSize = (text as NSString).size(withAttributes: textFontAttributes)
      let textOrigin = CGPoint(
          x: 0,
          y: entityAnnotationImage.size.height)
      
      let textRect = CGRect(origin: textOrigin, size: textSize)
      
      let scale = UIScreen.main.scale
      var imageSize = entityAnnotationImage.size
      imageSize.width = max(imageSize.width, textSize.width)
      imageSize.height += textSize.height
      UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
      
      entityAnnotationImage.draw(in: CGRect(origin: CGPoint.zero, size: entityAnnotationImage.size))
      text.draw(in: textRect, withAttributes: textFontAttributes)
      
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      return newImage
  }
}
