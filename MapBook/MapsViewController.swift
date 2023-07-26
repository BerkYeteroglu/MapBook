//
//  ViewController.swift
//  MapBook
//
//  Created by Berk Yeteroğlu on 21.07.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var isimTextField: UITextField!
    
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRec = UILongPressGestureRecognizer(target: self, action: #selector(tappedMap(gestureRecognizer:)))
        gestureRec.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(gestureRec)
        
        let gestureView = UITapGestureRecognizer(target: self, action: #selector(tappedView))
        view.addGestureRecognizer(gestureView)
        
        if secilenIsim != ""{
            if let uuidString = secilenId?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchReq.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchReq.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchReq)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubtitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    print("HATA!!!")
                }
            }
        }else{
            
        }
        
    }
    @objc func tappedView(){
        view.endEditing(true)
    }

    @objc func tappedMap(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else{
            pinView?.annotation =  annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != ""{
            let reqLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(reqLocation) { (placeMarkDizisi, hata)  in
                if let placeMarks = placeMarkDizisi {
                    if placeMarks.count > 0 {
                        let yeniPlacemark = MKPlacemark(placemark: placeMarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOption = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOption)
                    }
                }
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if secilenIsim == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    @IBAction func kaydetButton(_ sender: Any) {
        let appDelagate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelagate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "isim")
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Kayıt başarılı")
        }catch{
            fatalError()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("yerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
}

