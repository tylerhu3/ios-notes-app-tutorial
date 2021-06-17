//
//  CreateNote.swift
//  Notes App From Tutorial
//
//  Created by Hu, Tyler on 11/19/20.
//  Copyright © 2020 Hu, Tyler. All rights reserved.
//

import UIKit
import SQLite3

class CreateNote: UIViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var isKeyboardOpen = false, isTextBold = false, isTextItalic = false
    var db:OpaquePointer? //database pointer
    var noteToEdit: Dictionary<String,String>?
    
    override func viewDidLoad() {
        super.viewDidLoad() // Do any additional setup after loading the view.
        textView.delegate = self
        var dbURL = try! //this can return a nil so, if it does return nil, just crash the app
            FileManager.default.url(for: .documentDirectory, //where we going to create file
            in: .userDomainMask, //where to search for this directory
            appropriateFor: nil,
            create: false //don't create a new dir if it doesn't already exist
        )
        .appendingPathComponent("data.sqlite") //this will create a file call "data.sqlite"
        
        if sqlite3_open(dbURL.path, //path of DB
            &db) == SQLITE_OK
        {
            //Create DB if it doesn't exist
            sqlite3_exec(db, //our db pointer
                         "CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY AUTOINCREMENT, note TEXT, isBold TEXT, isItalic TEXT, date TEXT, imagePath TEXT)", //create table query
                         nil, nil, nil)
        }
        
        if noteToEdit != nil{
            initializeNote()
        }
        
    }
    
    func initializeNote(){
        addButton.setTitle("Edit", for: .normal)
        textView.text = noteToEdit!["note"]
        var font = "Georgia"
        if (noteToEdit!["isTextBold"] == "true" || noteToEdit!["isTextItalic"] == "true"){
            font+="-"
            if noteToEdit!["isTextBold"] == "true" {
                font+="Bold"
            }
            if noteToEdit!["isTextItalic"] == "true" {
                font+="Italic"
            }
        }
        textView.font = UIFont(name: font, size: 24)
        
        if noteToEdit!["imagePath"] != "" {
            let imageURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent(noteToEdit!["imagePath"]!)
            
            imageView.image = UIImage(contentsOfFile: imageURL.path)
        }
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write your note here..."{
            textView.text = ""
            textView.alpha = 1
        }
        isKeyboardOpen = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "Write your note here..."
            textView.alpha = 0.5
        }
        isKeyboardOpen = false
    }
    
    @IBAction func backClicked(_ sender: Any) {
        if isKeyboardOpen {
            textView.endEditing(true) //closes keyboard
        }else{
            let storyboard  = UIStoryboard(name: "Main", bundle: nil)
            let firstScreen = storyboard.instantiateViewController(identifier: "firstScreen")
            present(firstScreen, animated: true, completion: {print("Came from CreateNote: backClicked :)")})
        }
    }
    
    @IBAction func addClicked(_ sender: Any) {
        let note = textView.text
        if note == "Write your note here..." || note == ""{
            return
        }
        let italic  = String (isTextItalic),
        bold = String (isTextBold),
        date = Date().string(format: "dd/MM/yyyy"),
        image = imageView.image;
        var imagePath = ""
        
        if image != nil {
                if noteToEdit != nil && noteToEdit!["imagePath"] != ""{
                    imagePath = noteToEdit!["imagePath"]!
                }
                else{
                imagePath = UUID().uuidString + ".jpg" //random generated named
                let jpegData = image?.jpegData(compressionQuality: 1) // no compression string
                let imageURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(imagePath)
                try! jpegData?.write(to: imageURL)
                }
            }
        var query =
        "INSERT INTO notes( note, isBold, isItalic, date, imagePath) VALUES ('\(note!)','\(bold)','\(italic)','\(date)','\(imagePath)')"
        
        if noteToEdit != nil {
            query = "UPDATE notes SET note='\(note!)', isBold='\(bold)', isItalic='\(italic)', date='\(date)', imagePath='\(imagePath)', WHERE id='\(noteToEdit!["id"]!)' "
        }
        let res = sqlite3_exec(db, query, nil, nil, nil)
        if res == SQLITE_OK {
            let storyboard  = UIStoryboard (name: "Main", bundle: nil)
            let firstScreen = storyboard.instantiateViewController(identifier: "firstScreen")
            present(firstScreen, animated: true, completion: {print("Came from CreateNote: addClicked :)")})
        }else{
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
            print("Unsuccesful Query :(")
        }
        
    }
    
    @IBAction func italicClicked(_ sender: Any) {
        
        isTextItalic = !isTextItalic
        var font = "Georgia"
        if (isTextBold || isTextItalic){
            font+="-"
            if isTextBold{
                font+="Bold"
            }
            if isTextItalic{
                font+="Italic"
            }
        }
        textView.font = UIFont(name: font, size: 24)
    }
    
    @IBAction func boldClicked(_ sender: Any) {
         isTextBold = !isTextBold
         var font = "Georgia"
         if (isTextBold || isTextItalic){
             font+="-"
             if isTextBold{
                 font+="Bold"
             }
             if isTextItalic{
                 font+="Italic"
             }
         }
         textView.font = UIFont(name: font, size: 24)
     }
     
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil) //close image picture
        imageView.image = info[.originalImage] as? UIImage
    }
    
    @IBAction func galleryClicked(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker,animated: true, completion: nil)
    }
    
    
    @IBAction func cameraClicked(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker,animated: true, completion: nil)    
    }
    
}

extension Date {
    func string (format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from:self) //return date as a String.. WhoOoOoaaa
    }
}
