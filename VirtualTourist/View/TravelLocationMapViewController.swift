//
//  TravelLocationMapViewController.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2021/12/07.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController,MKMapViewDelegate {
    
    // MARK: Outlets
    @IBOutlet weak var travelMapView: MKMapView!
    
    // MARK: Actions
    

    
    
    // MARK: Variables
    var dataController: DataController!
    
    var coordinates: [Coordinate] = []
    
    var pickedLocation : CLLocationCoordinate2D!

    
    // MARK: Functions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        travelMapView.region = AppDelegate.launchRegion
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        travelMapView.delegate = self
        
        //handling CoreData
        print("handleCoreData")
        let fetchRequest: NSFetchRequest<Coordinate> = Coordinate.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            coordinates = result
        // map  reload
        }
        getAnnotationsFromCoordinates(coordinates: coordinates)
        
        //Create UIGestureRecoginizer
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(TravelLocationMapViewController.recognizeLongPress(sender:)))
            
        //Add UIGesture Recognizer
        travelMapView.addGestureRecognizer(myLongPress)
        
    }
    
    // MARK: MKMapViewDelegate
    
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let currentRegion = mapView.region
        DispatchQueue.main.async {
            UserDefaultsHandling.saveLaunchRegion(region: currentRegion)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
    
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation{
            self.pickedLocation = annotation.coordinate
            self.performSegue(withIdentifier: "annotationTapped", sender: nil)
        }
    }
    
    // MARK: action func
    @objc func recognizeLongPress(sender: UILongPressGestureRecognizer) {
        // Prevent creating multiple pins while long pressing
        if sender.state != UIGestureRecognizer.State.began{
            return
        }
        //define the long pressed location
        let location = sender.location(in: travelMapView)
        
        //convert location to CLLocationCoordinate2D
        let longPressedLocation: CLLocationCoordinate2D = travelMapView.convert(location, toCoordinateFrom: travelMapView)
        
        //create a pin
        let newPin: MKPointAnnotation = MKPointAnnotation()
        newPin.coordinate = longPressedLocation
        
        //add to CoreData Coordinate? ??
        addCoordinate(newCoordinate: longPressedLocation)
        
        //add a pin on the map
        travelMapView.addAnnotation(newPin)
       
        
    }
    
    // MARK: CoreData handling
    
    func addCoordinate(newCoordinate: CLLocationCoordinate2D) {
        let coordinate = Coordinate(context: dataController.viewContext)
        coordinate.latitude = Float(newCoordinate.latitude)
        coordinate.longitude = Float(newCoordinate.longitude)
        coordinate.creationDate = Date()
        try? dataController.viewContext.save()
        
    }
    
    func getAnnotationsFromCoordinates(coordinates: [Coordinate]) {
        var annotations = [MKPointAnnotation]()
        
        for coordinate in coordinates {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(coordinate.latitude), longitude: Double(coordinate.longitude))
            annotations.append(annotation)
        }
        
        self.travelMapView.addAnnotations(annotations)
    }
    
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "annotationTapped" {
            let photoAlbumVC = segue.destination as? PhotoAlbumViewController
            photoAlbumVC?.pickedLocation = pickedLocation
            photoAlbumVC?.dataController = dataController
        }
    }
    
    
}


