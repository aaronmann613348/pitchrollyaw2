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

var matrix = [[Double]] (repeating: [Double](repeating: 0, count: 100), count: 100)
    
var acc_x : [Double] = []
var acc_z : [Double] = []
var acc_y : [Double] = []
var iteration : Int = 1
    
    
    var mag_x : [Double] = []
    var mag_z : [Double] = []
    var mag_y : [Double] = []

    let oh_f : Double = 0.5
   
var pitch : [Double] = []
var roll : [Double] = []
var yaw : [Double] = []
var steps_total : Double = 0
var loc_1 : Double = 50
var loc_2 : Double = 50
var turns : [Double] = []
    
    var copy_arr : [Double] = []
    var copy_arr2 : [Double] = []
    var copy_arr3 : [Double] = []
    
@IBOutlet var loc_1_: UITextField!
@IBOutlet var loc_2_: UITextField!
    
    var down_pitch : [Int] = []
    var down_roll : [Int] = []

    // 0 is pitch
    // 1 is roll
    // 2 is yaw
    
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

    @IBAction func start(_ sender: AnyObject) {
        
        
        
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData: CMAccelerometerData?, NSError) -> Void in
                self.outputAccData(accelerometerData!.acceleration)
                if(NSError != nil) {
                    print("\(NSError)")
                }
            }
            
            motionManager.startGyroUpdates(to: OperationQueue.current!, withHandler: { (gyroData: CMGyroData?, NSError) -> Void in
                self.outputGyroData(gyroData!.rotationRate)
                if (NSError != nil){
                    print("\(NSError)")
                }
                
                
            })
        
            motionManager.startMagnetometerUpdates(to: OperationQueue.current!, withHandler: { (magData: CMMagnetometerData?, NSError) -> Void in
            self.outputMagData(magData!.magneticField)
            if(NSError != nil){
                print("\(NSError)")
                }
            })
        
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
                (deviceMotion, error) -> Void in
                self.outputRotationData(deviceMotion!)
                if(error != nil){
                    print("\(error)")
                }
            })
        }
    
    
    @IBAction func stop(_ sender: AnyObject) {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopDeviceMotionUpdates()
        self.loc_1_.text = String(loc_1)
        self.loc_2_.text = String(loc_2)
    }
    
    func analyze(){
        var type : String = " "
        
        var sum_x : Double = 0
        var sum_y : Double = 0
        var sum_z : Double = 0
        var start : Int = 0
        var end : Int = 33
        
        for k in 0 ..< 3 {
                //first 33 elements
            
            
                for i in start ..< end {
                    sum_x += acc_x[i]
                    sum_y += acc_y[i]
                    sum_z += acc_z[i]

                }
                
                if( abs(sum_x)>=abs(sum_y) && abs(sum_x)>=abs(sum_z) ){
                    type = "x"
                    copy_array(acc_x, start: start, end: end)

                }
            
                if( abs(sum_y)>=abs(sum_x) && abs(sum_y)>=abs(sum_z) ){
                    type = "y"
                    copy_array(acc_y, start: start, end: end)

                }
                
                if( abs(sum_z)>=abs(sum_x) && abs(sum_z)>=abs(sum_y) ){
                    type = "z"
                    copy_array(acc_z, start: start, end: end)
                }
                
                var steps = get_steps(copy_arr)
                
                //var dir : Bool = forward_backward(type, start: ((start/99)*yaw.count), end: Int((33/99)*mag_x.count))
                
                let travel : String = travel_axis(type, start: start, end: end, steps: steps)
                NSLog(travel)
                steps_total += steps
                get_turns(type, start_b: ((start/99)*yaw.count), end: Int((end/99)*yaw.count))
                
                //if dir == false {
                //    steps = -steps //
                //}
                
                endpoint(type, steps: steps, dir: travel)
                start += 33
                end += 33
            
                copy_arr = []
                copy_arr2 = []
                copy_arr3 = []
                turns = []

                steps = 0
                sum_x = 0
                sum_y = 0
                sum_z = 0
            
        }
        
        acc_x = []
        acc_y = []
        acc_z = []
        yaw = []
        roll = []
        pitch = []
        turns = []
        mag_x = []
        mag_y = []
        mag_z = []
        
        //not in fucking use
        //down_pitch = []
        //down_roll = []
        
        
    }
    
    func travel_axis(_ type : String, start: Int, end: Int, steps: Double)->String{
        
        var steps1 : Double = 0
        var steps2 : Double = 0
        var travel : String = " "
        
        if type == "x" {
            copy_array2(acc_y, start: start, end: end)
            copy_array3(acc_z, start: start, end: end)
            steps1 = abs(steps - get_steps(copy_arr2))
            steps2 = abs(steps - get_steps(copy_arr3))
            
            if steps1 >= steps2 {
                travel = "z"
            }
            else {
                travel = "y"
            }

        }
        
        if type == "y" {
            copy_array2(acc_x, start: start, end: end)
            copy_array3(acc_z, start: start, end: end)
            steps1 = abs(steps - get_steps(copy_arr2))
            steps2 = abs(steps - get_steps(copy_arr3))
            
            if steps1 >= steps2 {
                travel = "z"
            }
            else {
                travel = "x"
            }
        }
        
        if type == "z" {
            copy_array2(acc_x, start: start, end: end)
            copy_array3(acc_y, start: start, end: end)
            steps1 = abs(steps - get_steps(copy_arr2))
            steps2 = abs(steps - get_steps(copy_arr3))
            
            if steps1 >= steps2 {
                travel = "y"
            }
            else {
                travel = "x"
            }
        }
        
        return travel
    }
    
    
    func forward_backward(_ type : String, start: Int, end: Int)->Bool{
        var dir : Bool = false
        
        if type == "x" {
            var counter : Int = 0
            for i in start ..< Int(floor(Double(mag_x.count)*Double(end/99)))-1 {
                if mag_x[i] > mag_x[i+1] {
                    counter -= counter
                }
                if mag_x[i] < mag_x[i+1] {
                    counter += counter
                }
            }
            
            if counter >= 0 {
                dir = true
            }
        }
        
        if type == "y" {
            var counter : Int = 0
            for i in start ..< Int(floor(Double(mag_y.count)*Double(end/99)))-1 {
                if mag_y[i] > mag_y[i+1] {
                    counter -= counter
                }
                if mag_y[i] < mag_y[i+1] {
                    counter += counter
                }
            }
            
            if counter >= 0 {
                dir = true
            }
            
        }
        
        if type == "z" {
            var counter : Int = 0
            for i in start ..< Int(floor(Double(mag_z.count)*Double(end/99)))-1 {
                if mag_z[i] > mag_z[i+1] {
                    counter -= counter
                }
                if mag_z[i] < mag_z[i+1] {
                    counter += counter
                }
            }
            
            if counter >= 0 {
                dir = true
            }
            
        }
        
        return dir
    }
  
    //Don't think we need this part but saving just in case
    /*func segments(type:String){
        var steps : Double = get_steps(copy_arr)
        steps = floor(steps)
        steps_total += steps
        self.steps_label.text = String(steps_total)
        
        
        get_turns()
        endpoint(type, steps: steps)

    } */
    
    func endpoint(_ ver:String, steps: Double, dir : String){
        if ver == "z" {
            var x_step : Double = 0
            var y_step : Double = 0
            var next_angle : Double = 0
            if turns.count == 0 {  /////might not be correct what if the angle is not face
                if dir == "y" {
                    x_step += steps*cos(yaw[0]*M_PI/180)
                    y_step += steps*sin(yaw[0]*M_PI/180)
                }
                else {
                    x_step += steps*sin(yaw[0]*M_PI/180)
                    y_step += steps*cos(yaw[0]*M_PI/180)
                }
            }
            else {
                var last : Double = 0
                for i : Int in 0 ..< turns.count {
                    next_angle = yaw[Int(turns[i])]
                    
                    if dir == "y" {
                        x_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(yaw.count)
                        y_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(yaw.count)                    }
                    else {
                        x_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(yaw.count)
                        y_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(yaw.count)
                    }
                    last = turns[i]
                }
            }
            adjust_matrix(x_step, y_step: y_step)
        }
        
        
        
        if ver == "y" {
            var x_step : Double = 0
            var y_step : Double = 0
            var next_angle : Double = 0
            if turns.count == 0 {  /////might not be correct what if the angle is not face
                
                if dir == "z" {
                    x_step += steps*cos(roll[0]*M_PI/180)
                    y_step += steps*sin(roll[0]*M_PI/180)
                }
                else {
                    x_step += steps*cos(roll[0]*M_PI/180)
                    y_step += steps*sin(roll[0]*M_PI/180)
                }
            }
            else {
                var last : Double = 0
                for i : Int in 0 ..< turns.count {
                    next_angle = roll[Int(turns[i])]
                    if dir == "z" {
                        x_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(roll.count)
                        y_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(roll.count)
                    }
                    else {
                        y_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(roll.count)
                        x_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(roll.count)
                    }
                    last = turns[i]
                }
            }
            adjust_matrix(x_step, y_step: y_step)
        }
        
        if ver == "x" {
            var x_step : Double = 0
            var y_step : Double = 0
            var next_angle : Double = 0
            if turns.count == 0 {  /////might not be correct what if the angle is not face
                
                if dir == "z" {
                    x_step += steps*cos(pitch[0]*M_PI/180)
                    y_step += steps*sin(pitch[0]*M_PI/180)
                }
                else {
                    y_step += steps*cos(pitch[0]*M_PI/180)
                    x_step += steps*sin(pitch[0]*M_PI/180)
                }
            }
            else {
                var last : Double = 0
                for i : Int in 0 ..< turns.count {
                    next_angle = pitch[Int(turns[i])]
                    
                    if dir == "z" {
                        x_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(pitch.count)
                        y_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(pitch.count)                    }
                    else {
                        y_step += (turns[i]-last)*steps*cos(next_angle/180*M_PI)/Double(pitch.count)
                        x_step += (turns[i]-last)*steps*sin(next_angle*M_PI/180)/Double(pitch.count)
                    }
                    last = turns[i]
                }
            }
            adjust_matrix(x_step, y_step: y_step)
        }
        
    }
    
    func adjust_matrix(_ x_step: Double, y_step: Double){
        
        let x_step = floor(x_step*7.6)
        let y_step = floor(y_step*7.6)
        loc_1 += x_step
        loc_2 += y_step
    }
    
    func get_turns(_ type: String, start_b: Int, end: Int){
        
        if type == "z" {

            var start : Double = yaw[start_b]
            var part_tot : Double = 0
            for i : Int in start_b ..< end {
                part_tot = start - yaw[i]
                if abs(part_tot) > 15 {
                    turns.append(Double(i))
                    start = yaw[i]
                }
            }
        }
        if type == "y" {
            
            var start : Double = roll[start_b]
            var part_tot : Double = 0
            for i : Int in start_b ..< end {
                part_tot = start - roll[i]
                if abs(part_tot) > 30 {
                    turns.append(Double(i))
                    start = roll[i]
                }
            }
            
        }
            
        if type == "x" {
            
            var start : Double = pitch[start_b]
            var part_tot : Double = 0
            for i : Int in start_b ..< end {
                part_tot = start - pitch[i]
                if abs(part_tot) > 15 {
                    turns.append(Double(i))
                    //NSLog("iteration through yaw: %i", i)
                    //NSLog("yaw: %f", roll[i])
                    start = roll[i]
                }
            }
                
        }
        
        
        
    }
    
    func outputRotationData(_ rotation:CMDeviceMotion)
    {
        let attitude = rotation.attitude
        print("pitch", 180/M_PI*attitude.pitch)
        print("roll", 180/M_PI*attitude.roll)
        print("yaw", 180/M_PI*attitude.yaw)


        pitch.append(180/M_PI*attitude.pitch)
        roll.append(180/M_PI*attitude.roll)
        yaw.append(180/M_PI*attitude.yaw)
        
    }
   
    
    func outputAccData(_ acceleration: CMAcceleration){
        acc_x.append(acceleration.x)
        acc_y.append(acceleration.y)
        acc_z.append(acceleration.z)

        if iteration%99==0 {
            analyze()
            self.steps_label.text = String(steps_total)
        }
       iteration = iteration + 1


        
    }
    
    func outputMagData(_ mag: CMMagneticField){
        
        mag_x.append(mag.x)
        mag_y.append(mag.y)
        mag_z.append(mag.z)
    
    }
    
    func outputGyroData(_ rotation: CMRotationRate){
        
        gyro_x.append(rotation.x)
        gyro_y.append(rotation.y)
        gyro_z.append(rotation.z)
        
    }
    
    func get_steps(_ z: [Double])->Double {
        
        
        
        var steps : Double = 0.0
        var z_sum : Double = 0.0
        
        z_sum = z.reduce(0, +)
        
        let z_avg : Double = z_sum/Double(z.count)
        
        let z_std : Double = standardDeviation(z)
        
        steps = counter(z, std: z_std, avg: z_avg, plane: "z")
        
        if z_std<0.05{
            return 0
        }
        
        return steps
    }
    
    func standardDeviation(_ arr : [Double]) -> Double
    {
        
        //MIGHT BE BROKEN AS FUCK
        let length = Double(arr.count)
        let avg = arr.reduce(0, +)/length
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, +)
        return sqrt(sumOfSquaredAvgDiff/length)
        
    }
    
    func counter(_ vals: [Double], std: Double, avg: Double, plane: String)->Double{
        var vals = vals
        
        var counter_up : Double = 0.0
        var counter_down : Double = 0.0
        var step_counter_up : Double = 0.0
        var step_counter_down : Double = 0.0
        
        var up_step : Bool = false
        var down_step : Bool = false
        
        var counter_next : Double = 0.0
        //
        
        for k in 0 ..< vals.count {
            
            if((vals[k]>(avg+std*oh_f))&&(up_step==false)){
                counter_up = counter_up + 1
                
                if(counter_down>0){
                    counter_down = counter_down - 1
                }
            }
            
            if((vals[k]<(avg-std*oh_f))&&(down_step==false)){
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

    //not in use
    
    func where_down(){
        var roll_flag = false
        var pitch_flag = false
        var counter = 0
        var start = 0
        var end = 0
        
        var counter_r = 0
        var start_r = 0
        var end_r = 0
        
        for i in 0 ..< pitch.count {
            
            if pitch[i] > 45 || pitch[i] < -45 {
                if pitch_flag == false {
                    start = i
                    pitch_flag = true
                    counter += 1
                }
                else{
                    counter += 1
                    if counter >= 30 {
                        end = i
                    }
                }
            }
            else {
                if pitch_flag == true && counter >= 30 {
                    down_pitch.append(start)
                    down_pitch.append(end)
                }
                pitch_flag = false
                counter = 0
                start = 0
                end = 0
            }
        }
        
        for i in 0 ..< roll.count {

            if (roll[i] < -45 && roll[i] > -135) || (roll[i]>45 && roll[i]<135) {
                if roll_flag == false {
                    start_r = i
                    pitch_flag = true
                    counter_r += 1
                }
                else{
                    counter_r += 1
                    if counter_r >= 30 {
                        end_r = i
                    }
                }
            }
            else {
                if roll_flag == true && counter_r >= 30 {
                    down_roll.append(start_r)
                    down_roll.append(end_r)
                    }
                    roll_flag = false
                    counter_r = 0
                    start_r = 0
                    end_r = 0
                }

        }
        
    }//end of func
    
    
    func copy_array(_ x: [Double], start: Int, end: Int){
        
        for i in start  ..< end {
            copy_arr.append(x[i])
        }
        
    }
    
    func copy_array2(_ x: [Double], start: Int, end: Int){
        
        for i in start  ..< end {
            copy_arr2.append(x[i])
        }
        
    }
    
    func copy_array3(_ x: [Double], start: Int, end: Int){
        
        for i in start  ..< end {
            copy_arr3.append(x[i])
        }
        
    }
    
}

