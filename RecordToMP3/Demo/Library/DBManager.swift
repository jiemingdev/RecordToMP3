//
//  DBManager.swift
//  RecordToMP3
//
//  Created by 周鑫 on 2017/9/25.
//  Copyright © 2017年 周鑫. All rights reserved.
//

import UIKit
import FMDB

class DBManager: NSObject {
    
    var dataBase = FMDatabase()

    // 创建单例 http://www.cocoachina.com/swift/20151207/14584.html
    static let shareManager : DBManager = DBManager()
    private override init() {
        super.init()
        initDataBase()
    }
    
    func initDataBase() {
        let path = NSHomeDirectory() + "/Library/Caches/record_swift.sqlite"
        dataBase = FMDatabase(path: path)
        let ret = dataBase.open();
        if ret {
            //录音表myRecord
            let recordSql = "create table if not exists myRecord (kRecordId integer primary key autoincrement, fileSize varchar(255), createTime varchar(255), recordTime varchar(255), fileName varchar(255), filePath varchar(255))"
            do {
                try dataBase.executeUpdate(recordSql, values: nil)
            } catch {
                print(dataBase.lastErrorMessage());
            }
        } else {
            print(dataBase.lastErrorMessage());
            print("打开数据库失败");
        }
        dataBase.close()
    }
    
    func addRecordModel(model: RecordModel) {
    
        let ret = dataBase.open()
        if ret {
            let sql = "insert into myRecord (fileSize, createTime, recordTime, fileName, filePath) values (?, ?, ?, ?, ?)"
            
            if dataBase.executeUpdate(sql, withArgumentsIn:[model.fileSize, model.createTime, model.recordTime, model.fileName, model.filePath ?? String.self]) {
                print("插入数据成功")
            } else {
                print("插入数据失败")
            }
        }
        dataBase.close()
    }
    
    func searchAllRecordData() -> Array<Any> {
        let ret = dataBase.open()
        var array = Array<Any>()
        if ret {
        
            let sql = "select * from myRecord order by kRecordId desc";
            do {
            let rs =  try dataBase.executeQuery(sql, values: nil)
                while rs.next() {
                
                    let model = RecordModel()
                    model.fileSize = rs.string(forColumn: "fileSize")
                    model.createTime = rs.string(forColumn: "createTime")
                    model.recordTime = rs.string(forColumn: "recordTime")
                    model.fileName = rs.string(forColumn: "fileName")
                    model.filePath = rs.string(forColumn: "filePath")
                    array.append(model)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        dataBase.close()
        return array
    }
    
    func deleteAllRecordData() {
    
        let ret = dataBase.open()
        if ret {
        
            dataBase.executeUpdate("DELETE FROM myRecord", withArgumentsIn: Optional.none!)
            dataBase.executeUpdate("UPDATE sqlite_sequence set seq=0 where name='myRecord'", withArgumentsIn: Optional.none!)
        }
        dataBase.close()
    }
    
    func deleteRecord(filePath : String) {
    
        let ret = dataBase.open()
        if ret {
        
            let flag = dataBase.executeUpdate("delete from myRecord where filePath = ?", withArgumentsIn: [filePath])
            if !flag {
                print(dataBase.lastErrorMessage())
            }
        }
        dataBase.close()
    }

}



