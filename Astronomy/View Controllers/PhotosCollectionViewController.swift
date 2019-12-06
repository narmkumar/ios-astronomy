//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

// Serial Queue happens on the main thread
// DispatchQueue is a serial queue
// OperationQueue is a background queue

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    
    private let client = MarsRoverClient()
    private let cache = Cache<Int, Data>()
    private var photoFetchQueue = OperationQueue()
    private var operations = [Int: Operation]()
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[3]
        }
    }
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                }
            }
        }
    }
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
    }
    
    // MARK: - UICollectionView Data Source
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    // Make collection view cells fill as much available width as possible
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    // Add margins to the left and right side
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    // MARK: - Private
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        // Get the MarsPhotoReference instance for the passed in indexPath from the photoReferences array property.
        let photoReference = photoReferences[indexPath.item]
        
        // Check if there is cached data
        if let cacheData = cache.value(key: photoReference.id),
            let image = UIImage(data: cacheData) {
                cell.imageView.image = image
                return
            }
        
        // Start our fetch operation:
        let fetchOp = FetchPhotoOperation(photoReference: photoReference)
        
        let cacheOp = BlockOperation {
            if let data  = fetchOp.imageData {
                self.cache.cache(key: photoReference.id, value: data)
            }
        }
        
        let completionOp = BlockOperation {
            defer { self.operations.removeValue(forKey: photoReference.id) }
            if let currentIndexPath = self.collectionView.indexPath(for: cell),
                currentIndexPath != indexPath {
                print("Got image for reused cell")
                return
            }
            
            if let data = fetchOp.imageData {
                cell.imageView.image = UIImage(data: data)
            }
            
        }
        
        
        cacheOp.addDependency(fetchOp)
        completionOp.addDependency(fetchOp)
        
        photoFetchQueue.addOperation(fetchOp)
        photoFetchQueue.addOperation(cacheOp)
        OperationQueue.main.addOperation(completionOp)
        // Background que has property called "main" which segues back into the main que
        // All UI updates have to done on the main queue, so once this is done being run on the background queue, we must update it onto the main queue
        
        
        
        
        
        // PART 1:
        //        //Get the URL for the associated image using the imageURL property. Use .usingHTTPS (provided in URL+Secure.swift) to make sure the URL is an https URL. By default, the API returns http URLs.
        //        guard let imageURL = photoReference.imageURL.usingHTTPS else { return }
        //
        //
        //        // TODO: Implement image loading here
        //        let dataTask = URLSession.shared.dataTask(with: imageURL) { (data, _, error) in
        //            if let error = error {
        //                print("Error fetching image data: \(error)")
        //                return
        //            }
        //
        //            guard let data = data else {
        //                print("Error receiving data")
        //                return
        //            }
        //
        //            let image = UIImage(data: data)
        //            DispatchQueue.main.async {
        //                if self.collectionView.indexPath(for: cell) == indexPath {
        //                cell.imageView.image = image
        //                }
        //            }
        //        }
        //        dataTask.resume()
        // MARK: - END OF PART 1
    }
    
    
}
