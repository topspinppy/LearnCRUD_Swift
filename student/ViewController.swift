//
//  ViewController.swift
//  student
//
//  Created by Admin on 29/1/2562 BE.
//  Copyright © 2562 KMUTNB. All rights reserved.
//

import UIKit
import SQLite3

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    let fileName = "db.sqlite"
    let fileManager = FileManager.default
    var dbPath = String()
    var sql = String()
    var db: OpaquePointer?
    var stmt: OpaquePointer?
    var pointer: OpaquePointer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dbURL = try! fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false)
            .appendingPathComponent(fileName)
        let openDb = sqlite3_open(dbURL.path, &db)
        if openDb != SQLITE_OK{
            print("opening database error!")
            return
        }
        sql = "CREATE TABLE IF NOT EXISTS people " +
            "(id INTEGER PRIMARY KEY AUTOINCREMENT," +
            "name TEXT," +
        "phone TEXT)"
        let createTb = sqlite3_exec(db,sql,nil,nil,nil)
        if createTb != SQLITE_OK {
            let err = String(cString: sqlite3_errmsg(db))
            print(err)
        }
        sql = "INSERT INTO people (id, name, phone) VALUES " +
            "('1', 'สมชาย พายเรือ', ' 088444xxxx'), " +
            "('2', 'สมหญิง ยิงเรือ', ' 088555xxxx'), " +
            "('3', 'สมศรี ขี่เรือ', ' 088666xxxx'), " +
        "('4', 'Steve Jobs', ' 088777xxxx')"
        sqlite3_exec(db,sql,nil,nil,nil)
        select()
    }
    
    func select() {
        sql = "SELECT * FROM people"
        sqlite3_prepare(db, sql, -1, &pointer, nil)
        textView.text = ""
        
        var id: Int32
        var name: String
        var phone: String
        
        while(sqlite3_step(pointer) == SQLITE_ROW)
        {
            id = sqlite3_column_int(pointer, 0)
            textView.text?.append("id: \(id)\n")
            
            name = String(cString: sqlite3_column_text(pointer, 1))
            textView.text?.append("name: \(name) \n")
            
            phone = String(cString: sqlite3_column_text(pointer, 2))
            textView.text?.append("phone: \(phone)\n\n")
            
        }
    }
    @IBAction func buttonAddDidTap(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Insert", message: "ใส่ข้อมูลให้ครบทุกช่อง", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { tf in
            tf.placeholder = "ชื่อ"
            tf.font = UIFont.systemFont(ofSize: 18)
        })
        
        alert.addTextField(configurationHandler: { tf in
            tf.placeholder = "เบอร์โทร"
            tf.font = UIFont.systemFont(ofSize: 18)
            tf.keyboardType = .phonePad
        })
        
        let btCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let btOk = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.sql = "INSERT INTO people VALUES (null, ?, ?)"
            sqlite3_prepare(self.db, self.sql, -1, &self.stmt, nil)
            let name = alert.textFields![0].text! as NSString
            let phone = alert.textFields![1].text! as NSString
            sqlite3_bind_text(self.stmt, 1, name.utf8String, -1, nil)
            sqlite3_bind_text(self.stmt, 2, phone.utf8String, -1, nil)
            sqlite3_step(self.stmt)
            
            self.select()
        })
        
        alert.addAction(btCancel)
        alert.addAction(btOk)
        present(alert, animated: true, completion: nil)
        
    }

    @IBAction func buttonEditDidTap(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(
            title: "Update",
            message: "ใส่ข้อมูลให้ครบทุกช่อง",
            preferredStyle: .alert
        )
        
        alert.addTextField(configurationHandler: { tf in
            tf.placeholder = "ID ของแถวที่ต้องการแก้ไข"
            tf.font = UIFont.systemFont(ofSize: 18)
            tf.keyboardType = .numberPad
        })
        
        alert.addTextField(configurationHandler: { tf in
            tf.placeholder = "ชื่อ"
            tf.font = UIFont.systemFont(ofSize: 18)
        })
        alert.addTextField(configurationHandler: { tf in
            tf.placeholder = "เบอร์โทร"
            tf.font = UIFont.systemFont(ofSize: 18)
            tf.keyboardType = .phonePad
        })
        
        let btCancel = UIAlertAction(title: "Cancel",
                                     style: .cancel,
                                     handler: nil)
        
        let btOK = UIAlertAction(title: "Ok",
                                 style: .default,
                                 handler: { _ in
                                    guard let id = Int32(alert.textFields![0].text!) else {
                                        return
                                    }
            let name = alert.textFields![1].text! as NSString
            let phone = alert.textFields![2].text! as NSString
            self.sql = "UPDATE people " +
                    "SET name = ?, phone = ? " +
                    "WHERE id = ?"
            sqlite3_prepare(self.db, self.sql, -1, &self.stmt, nil)
            sqlite3_bind_text(self.stmt, 1, name.utf8String, -1, nil)
            sqlite3_bind_text(self.stmt, 2, phone.utf8String, -1, nil)
            sqlite3_bind_int(self.stmt, 3, id)
            sqlite3_step(self.stmt)
                                    
            self.select()
        })
        
        alert.addAction(btCancel)
        alert.addAction(btOK)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func buttonDeleteDidTap(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Delete",
                                      message: "ใส่ ID ของแถวที่ต้องการลบ",
                                      preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { tf in
            tf.placeholder = "ID ของแถวที่ต้องการลบ"
            tf.font = UIFont.systemFont(ofSize: 18)
            tf.keyboardType = .numberPad
        })
        
        let btCancel = UIAlertAction(title: "Cancel",
                                     style: .cancel,
                                     handler: nil)
        
        let btOK = UIAlertAction(title: "OK",
                                 style: .default,
                                 handler: { _ in
                                    guard let id = Int32(alert.textFields!.first!.text!) else {
                                        return
                                    }
                                    self.sql = "DELETE FROM people WHERE id = \(id)"
                                    sqlite3_exec(self.db, self.sql, nil,nil,nil)
                                    self.select()
        })
        
        alert.addAction(btCancel)
        alert.addAction(btOK)
        present(alert, animated: true, completion: nil)
    }
    

}

