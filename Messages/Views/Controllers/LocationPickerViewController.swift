//
//  LocationPickerViewController.swift
//  Messages
//
//  Created by Sergey on 11/25/20.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?

    private var coordinates: CLLocationCoordinate2D?
    
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        map.isUserInteractionEnabled = true
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.coordinates = coordinates
        self.isPickable = coordinates == nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(didTapSendButton))
            setupGestureRecognizer()
        } else {
            // just show the location
            guard let coordinates = self.coordinates else {
                return 
            }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        
        view.addSubview(map)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    @objc func didTapSendButton() {
        guard let coordinates = coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    func setupGestureRecognizer() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        map.addGestureRecognizer(gesture)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer) {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
        
        //drop a pin on that location
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    
    
}
