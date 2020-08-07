//
//  ViewController.swift
//  ConcurrencyDemo
//
//  Created by Hossam Ghareeb on 11/15/15.
//  Copyright © 2015 Hossam Ghareeb. All rights reserved.
//

import UIKit

let imageURLs = ["http://www.planetware.com/photos-large/F/france-paris-eiffel-tower.jpg"
    , "http://adriatic-lines.com/wp-content/uploads/2015/04/canal-of-Venice.jpg"
    , "http://seopic.699pic.com/photo/50053/9342.jpg_wh1200.jpg"
    , "http://seopic.699pic.com/photo/40005/7496.jpg_wh1200.jpg"]

class Downloader {
    
    class func downloadImageWithURLStr(urlStr:String,  block:@escaping(UIImage?) ->  Void)  {
        
        let data = NSData(contentsOf: NSURL(string: urlStr)! as URL)
        if let lD = data{
            let lImg = UIImage(data: lD as Data)
//            DispatchQueue.main.async {
                block(lImg)
//            }
        }
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView1: UIImageView!
    
    @IBOutlet weak var imageView2: UIImageView!
    
    @IBOutlet weak var imageView3: UIImageView!
    
    @IBOutlet weak var imageView4: UIImageView!
    
    @IBOutlet weak var sliderValueLabel: UILabel!
    
    lazy var gOpeQueue: OperationQueue = {
        let lQ = OperationQueue.init()
        return lQ
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    deinit {
        gOpeQueue.cancelAllOperations()
        print("die:%@",self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickOnStart(sender: AnyObject) {
//        concurrentExcuteByGCD()
//        serialExcuteByGCD()
        serialExcuteByOperationQueue()
//        concurrentExcuteByOperationQueue()
    }
    
    ///暂停队列，只对非执行中的任务有效。本例中对串行队列的效果明显。并行队列因4个任务一开始就很容易一起开始执行，即使挂起也无法影响已处于执行状态的任务。
    @IBAction func pauseQueueItemDC(_ sender: Any) {
        gOpeQueue.isSuspended = true
    }
    
    ///恢复队列，之前未开始执行的任务会开始执行
    @IBAction func resumeQueueItemDC(_ sender: Any) {
       gOpeQueue.isSuspended = false
    }
    
    /*log:
     第0个加入队列
     第0个下载成功
     第0个开始显示
     第1个加入队列
     第1个下载成功
     第1个开始显示
     第2个加入队列
     第2个下载成功
     第2个开始显示
     第3个加入队列
     第3个下载成功
     第3个开始显示
     */
    private func serialExcuteByOperationQueue() {
        
        //串行效果
        gOpeQueue.maxConcurrentOperationCount = 1
        
        concurrentExcuteByOperationQueue()
    }
    
    /*log:
    第0个加入队列
    第1个加入队列
    第2个加入队列
    第3个加入队列
    第2个下载成功
    第2个开始显示
    第0个下载成功
    第0个开始显示
    第3个下载成功
    第3个开始显示
    第1个下载成功
    第1个开始显示
     */
    private func concurrentExcuteByOperationQueue() {
        let lArr : [UIImageView] = [imageView1, imageView2, imageView3, imageView4]
        
        for i in 0..<lArr.count{
            let lImgV = lArr[i]
            
            //清空旧图片
            lImgV.image = nil
            
            //为何没有循环引用？self->gOpeQueue->OperationBlock->imageView1->self。A:其实是有的，通过instrument可以验证。只是，队列在执行完毕操作后，会自动释放操作对象，自动解除循环引用。
            /*验证方法二：进入此页面，点击开始，立刻返回。看log：
             第0个加入队列
             Optional(<UIImageView: 0x7fc9cb602ac0; frame = (0 0; 187.5 110.5); autoresize = RM+BM; userInteractionEnabled = NO; layer = <CALayer: 0x600000b7d8e0>>)
             第0个下载成功
             第1个加入队列
             Optional(<UIImageView: 0x7fc9cb602ac0; frame = (0 0; 187.5 110.5); autoresize = RM+BM; userInteractionEnabled = NO; layer = <CALayer: 0x600000b7d8e0>>)
             第0个开始显示
             第1个下载成功
             第1个开始显示
             第2个加入队列
             Optional(<UIImageView: 0x7fc9cb602ac0; frame = (0 0; 187.5 110.5); opaque = NO; autoresize = RM+BM; userInteractionEnabled = NO; layer = <CALayer: 0x600000b7d8e0>>)
             第2个下载成功
             第2个开始显示
             第3个加入队列
             Optional(<UIImageView: 0x7fc9cb602ac0; frame = (0 0; 187.5 110.5); opaque = NO; autoresize = RM+BM; userInteractionEnabled = NO; layer = <CALayer: 0x600000b7d8e0>>)
             第3个下载成功
             第3个开始显示
             die:%@ <ConcurrencyDemo.ViewController: 0x7fc9cb5174b0>
             */
            gOpeQueue.addOperation {
                print("第\(i)个加入队列")
                
                //当把下面注释掉时，是没有循环引用的。进入此页面，点击开始，立刻返回。看log即可发现，未开始执行的操作都没有执行，vc很快就deinit了。
                print(self.imageView1 as Any)
                
                Downloader.downloadImageWithURLStr(urlStr: imageURLs[i]) { (img) in
                    print("第\(i)个下载成功")
                    DispatchQueue.main.async {
                        print("第\(i)个开始显示")
                        lImgV.image = img
                    }
                }
            }
        }
    }
    
   private func serialExcuteByGCD(){
        let lArr : [UIImageView] = [imageView1, imageView2, imageView3, imageView4]
        
        //串行队列，异步执行时，只开一个子线程
        let serialQ = DispatchQueue.init(label: "com.ht.serial.downImage")
        
        for i in 0..<lArr.count{
            let lImgV = lArr[i]
            
            //清空旧图片
            lImgV.image = nil
            
         //注意，防坑：串行队列创建的位置,在这创建时，每个循环都是一个新的串行队列，里面只装一个任务，多个串行队列，整体上是并行的效果。
            //            let serialQ = DispatchQueue.init(label: "com.ht.serial.downImage")
            
            /*由log可知，切到主线程也需要时间，切换完成之前，指令可能已经执行到下个循环了。但是看起来图片还是依次下载完成和显示的，因为每一张图切到主线程显示都需要时间。
            第0个 开始
            第0个 结束
            第1个 开始
            第0个 更新图片
            第1个 结束
            第2个 开始
            第1个 更新图片
            第2个 结束
            第3个 开始
            第2个 更新图片
            第3个 结束
            第3个 更新图片
             */
            serialQ.async {
                
                print("第\(i)个 开始，%@",Thread.current)
                Downloader.downloadImageWithURLStr(urlStr: imageURLs[i]) { (img) in
                    let lImgV = lArr[i]
                    
                    print("第\(i)个 结束")
                    DispatchQueue.main.async {
                        print("第\(i)个 切到主线程更新图片")
                        lImgV.image = img
                    }
                    if nil == img{
                        print("第\(i+1)个img is nil")
                    }
                }
            }
        }
    }
    
   private func concurrentExcuteByGCD(){
        let lArr : [UIImageView] = [imageView1, imageView2, imageView3, imageView4]
        
        for i in 0..<lArr.count{
            let lImgV = lArr[i]
            
            //清空旧图片
            lImgV.image = nil
            
            //方法一、并行队列。图片下载任务按顺序开始，但是是并行执行，不会相互等待，任务结束和图片显示顺序是无序的，多个子线程同时执行，性能更佳。
            /*log:
             第0个开始，%@ <NSThread: 0x600002de2e00>{number = 4, name = (null)}
             第1个开始，%@ <NSThread: 0x600002dc65c0>{number = 6, name = (null)}
             第2个开始，%@ <NSThread: 0x600002ddc8c0>{number = 8, name = (null)}
             第3个开始，%@ <NSThread: 0x600002d0c8c0>{number = 7, name = (null)}
             第0个结束
             第3个结束
             第1个结束
             第2个结束
             */
            DispatchQueue.global(qos: .background).async {
                print("第\(i)个开始，%@", Thread.current)
                Downloader.downloadImageWithURLStr(urlStr: imageURLs[i]) { (img) in
                    let lImgV = lArr[i]
                      print("第\(i)个结束")
                    DispatchQueue.main.async {
                        lImgV.image = img
                    }
                    if nil == img{
                        print("第\(i+1)个img is nil")
                    }
                }
            }
        }
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        
        self.sliderValueLabel.text = "\(sender.value * 100.0)"
    }
    
}

