//
//  ViewController.swift
//  Notes App From Tutorial
//
//  Created by Hu, Tyler on 11/11/20.
//  Copyright © 2020 Hu, Tyler. All rights reserved.
//

import UIKit
import SQLite3

class ViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var db: OpaquePointer?
    var notes: [Dictionary<String, String>] = [] //a dictionary for each note
    
    /*
     This function will allow us to edit existing notes by getting the current index and saving the note we clicked
     on into a variable...
     at which point we will take that variable and transfer it to the "secondScreen"'s local var "noteToEdit"
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondScreen = storyboard.instantiateViewController(identifier: "secondScreen") as! CreateNote
        secondScreen.noteToEdit = notes[indexPath.row]
        present(secondScreen, animated: true, completion: nil)   
    }
    
    
    //function from UITableViewDataSource's def we can override to allow editing of cells
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool{
        //we can choose what's editable with indexPath
        return true //true allows for editing
    }
    
    //function from UITableViewDataSource's def we can override to
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath){
        if editingStyle == .delete {
            let note = notes[indexPath.row]
            notes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            sqlite3_exec(db, "DELETE FROM notes WHERE id='\(note["id"]!)'", nil, nil, nil)
            animateLabel()
        }
    }
    
    
    //This pretty much just animates the empty word to appear 1 character at a time @ rate 1 letter/5 milli seconds
    func animateLabel(){
        if notes.count == 0 {
            DispatchQueue.global(qos: .background).async {
                for c in "Empty!"{
                    DispatchQueue.main.async {
                        self.infoLabel.text = self.infoLabel.text! + String(c)
                    }
                    usleep(50000)
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        let note = notes[indexPath.row]
        let isBold = note["isBold"]
        let isItalic = note["isItalic"]
        cell.notelabel.text = note["note"]
        cell.dateLabel.text = note["date"]
        
        var font = "Georgia"
        if (isBold == "true" || isItalic == "true" ){
            font+="-"
            if isBold == "true"{
                font+="Bold"
            }
            if isItalic == "true"{
                font+="Italic"
            }
        }
        cell.notelabel.font = UIFont(name: font, size: 24)
        
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        
        let dbURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("data.sqlite")
        
        if sqlite3_open(dbURL.path, &db) == SQLITE_OK {
            let query = "SELECT * FROM notes"
            var queryStatement: OpaquePointer?
            
            if sqlite3_prepare(db, query, -1, &queryStatement, nil) == SQLITE_OK {
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = String(sqlite3_column_int(queryStatement, 0))
                    let note = String (cString: sqlite3_column_text(queryStatement, 1))
                    let isBold = String (cString: sqlite3_column_text(queryStatement, 2))
                    let isItalic = String (cString: sqlite3_column_text(queryStatement, 3))
                    let date = String (cString: sqlite3_column_text(queryStatement, 4))
                    let imagePath = String (cString: sqlite3_column_text(queryStatement, 5))
                    
                    let item = ["id":id, "note": note, "isBold": isBold, "isItalic": isItalic, "date": date, "imagePath":imagePath]
                    
                    notes.append(item)
                }
            }
        }
        
        animateLabel()
        
        //UINib refers to a xib file
       let nib = UINib(nibName: "TableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView() //get rid of separators for empty cells
        
    }


}

