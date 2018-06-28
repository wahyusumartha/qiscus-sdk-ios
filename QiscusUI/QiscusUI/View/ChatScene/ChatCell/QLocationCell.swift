//
//  QLocationCell.swift
//  Alamofire
//
//  Created by UziApel on 27/06/18.
//

import UIKit
import MapKit
import SwiftyJSON
class QLocationCell: BaseChatCell {
    
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbTime: UILabel!
    
    @IBOutlet weak var ivStatus: UIImageView!
    @IBOutlet weak var locationContainer: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressView: UITextView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(QLocationCell.openMap))
        self.mapView.addGestureRecognizer(tapRecognizer)
    }
     override func bindDataToView() {
        self.lbName.text = self.comment.senderName
        self.lbTime.text = self.comment.time
        let data = self.comment.additionalData
        let payload = JSON(parseJSON: data)
        print("name \(payload["name"].stringValue)")
        print("name \(payload["address"].stringValue)")
        print("name \(payload["map_url"].stringValue)")
        print("name \(payload["name"].stringValue)")
        
        self.locationLabel.text = payload["name"].stringValue
        let address = payload["address"].stringValue
        self.addressView.text = address
        
        let lat = CLLocationDegrees(payload["latitude"].doubleValue)
        let long = CLLocationDegrees(payload["longitude"].doubleValue)

        let center = CLLocationCoordinate2DMake(lat, long)

        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        let newPin = MKPointAnnotation()
        newPin.coordinate = center
        self.mapView.setRegion(region, animated: false)
        self.mapView.addAnnotation(newPin)

        if self.comment.isMyComment {
            DispatchQueue.main.async {
                self.rightConstraint.isActive = true
                self.leftConstraint.isActive = false
            }
            lbName.textAlignment = .right
        }else {
            DispatchQueue.main.async {
                self.leftConstraint.isActive = true
                self.rightConstraint.isActive = false
            }
            lbName.textAlignment = .left
        }
    }
    
    @objc func openMap(){
        let payload = JSON(parseJSON: self.comment.additionalData)
        
        let latitude: CLLocationDegrees = payload["latitude"].doubleValue
        let longitude: CLLocationDegrees = payload["longitude"].doubleValue
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = payload["name"].stringValue
        mapItem.openInMaps(launchOptions: options)
    }

    
}
