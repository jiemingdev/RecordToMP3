//
//  RecordListViewController.swift
//  RecordToMP3
//
//  Created by 周鑫 on 2017/9/19.
//  Copyright © 2017年 周鑫. All rights reserved.
//

import UIKit
import AVFoundation

class RecordListViewController: UIViewController {

    lazy var dataArray = {[]}()
    var tableView : UITableView!
    let cellId = "recordCellId"
    
    var lastIndex = 0
    var isPlaying = false
    
    var player : AVAudioPlayer!
    var session : AVAudioSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        title = "录音列表"
        session = AVAudioSession.sharedInstance()
        addTableView()
        addData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        stop()
    }

    func addTableView() {
        tableView = UITableView(frame: CGRect(x: 0, y: 64, width: kScreenWidth, height: kScreenHeight - 64), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier:cellId)
        view.addSubview(tableView)
    }
    
    func addData() {
        let manager = DBManager.shareManager
        let array = manager.searchAllRecordData()
        // 相当于 addObjectsFromArray
        dataArray += array
    }
    
    func stop() {
        isPlaying = false
        if player != nil {
            player.stop()
        }
        do {
            try session.setActive(false)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func play(filePath: String) {
        let absolutionFilePath = NSHomeDirectory() + "/Documents" + filePath
        let url = URL(string: absolutionFilePath)
        do {
            try player = AVAudioPlayer(contentsOf: url!)
            player.delegate = self
            player.play()
            try session.setActive(true)
            isPlaying = true
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func deleteFile(fileName: String) {
        
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        // 文件名
        let uniquePath = paths[0] + fileName
        let isExist = fileManager.fileExists(atPath: uniquePath)
        if (!isExist) { return }
        
        do {
            try fileManager.removeItem(atPath: uniquePath)
            print("delete success")
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension RecordListViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension RecordListViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier:cellId)
        let model = dataArray[indexPath.row] as! RecordModel
        cell.textLabel?.text = model.fileName + "     " + model.createTime
        cell.detailTextLabel?.text = model.recordTime + "      " + model.fileSize
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if lastIndex != indexPath.row {
            // 点击别的录音，停止当前录音，播放这个录音
            stop()
            let model = dataArray[indexPath.row] as! RecordModel
            play(filePath: model.filePath)
            print(player.isPlaying)
        } else {
            // 点击当前录音
            if isPlaying {
                // 当前正在播放，则暂停
                isPlaying = false
                player.pause()
                print(player.isPlaying)

            } else {
                // 当前在暂停或还没开始播放，则播放
                isPlaying = true
                player.play()
//                let model = dataArray[indexPath.row] as! RecordModel
//                play(filePath: model.filePath)
//                print(player.isPlaying)

            }
        }
        lastIndex = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let manager = DBManager.shareManager
        let model = self.dataArray[indexPath.row] as! RecordModel;
        let deleteRowAction = UITableViewRowAction(style: .destructive, title: "删除", handler: { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.dataArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .bottom)
            manager.deleteRecord(filePath: model.filePath)
            self.deleteFile(fileName: model.filePath)
        })
        return [deleteRowAction];
    }
}

extension RecordListViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if (flag) {
            isPlaying = false
            do {
                try session.setActive(false)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}
