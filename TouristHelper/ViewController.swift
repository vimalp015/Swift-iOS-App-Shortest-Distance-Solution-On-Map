//
//  ViewController.swift
//  TouristHelper
//
//  Created by Vimal on 8/28/16.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, NSURLConnectionDelegate, GMSMapViewDelegate  {

    var mutableData:NSMutableData  = NSMutableData.init() //var to hold the result from Google for nearby locations (Google Places)
    var currentPlaceMarker = GMSMarker.init() //hold the location where the user clicked recently
    var polyline = GMSPolyline.init() //hold the polylines drawn on the map
    var googleLocations = [CLLocation]() //hold all the locations fetched from google places
    
    @IBOutlet weak var googleMapsContainer: UIView!
    
    let locationManager = CLLocationManager()
    var googleMapsView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        //load the map and display the current location of the user until nearby locations are loaded
        //{
        let lat = (locations.last?.coordinate.latitude)!
        let lon = (locations.last?.coordinate.longitude)!
        self.googleMapsView = GMSMapView(frame: self.googleMapsContainer.frame)
        self.googleMapsView.delegate = self
        self.view.addSubview(self.googleMapsView)
        
        let position = CLLocationCoordinate2DMake(lat, lon)
        let marker = GMSMarker(position: position)
        
        let camera = GMSCameraPosition.cameraWithLatitude(lat, longitude: lon, zoom: 15)
        self.googleMapsView.camera = camera
        
        locationManager.stopUpdatingLocation()
        
        marker.title = "Tourist Helper"
        marker.map = self.googleMapsView
        marker.map?.myLocationEnabled = true
        marker.map?.settings.myLocationButton = true
        marker.map?.settings.scrollGestures = true
        //}
        
        //code to fetch nearby locations from Google from a radius of 1000 meters
        //{
        //preferably the key should be fetched from google.plist
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lon)&radius=1000&type=restaurant&key=AIzaSyAYuV7MCH0S76Eit0mJW8lGMfOc98FySdA"
        let url = NSURL(string:urlString)
        let theRequest = NSMutableURLRequest(URL: url!)
        theRequest.HTTPMethod = "POST"
        let connection = NSURLConnection(request: theRequest, delegate: self, startImmediately: true)
        connection!.start()
        
        if (connection != nil) {
            print("Connection success")
        }
        else{
            print("Error in connection")
        }
        //}
    }
    
    //event when a user clicks on the map
    func mapView(mapView: GMSMapView, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        
        //remove the current marker
        currentPlaceMarker.map = nil
        //remove the current polyline
        polyline.map = nil
        
        let path = GMSMutablePath()
        path.addCoordinate(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
        
        //Code to calculate the shortest path to google locations
        //{
        var tempGoogleLocations = googleLocations
        var tempCurrentLocation = CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
        for _ in googleLocations {
            var nearestPoint = CLLocation.init()
            var removalIndex = 0
            for (index, value) in tempGoogleLocations.enumerate() {
                if(index == 0) {
                    nearestPoint = value
                    removalIndex = index
                }
                else {
                    if(tempCurrentLocation.distanceFromLocation(nearestPoint) >= tempCurrentLocation.distanceFromLocation(value)) {
                        nearestPoint = value
                        removalIndex = index
                    }
                }
            }
            tempGoogleLocations.removeAtIndex(removalIndex)
            tempCurrentLocation = nearestPoint
            path.addCoordinate(CLLocationCoordinate2D(latitude: nearestPoint.coordinate.latitude, longitude: nearestPoint.coordinate.longitude))
        }
        path.addCoordinate(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
        //}
        
        //display polylines on the map
        polyline = GMSPolyline(path: path)
        polyline.map = googleMapsView

        //code to set the new marker and assign it as current selected start location
        //{
        let placeMarker = GMSMarker.init()
        placeMarker.position = coordinate
        placeMarker.title = "Start Location"
        placeMarker.groundAnchor = CGPoint(x: 0.5, y: 1)
        placeMarker.appearAnimation = kGMSMarkerAnimationPop
        placeMarker.map = self.googleMapsView
        currentPlaceMarker = placeMarker
        //}
    }
    
    func mapView(mapView: GMSMapView, didTapInfoWindowOfMarker marker: GMSMarker) {
        // your code
    }
    
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        mutableData.length = 0;
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        mutableData.appendData(data)
    }
    
    //Function to scale the location icon
    func image(originalImage: UIImage, scaledToSize size: CGSize) -> UIImage {
        //avoid redundant drawing
        if CGSizeEqualToSize(originalImage.size, size) {
            return originalImage
        }
        //create drawing context
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        //draw
        originalImage.drawInRect(CGRectMake(0.0, 0.0, size.width, size.height))
        //capture resultant image
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //return image
        return image!
    }
    
    //Triggered once the locations are received from Google Places
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(mutableData, options: []) as! [String: AnyObject]
            //Clear the map to avoid duplicate flags
            self.googleMapsView.clear()
            
            let results = json["results"] as? Array<NSDictionary>
            //print("results = \(results!.count)")
            
            //Loop each location from the result and set the marker on the map
            for (index, result) in results!.enumerate() {
                //Select only 20 locations
                if(index == 19) {
                    return
                }
                var coordinate : CLLocationCoordinate2D!
                
                if let geometry = result["geometry"] as? NSDictionary {
                    if let location = geometry["location"] as? NSDictionary {
                        let lat = location["lat"] as! CLLocationDegrees
                        let long = location["lng"] as! CLLocationDegrees
                        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        
                        let placeMarker = GMSMarker.init()
                        placeMarker.position = coordinate
                        //Verify if "icon" is a valid URL
                        if let url = NSURL(string: result["icon"] as! String) {
                            if let data = NSData(contentsOfURL: url) {
                                //placeMarker.icon = UIImage(data: data)!.imageWithRenderingMode(.AlwaysTemplate)
                                placeMarker.icon = self.image(UIImage(data: data)!, scaledToSize: CGSizeMake(15.0, 15.0))
                            }        
                        }
                        placeMarker.title = result["name"] as? String
                        placeMarker.groundAnchor = CGPoint(x: 0.5, y: 1)
                        placeMarker.appearAnimation = kGMSMarkerAnimationPop
                        placeMarker.map = self.googleMapsView
                        //add the google locations to our global array
                        googleLocations.append(CLLocation.init(latitude: lat, longitude: long))
                    }
                }
            }

        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        print(error.description)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }

}

