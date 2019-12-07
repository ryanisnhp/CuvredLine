//
//  ViewController.swift
//  CurvedLine
//
//  Created by Phat on 12/5/19.
//  Copyright © 2019 Phat. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    @IBOutlet private weak var mapView: GMSMapView!
    private var polylines: [GMSPolyline] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleTheMap()
        
        let london = CLLocationCoordinate2D(latitude: 51.5287714, longitude: -0.2420222)
        let cambridge = CLLocationCoordinate2D(latitude: 52.1988895, longitude: 0.0848821)
        
        clearCurvedPolylines()
        draw(startLocation: london, endLocation: cambridge)
    }
    
    func loadContentFile(name:String, type:String) -> String? {
        do {
            let filePath = Bundle.main.path(forResource: name, ofType: type)
            let fileContent = try String(contentsOfFile: filePath!, encoding: String.Encoding.utf8) as String?
            return fileContent
        } catch let error {
            print("json serialization error: \(error)")
            return nil
        }
    }
    
    func styleTheMap() {
        mapView.mapStyle = try! GMSMapStyle(jsonString: loadContentFile(name: "mapStyle", type: "json")!)
    }
    
    func draw(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D) {
        let polyline = getPolyline(startLocation: startLocation, endLocation: endLocation)!
        polylines.append(polyline)
    }
    
    /// Return a polyline from startLocation to endLocation
    /// - Parameters:
    ///   - startLocation: coordinate must be valid
    ///   - endLocation: coordinate must be valid
    func getPolyline(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D) -> GMSPolyline? {
        //Create initial path
        let path = GMSMutablePath()
        
        //STEP 1:
        let SE = GMSGeometryDistance(startLocation, endLocation)
        
        //STEP 2:
        let angle = Double.pi / 2

        //STEP 3:
        let ME = SE / 2.0
        let R = ME / sin(angle / 2)
        let MO = R * cos(angle / 2)
        
        //STEP 4:
        let heading = GMSGeometryHeading(startLocation, endLocation)
        let mCoordinate = GMSGeometryOffset(startLocation, ME, heading)
        let direction = (startLocation.longitude - endLocation.longitude > 0) ? -1.0 : 1.0
        let angleFromCenter = 90.0 * direction
        let oCoordinate = GMSGeometryOffset(mCoordinate, MO, heading + angleFromCenter)
        addMarkerOnMap(location: startLocation)

        //Add endLocation to the path
        path.add(endLocation)
        
        //Add marker for endLocation
        addMarkerOnMap(location: endLocation)
        
        
        //STEP 5:
        let num = 100
        
        let initialHeading = GMSGeometryHeading(oCoordinate, endLocation)
        let degree = (180.0 * angle) / Double.pi
        
        for i in 1...num {
            let step = Double(i) * (degree / Double(num))
            let heading : Double = (-1.0) * direction
            let pointOnCurvedLine = GMSGeometryOffset(oCoordinate, R, initialHeading + heading * step)
            path.add(pointOnCurvedLine)
        }
        
        path.add(startLocation)
        addMarkerOnMap(location: startLocation)
        
        //Adjust polylines are in the center of the screen
        let bounds = GMSCoordinateBounds(path: path)
        mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50))
        
        //STEP 6:
        let polyline = GMSPolyline(path: path)
        polyline.map = mapView
        polyline.strokeWidth = 4.0
        polyline.strokeColor = UIColor.white
        
        return polyline
    }
    
    func clearCurvedPolylines() {
        for polyline in polylines {
            polyline.map = nil
        }
        polylines.removeAll()
    }
    
    func addMarkerOnMap(location: CLLocationCoordinate2D){
        let marker = GMSMarker(position: location)
        marker.icon = UIImage(named: "ic_pin")
        marker.map = mapView
    }
}

