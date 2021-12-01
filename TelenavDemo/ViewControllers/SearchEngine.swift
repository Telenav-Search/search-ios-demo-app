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
      
      var counter = 1
      for result in searchResults {
        let entity = VNPoiSearchEntity.init(
          location: CLLocationCoordinate2DMake(result.place?.address?.geoCoordinates?.latitude ?? 0.0,
                                               result.place?.address?.geoCoordinates?.longitude ?? 0.0),
          image: makeEntityAnnotaionIcon(by: "\(counter)")
        )
        searchResult.append(entity)
        counter += 1
      }
      group.leave()
    }
    
    group.wait()
    
    return searchResult
  }
  
  private func makeEntityAnnotaionIcon(by text: String) -> UIImage? {
      let textColor = UIColor.black
      let textFont = UIFont.systemFont(ofSize: 24)
      guard let entityAnnotationImage = UIImage(named: "entity-annotation-icon") else {
          return nil
      }
      
      let scale = UIScreen.main.scale
      UIGraphicsBeginImageContextWithOptions(entityAnnotationImage.size, false, scale)
      
      let textFontAttributes = [
          NSAttributedString.Key.font: textFont,
          NSAttributedString.Key.foregroundColor: textColor,
          ] as [NSAttributedString.Key : Any]
      
      let size = (text as NSString).size(withAttributes: textFontAttributes)
      let origin = CGPoint(
          x: entityAnnotationImage.size.width / 2 - size.width / 2,
          y: entityAnnotationImage.size.height / 2 - size.height / 2)
      
      let rect = CGRect(origin: origin, size: size)
      
      entityAnnotationImage.draw(in: CGRect(origin: CGPoint.zero, size: entityAnnotationImage.size))
      text.draw(in: rect, withAttributes: textFontAttributes)
      
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      return newImage
  }
}
