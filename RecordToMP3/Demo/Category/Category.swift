//
//  Category.swift
//  RecordToMP3
//
//  Created by 周鑫 on 2017/9/25.
//  Copyright © 2017年 周鑫. All rights reserved.
//

import Foundation

extension Timer {
    func pauseTimer() {
        //如果已被释放则return！isValid对应invalidate
        if !isValid { return }
        //启动时间为很久以后
        fireDate = Date.distantFuture
    }
    
    func continueTimer() {
        if !isValid { return }
        fireDate = Date()
    }
}
