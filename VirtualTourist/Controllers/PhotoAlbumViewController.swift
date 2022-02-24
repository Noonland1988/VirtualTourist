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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    
    // MARK: Actions
    
    @IBAction func okButtonTapped(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
        fetchedResultsController = nil
        flickrPages = nil
    }
    
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        deleteAllCells()
        print("deletion completed")
        getPhotoListHandler(pages: flickrPages)
        try? dataController.viewContext.save()
    }
    
    // MARK: Variables
    var dataController : DataController!
    
    var pickedLocation: CLLocationCoordinate2D!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var flickrPages: Int!
    
    var downloadedphotoList: PhotoList!
    
    var pin: String!
    
    var coordinate: Coordinate!
    
    private var blocks:[() -> Void] = [] //used in extension PAVC managing changes
    
    
    // MARK: Functions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        addAPinOnTheMap()
        
    }
    
    override func viewDidLoad() {
        mapView.delegate = self
        
        setUpFetchedResultsController()
        if photoCollectionView.numberOfItems(inSection: 0) == 0 {
            getPhotoListHandler(pages: 1)
            print("Photohandler activated")
        } else {
            flickrPages = 1
            print("Photos alreadly exist")
        }
        
        //collectionView
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        self.view.isUserInteractionEnabled = true
        photoCollectionView.isUserInteractionEnabled = true
        photoCollectionView.allowsSelection = true
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
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(fetchedResultsController.sections?[section].numberOfObjects ?? 0)
        return fetchedResultsController.sections?[section].numberOfObjects ?? 10

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let aPhoto = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionCell", for: indexPath) as! PhotoAlbumCollectionCell
        cell.imageView.image = UIImage(named: "collectionPlaceholder")
        
        if let photoURL = aPhoto.photoURL {
            self.getAImage(url: photoURL) { response, error in
                if let response = response {
                    cell.imageView.image = response
                } else {
                    self.showAlert(title: "Could not find a image", message: error?.localizedDescription ?? "")
                    print("could not find a image")
                }
            }
        } else {
            print("could not find image url")
        }
        
        return cell
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = fetchedResultsController.object(at: indexPath)
        print("a cell selected")
        dataController.viewContext.delete(selectedCell)
        try? dataController.viewContext.save()
        
    }
    
    // MARK: handling CoreData
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        let predicate = NSPredicate(format: "coordinate == %@", coordinate)
        fetchRequest.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func addCoreDataPhoto(id: String, photoURL: String) {
        let photo = Photo(context: dataController.viewContext)
        photo.id = Int64(id)!
        //photo.photoImage = photoImage.jpegData(compressionQuality: 1)
        photo.coordinate = coordinate
        photo.photoURL = photoURL
        try? dataController.viewContext.save()
    }
    

    // MARK: get photoList and add in CoreData
    func getPhotoListHandler(pages: Int){
        searchingImageActive(true)
        let requestURL = FlickrClient.requestPhotosURL(coordinate: pickedLocation, page: Int.random(in: 1...pages))
        
        FlickrClient.taskForGETRequest(url: requestURL, responseType: PhotoList.self){ response, error in
            if let response = response {
                self.flickrPages = response.photos.pages
                self.downloadedphotoList = response
                for i in response.photos.photo {
                    //id, url
                    self.addCoreDataPhoto(id: i.id, photoURL: FlickrClient.getPhotoImageURL(serverId: i.server, id: i.id, secret: i.secret, sizeSuffix: "q"))
                    
                }
                self.searchingImageActive(false)
            } else {
                self.showAlert(title: "Could not find a imageList", message: error?.localizedDescription ?? "")
                print("could not find the list")
                self.searchingImageActive(false)
            }
        }
    }
    
    
    func getAImage(url:String, completion: @escaping (UIImage?, Error?) -> Void) {
        let imageURL = URL(string: url)
        do {
            let data = try Data(contentsOf: imageURL!)
            completion(UIImage(data: data), nil)
        } catch {
            completion(nil, error)
        }
        
    }
    
    func deleteAllCells(){
        let cellsToDelete = dataController.viewContext.object(with: self.coordinate.objectID) as! Coordinate
        cellsToDelete.photos = []
        print("commance cellsToDelete")
        try? dataController.viewContext.save()
    }

    
// Does not seems to work...
//    func updateCoreDataPhoto() {
//        print("updateCoreDataPhoto initiated")
//        let coreDataPhotos = dataController.viewContext.object(with: self.coordinate.objectID) as! Coordinate
//        for i in coreDataPhotos.photos!.allObjects as! [Photo] {
//            if let photoURL = i.photoURL{
//                self.getAImage(url: photoURL) { response, error in
//                    if let response = response {
//                        i.photoImage = response.jpegData(compressionQuality: 1)
//                    } else {
//                        print("could not find a image")
//                    }
//                }
//            } else {
//                print("could not find image url")
//            }
//        }
//        try? dataController.viewContext.save()
//    }
    
    func searchingImageActive(_ active: Bool){
        active ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        newCollectionButton.isEnabled = !active
    }
    
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {


        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .delete:
                blocks.append { [weak self] in
                    self?.photoCollectionView.deleteItems(at: [indexPath!])
                }
            case .insert:
                blocks.append  { [weak self] in
                    self?.photoCollectionView.insertItems(at: [newIndexPath!])
                }
            case .move:
                blocks.append { [weak self] in
                    self?.photoCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
                }
            case .update:
                blocks.append { [weak self] in
                    self?.photoCollectionView.reloadItems(at: [indexPath!])
                }
            @unknown default:
                break
            }
        }

        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            blocks.removeAll()
        }

        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            photoCollectionView.performBatchUpdates({
                self.blocks.forEach { (block) in
                    block()
                }
            }, completion: nil)
        }
    
    
}
