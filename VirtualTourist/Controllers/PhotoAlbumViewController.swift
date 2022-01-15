//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by 嶋田省吾 on 2021/12/07.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource{

    
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    @IBOutlet weak var photoFlowLayout: UICollectionViewFlowLayout!
    

    
    
    // MARK: Actions
    
    @IBAction func okButtonTapped(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
        fetchedResultsController = nil
        flickrPages = nil
    }
    
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Photo")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try dataController.persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: dataController.viewContext)
        } catch let errors as NSError {
            //handle the error...
        }
        //dataController.viewContext.delete(fetchedResultsController)
        getPhotoListHandler(pages: flickrPages)
        try? dataController.viewContext.save()
        
        
        
    }
    
    // MARK: Variables
    var dataController : DataController!
    
    var pickedLocation: CLLocationCoordinate2D!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var flickrPages: Int!
    
    //var collectionViewPhotos: [Photo] = []
    
    //var photoList = [photo]()
    
    
    // MARK: Functions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        addAPinOnTheMap()
        setUpFetchedResultsController()
        if photoCollectionView.numberOfItems(inSection: 0) == 0 {
            getPhotoListHandler(pages: 1)
            print("Photohandler activated")
        } else {
            flickrPages = 1
            print("Photos alreadly exist")
        }

    }
    
    override func viewDidLoad() {
        mapView.delegate = self
        
        //collectionView
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        collectionFlowSizeProperties()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        fetchedResultsController = nil
    }
    
    
    // MARK: MapView functions
    
    func addAPinOnTheMap() {
        let pin = MKPointAnnotation()
        pin.coordinate = pickedLocation
        self.mapView.addAnnotation(pin)
        var pinRegion = UserDefaultsHandling.loadLatestRegion()
        pinRegion.center = pickedLocation
        self.mapView.region = pinRegion
        
    }
    
    // MARK: CollectionView functions
    
    func collectionFlowSizeProperties(){
        let space:CGFloat = 3.0
        let dimention = (view.frame.size.width - (2 * space))/3.0
        
        photoFlowLayout.minimumInteritemSpacing = space
        photoFlowLayout.minimumLineSpacing = space
        photoFlowLayout.itemSize = CGSize(width: dimention, height: dimention)
        print("collectionFlowSizeProperties enabled")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(fetchedResultsController.sections?[section].numberOfObjects ?? 0)
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        
        //return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let aPhoto = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionCell", for: indexPath) as! PhotoAlbumCollectionCell

        DispatchQueue.main.async {
            if let imageData = aPhoto.photoImage{
                cell.imageView.image = UIImage(data: imageData)
                
            }
        }

        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(selectedCell)
        try? dataController.viewContext.save()
        
    }
    
    // MARK: handling CoreData
    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "photos")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func addCoreDataPhoto(id: String, photoImage: UIImage) {
        let photo = Photo(context: dataController.viewContext)
        photo.id = Int64(id)!
        photo.photoImage = photoImage.jpegData(compressionQuality: 1)
        try? dataController.viewContext.save()
    }
    
    // MARK: get photoList and add in CoreData
    func getPhotoListHandler(pages: Int){
        let requestURL = FlickrClient.requestPhotosURL(coordinate: pickedLocation, page: Int.random(in: 1...pages))
        
        FlickrClient.taskForGETRequest(url: requestURL, responseType: PhotoList.self){ response, error in
            if let response = response {
                self.flickrPages = response.photos.pages
                for i in response.photos.photo {
                    FlickrClient.getPhotoImage(serverId: i.server, id: i.id, secret: i.secret, sizeSuffix: "q") {data, error in
                        if let data = data {
                            self.addCoreDataPhoto(id: i.id, photoImage: data)
                            print(data)
                            
                            
                        } else {
                            print("No photo data found")
                        }
                    }
                }
            } else {
                print("could not find the list")
            }
        }

    }
    

    
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type{
        case .insert:
            photoCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photoCollectionView.deleteItems(at: [indexPath!])
        default:
            break
            
        }
    }

    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photoCollectionView.reloadData()
    }
    
}
