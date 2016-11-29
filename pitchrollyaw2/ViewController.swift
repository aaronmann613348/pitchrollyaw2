//
//  ViewController.swift
//  pitchrollyaw2
//
//  Created by Aaron Mann on 11/27/16.
//  Copyright © 2016 Aaron Mann. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreMotion
class ViewController: UIViewController {

var matrix = [[Double]] (count:100, repeatedValue:[Double](count:100, repeatedValue:0))
    
var acc_x : [Double] = []
var acc_z : [Double] = []
var acc_y : [Double] = []
var iteration : Int = 1
    
var pitch : [Double] = []
var roll : [Double] = []
var yaw : [Double] = []
var steps_total : Double = 0
var loc_1 : Double = 50
var loc_2 : Double = 50
var turns : [Double] = []
    
@IBOutlet var loc_1_: UITextField!
@IBOutlet var loc_2_: UITextField!
    
var turn_time : [Double] = []
var gyro_x : [Double] = []
var gyro_z : [Double] = []
var gyro_y : [Double] = []

@IBOutlet var steps_label: UITextField!
@IBOutlet var motion_type: UITextField!
    
let motionManager = CMMotionManager()


    override func viewDidLoad() {
        
        motionManager.gyroUpdateInterval = 0.025
        motionManager.accelerometerUpdateInterval = 0.025
        motionManager.deviceMotionUpdateInterval = 0.025
        motionManager.magnetometerUpdateInterval = 0.025
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func start(sender: AnyObject) {
        
        
        
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!) { (accelerometerData: CMAccelerometerData?, NSError) -> Void in
                self.outputAccData(accelerometerData!.acceleration)
                if(NSError != nil) {
                    print("\(NSError)")
                }
            }
            
            motionManager.startGyroUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
                self.outputGyroData(gyroData!.rotationRate)
                if (NSError != nil){
                    print("\(NSError)")
                }
                
                
            })
            
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: {
                (deviceMotion, error) -> Void in
                self.outputRotationData(deviceMotion!)
                if(error != nil){
                    print("\(error)")
                }
            })
        }
    
    
    @IBAction func stop(sender: AnyObject) {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        self.loc_1_.text = String(loc_1)
        self.loc_2_.text = String(loc_2)
    }
    
    func analyze(){
        var steps : Double = get_steps(acc_y, z: acc_z)
        steps_total += steps
        NSLog("steps total : %f", steps_total)
        NSLog("steps: %f", steps)
        self.steps_label.text = String(steps_total)
        get_turns()
        for element in turns{
            print(element)
        }
        endpoint("t", steps: steps)
        acc_x = []
        acc_y = []
        acc_z = []
        yaw = []
        turns = []
    }
    func endpoint(ver:String, steps: Double){
        if ver == "t" {
            var x_step : Double = 0
            var y_step : Double = 0
            var next_angle : Double = 0
            if turns.count == 0 {  /////might not be correct what if the angle is not face
                x_step += steps*cos(yaw[0]*M_PI/180)
                NSLog("x steps: %f", x_step)
                y_step += steps*sin(yaw[0]*M_PI/180)
                NSLog("y steps: %f", y_step)
            }
            else {
                var last : Double = 0
                for var i : Int = 0; i < turns.count; i++ {
                    next_angle = yaw[Int(turns[i])]
                    NSLog("next angle: %f", next_angle)
                    x_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(yaw.count)
                    NSLog("turns[i] - last: %f", turns[i]-last)
                    NSLog("yaw.count: %i", yaw.count)
                    NSLog("steps: %f", steps)
                    NSLog("cos: %f", cos(next_angle*M_PI/180))
                    NSLog("x steps: %f", x_step)
                    y_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(yaw.count)
                    last = Double(i)
                }
            }
            adjust_matrix(x_step, y_step: y_step)
        }
        
    }
    
    func adjust_matrix(x_step: Double, y_step: Double){
        NSLog("HOY")
        NSLog("%f", x_step)
        var x_step = floor(x_step*7.6)
        var y_step = floor(y_step*7.6)
        loc_1 += x_step
        loc_2 += y_step
    }
    
    func get_turns(){
        var start : Double = yaw[0]
        var part_tot : Double = 0
        for var i : Int = 0; i < yaw.count; i++ {
            part_tot = start - yaw[i]
            if abs(part_tot) > 10 {
                turns.append(Double(i))
                NSLog("iteration through yaw: %i", i)
                NSLog("yaw: %f", yaw[i])
                start = yaw[i]
            }
        }
    }
    
    func outputRotationData(rotation:CMDeviceMotion)
    {
        let attitude = rotation.attitude
        pitch.append(180/M_PI*attitude.pitch)
        roll.append(180/M_PI*attitude.roll)
        yaw.append(180/M_PI*attitude.yaw)
        
    }
   
    
    func outputAccData(acceleration: CMAcceleration){
        acc_x.append(acceleration.x)
        acc_y.append(acceleration.y)
        acc_z.append(acceleration.z)
        var steps_thereal : Double = 0
        //steps_thereal = get_steps(acc_y, z: acc_z)
        if iteration%100==0 {
            analyze()
            NSLog("SHIT")
        }
       iteration = iteration + 1
        //self.steps_label.text = String(steps_thereal)

        
    }
    
    func outputGyroData(rotation: CMRotationRate){
        
        gyro_x.append(rotation.x)
        gyro_y.append(rotation.y)
        gyro_z.append(rotation.z)
        
    }
    
    func get_steps(y: [Double], z: [Double])->Double {
        
        
        
        var steps : Double = 0.0
        //var y_sum : Double = 0.0
        var z_sum : Double = 0.0
        
        //y_sum = y.reduce(0, combine: +)
        z_sum = z.reduce(0, combine: +)
        
        //let y_avg : Double = y_sum/Double(y.count)
        let z_avg : Double = z_sum/Double(z.count)
        
        //let y_std : Double = standardDeviation(y)
        let z_std : Double = standardDeviation(z)
        
        //HUH?!?!?!?!?!
        //steps = counter(y, std: y_std, avg: y_avg, plane: "y")
        steps = counter(z, std: z_std, avg: z_avg, plane: "z")
        
        if z_std<0.05{
            return 0
        }
        
        return steps
    }
    
    func standardDeviation(arr : [Double]) -> Double
    {
        
        //MIGHT BE BROKEN AS FUCK
        let length = Double(arr.count)
        let avg = arr.reduce(0, combine: +)/length
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, combine: +)
        return sqrt(sumOfSquaredAvgDiff/length)
        
    }
    
    func counter(var vals: [Double], std: Double, avg: Double, plane: String)->Double{
        
        var counter_up : Double = 0.0
        var counter_down : Double = 0.0
        var step_counter_up : Double = 0.0
        var step_counter_down : Double = 0.0
        
        var up_step : Bool = false
        var down_step : Bool = false
        
        var counter_next : Double = 0.0
        
        let oh_f : Double = 0.4
        
        for var k = 0; k < vals.count; ++k {
            
            if((vals[k]>(avg+std*oh_f))&&(up_step==false)){
                counter_up = counter_up + 1
                
                if(counter_down>0){
                    counter_down = counter_down - 1
                }
            }
            
            if((vals[k]<(avg+std*oh_f))&&(down_step==false)){
                counter_down = counter_down + 1
                
                if(counter_up>0){
                    counter_up = counter_up - 1
                }
                
            }
            
            if((counter_up > 4)&&(up_step==false)){
                step_counter_up  = step_counter_up + 1;
                up_step = true;
                down_step = false;
                
            }
            
            if((counter_down > 4)&&(down_step==false)){
                step_counter_down = step_counter_down + 1;
                if(up_step==true){
                    counter_next = counter_next + 1
                }
                
                up_step = false;
                down_step = true;
            }
            
        }
        
        if plane == "z"{
            return (step_counter_down + step_counter_up*3.0)/4.0
        }
            
        else{
            return (step_counter_down + step_counter_up)/2.0
        }
    }


}

