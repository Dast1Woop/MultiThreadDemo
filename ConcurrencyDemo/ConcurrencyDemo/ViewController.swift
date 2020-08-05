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
    
    class func downloadImageWithURL(url:String,  block:@escaping(UIImage?) ->  Void)  {
        
        let data = NSData(contentsOf: NSURL(string: url)! as URL)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didClickOnStart(sender: AnyObject) {
        concurrentQueueMethod()
//        serialQueueMethod()
    }
    
   private func serialQueueMethod(){
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
                Downloader.downloadImageWithURL(url: imageURLs[i]) { (img) in
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
    
   private func concurrentQueueMethod(){
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
                Downloader.downloadImageWithURL(url: imageURLs[i]) { (img) in
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

