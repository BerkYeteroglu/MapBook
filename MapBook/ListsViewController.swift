//
//  ListsViewController.swift
//  MapBook
//
//  Created by Berk Yeteroğlu on 24.07.2023.
//

import UIKit
import CoreData

class ListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenYerIsmi = ""
    var secilenYerId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMap))
        veriAl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yerOlusturuldu"), object: nil)
    }
    
    @objc func veriAl(){
        isimDizisi.removeAll(keepingCapacity: false)
        idDizisi.removeAll(keepingCapacity: false)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        fetchReq.returnsObjectsAsFaults = false
        do{
            let sonuclar = try context.fetch(fetchReq)
            if sonuclar.count > 0 {
                
                for sonuc in sonuclar as! [NSManagedObject] {
                    if let isim = sonuc.value(forKey: "isim") as? String {
                        isimDizisi.append(isim)
                    }
                    if let id = sonuc.value(forKey: "id") as? UUID {
                        idDizisi.append(id)
                    }
                }
            }
            tableView.reloadData()
        }catch{
            fatalError("Hata var")
        }
    }
    
    @objc func addMap(){
        secilenYerIsmi = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row]
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteNote(at: indexPath)
        }
    }
    func deleteNote(at indexPath: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        let uuidString = idDizisi[indexPath.row].uuidString
        
        fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                if let result = results.first as? NSManagedObject {
                    context.delete(result)
                    isimDizisi.remove(at: indexPath.row)
                    idDizisi.remove(at: indexPath.row)
                    
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    do {
                        try context.save()
                    } catch {
                        fatalError("Failed to update data")
                    }
                }
            }
        } catch {
            // Handle fetch error
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC" {
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId
        }
    }
    
}
