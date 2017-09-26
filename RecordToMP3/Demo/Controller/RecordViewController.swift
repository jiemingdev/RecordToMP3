//
//  RecordViewController.swift
//  RecordToMP3
//
//  Created by 周鑫 on 2017/9/19.
//  Copyright © 2017年 周鑫. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    
    let TimerLabelH : CGFloat = 80.0
    let startBtnWidth : CGFloat = 120.0
    let otherBtnWidth : CGFloat = 60.0
    let btnSpace : CGFloat = 20.0
    var second = 0
    
    var timerLabel : UILabel!
    var timer : Timer!
    
    var saveBtn : UIButton!
    var startBtn : UIButton!
    var deleteBtn : UIButton!
    
    var recorder : AVAudioRecorder!
    var session : AVAudioSession!
    var recordFilePath : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        initNavUI()
        initUI()
        addBtns()
    }
    
    func initNavUI() {
        title = "录音"
        
        let listItem = UIBarButtonItem(title: "目录", style: .plain, target: self, action:#selector(pushToListCtrl))
        navigationItem.rightBarButtonItem = listItem;
    }

    func initUI() {
        
        timerLabel = UILabel(frame: CGRect(x: 20.0, y: 150.0, width: kScreenWidth - 40, height: TimerLabelH))
        timerLabel.text = "00 : 00"
        timerLabel.textAlignment = .center
        timerLabel.textColor = .black
        timerLabel.font = UIFont.systemFont(ofSize: CGFloat(TimerLabelH))
        view.addSubview(timerLabel)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (s_timer) in
            self.second += 1
            if self.second == 1 {
                self.enbleBtn()
            }
            let timerStr = self.convertTimeToString(second: self.second)
            self.timerLabel.text = timerStr;
        })
    }
    
    func addBtns() {
        startBtn = UIButton(type: .custom)
        startBtn.frame = CGRect(x: 0.0, y: 0.0, width: 75.0, height: 75.0)
        startBtn.center = CGPoint(x: kScreenWidth / 2, y: kScreenHeight - 100)
        startBtn.setImage(UIImage(named: "camera_hightlighted_150x150_"), for: .normal)
        startBtn.addTarget(self, action: #selector(startRecord(_ :)), for: .touchUpInside)
        view.addSubview(startBtn)
        
        deleteBtn = UIButton(type: .custom)
        deleteBtn.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        deleteBtn.center = CGPoint(x: kScreenWidth / 2 - 100, y: kScreenHeight - 100)
        deleteBtn.setImage(UIImage(named: "record_deletesure_normal_60x60_"), for: .normal)
        deleteBtn.addTarget(self, action: #selector(deleteRecord(_ :)), for: .touchUpInside)
        view.addSubview(deleteBtn)
        
        saveBtn = UIButton(type: .custom)
        saveBtn.frame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
        saveBtn.center = CGPoint(x: kScreenWidth / 2 + 100, y: kScreenHeight - 100)
        saveBtn.setImage(UIImage(named: "finishOKClick_53x53_"), for: .normal)
        saveBtn.addTarget(self, action: #selector(saveRecord(_ :)), for: .touchUpInside)
        view.addSubview(saveBtn)
        
        recordFilePath = NSTemporaryDirectory() + "record.caf"
    }
    
    func enbleBtn() {
        
    }
    
    func unenbleBtn() {
        
    }
    
    @objc func startRecord(_ btn: UIButton) {
        
        session = AVAudioSession.sharedInstance()

        session.requestRecordPermission { (granted) in
            if granted {
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        if (btn.isSelected) {
                            btn.setImage(UIImage(named: "camera_hightlighted_150x150_"), for: .normal)
                            btn.isSelected = false
                            self.pause()
                        } else {
                            btn.setImage(UIImage(named: "video_longvideo_btn_pause1_150x150_"), for: .normal)
                            btn.isSelected = true
                            self.start()
                        }
                    }
                }
            } else {
                let alertCtrl = UIAlertController(title: "麦克风不可用", message: "请在“设置 - 隐私 - 麦克风”中允许思美访问你的麦克风", preferredStyle: .alert)
                let openAction = UIAlertAction(title: "前往开启", style: .default, handler: { (action: UIAlertAction) -> Void in
                    let url = URL(string: UIApplicationOpenSettingsURLString)
                    
                    if UIApplication.shared.canOpenURL(url!) {
                        // 判断当前iOS操作系统版本
                        if #available(iOS 10.0, *) {
                            // iOS 10 以上
                            UIApplication.shared.open(url!, options: Optional.none!, completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url!)
                        }
                    }
                })
                let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                alertCtrl.addAction(openAction)
                alertCtrl.addAction(cancelAction)
                self.present(alertCtrl, animated: true, completion: nil)
            }
        }
    }
    
    @objc func deleteRecord(_ btn: UIButton) {
        deleteFile(fileName: recordFilePath)
        resetRecord()
    }
    
    @objc func saveRecord(_ btn: UIButton) {
        let fileSize = fileSizeAtPath(filePath: recordFilePath)
        print(fileSize)
        let dict = TransformMP3.transformCAF(toMP3: recordFilePath)
        let filePath = dict!["filePath"]
        let fileName = dict!["fileName"]

        saveData(filePath: filePath as! String, fileName: fileName as! String)
        
        resetRecord()
    }
    
    @objc func pushToListCtrl() {
        let listCtrl = RecordListViewController()
        navigationController?.pushViewController(listCtrl, animated: true)
    }
    
    func start() {
        // 设置后台播放,下面这段是录音和播放录音的设置
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
        
        //判断后台有没有播放
        if timer == nil || !timer.isValid {
            startTimer()
        } else {
            timer.continueTimer()
        }
        
        if recorder == nil {
            
            // 所有的值都要转成NSNumber类型，否则无法开始录音？？
            let settings = [AVFormatIDKey : NSNumber(value: kAudioFormatLinearPCM), AVSampleRateKey : NSNumber(value: 11025.0), AVNumberOfChannelsKey : NSNumber(value: 2), AVEncoderBitDepthHintKey : NSNumber(value: 16), AVEncoderAudioQualityKey : NSNumber(value: AVAudioQuality.high.rawValue)] as [String : Any]
            
            //开始录音,将所获取到得录音存到文件里
            let recordUrl = URL(fileURLWithPath: recordFilePath)
            do {
                recorder = try AVAudioRecorder(url: recordUrl, settings: settings)
                //准备记录录音
                recorder.prepareToRecord()
                //开启仪表计数功能,必须开启这个功能，才能检测音频值
                recorder.isMeteringEnabled = true
                //启动或者恢复记录的录音文件
                if (!recorder.isRecording) {
                    recorder.record()
                    print(recorder.isRecording)
                }
            } catch {
                
            }
            
            /*
             * settings 参数
             1.AVNumberOfChannelsKey 通道数 通常为双声道 值2
             2.AVSampleRateKey 采样率 单位HZ 通常设置成44100 也就是44.1k,采样率必须要设为11025才能使转化成mp3格式后不会失真
             3.AVLinearPCMBitDepthKey 比特率 8 16 24 32
             4.AVEncoderAudioQualityKey 声音质量
             ① AVAudioQualityMin  = 0, 最小的质量
             ② AVAudioQualityLow  = 0x20, 比较低的质量
             ③ AVAudioQualityMedium = 0x40, 中间的质量
             ④ AVAudioQualityHigh  = 0x60,高的质量
             ⑤ AVAudioQualityMax  = 0x7F 最好的质量
             5.AVEncoderBitRateKey 音频编码的比特率 单位Kbps 传输的速率 一般设置128000 也就是128kbps
             
             */
        }
    }
    
    func pause() {
        //录音状态 点击录音按钮 停止录音
        
        //停止录音
        recorder.pause()
        timer.pauseTimer()
        do {
            try session.setActive(true)
        } catch {
            print("麦克风出错")
        }

        let pathSize = fileSizeAtPath(filePath: recordFilePath);
        print(pathSize);
    }
    
    func stop() {
        timer.invalidate()
        recorder.stop()
        recorder = nil
        do {
            try session.setActive(false)
        } catch {
            
        }
        startBtn.setImage(UIImage(named: "camera_hightlighted_150x150_"), for: .normal)
    }
    
    func deleteFile(fileName: String) {
        
        let fileManager = FileManager.default
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        //文件名
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
    
    func saveData(filePath: String, fileName: String) {
    
        var fileSize = fileSizeAtPath(filePath: filePath)
        print(fileSize);
    
        var fileSizeStr = ""
        
        if (fileSize < 1024) {
            fileSizeStr = String(fileSize) + "B"
        } else if (fileSize < 1024 * 1024) {
        
            fileSize =  fileSize / 1024
            fileSizeStr = String(fileSize) + "KB"
        } else if (fileSize < 1024 * 1024 * 1024) {
        
            fileSize =  fileSize / 1024 / 1024
            fileSizeStr = String(fileSize) + "MB"
        }
    
        let createTime = nowTime()
        let model = RecordModel()
        model.fileName = "录音";
        model.fileSize = fileSizeStr;
        model.recordTime = convertTimeToString(second: second)
        model.createTime = createTime;
        model.filePath = fileName;
        let manager = DBManager.shareManager
        manager.addRecordModel(model: model)
    }
    
    
    func resetRecord() {
        second = 0
        timerLabel.text = "00 : 00"
        self.stop()
        startBtn.isSelected = false
    }
    
//    CLongLog 等于OC中的long long 等于 Int64
    func fileSizeAtPath(filePath: String) -> CLongLong {
        
        let manager = FileManager.default
        if manager.fileExists(atPath: filePath) {
            do {
                let item = try manager.attributesOfItem(atPath: filePath)
                return item[FileAttributeKey.size] as! CLongLong
            } catch {
                
            }
        }
        return 0;
    }
    
    //规范计时器时间格式
    func convertTimeToString(second: NSInteger) -> String {
    
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        var date = formatter.date(from: "00:00")
        date = date?.addingTimeInterval(TimeInterval(second))
        let timerStr = formatter.string(from: date!)
        return timerStr
    }
    
    func nowTime() -> String {
        let format = DateFormatter()
        format.dateFormat = "yy-MM-dd_HH:mm:ss";
        let time = format.string(from: Date())
        return time;
    }

}
