//
//  ViewController.swift
//  Test
//
//  Created by Bryan_Wu on 2022/6/1.
//

import UIKit

struct Captcha: Decodable {
    let key: String
    let wall: String
    let piece: String
    let offsetY: Int
}

struct LogInBody: Encodable {
    let device: String
    let login_id: String
    let password: String
    let device_id: String
    let captcha_key: String
    let captcha_x: Int
    let version: String
    
}

struct LogInResponse: Decodable {
    let code: Int
    let msg: String
    let data: Info
}

struct Info: Codable {
    let device: String
    let device_id: String
    let email: String
    let email_name: String
    let token: String
    let username: String
}


class LogInViewController: UIViewController {
    
    @IBOutlet weak var m_imgWall: UIImageView!
    @IBOutlet weak var m_imgDrag: UIImageView!
    @IBOutlet weak var m_vDrag: UIView!
    
    let m_imgPiece: UIImageView = UIImageView (frame: CGRect(x: 0, y: 0, width: 42, height: 42))
    var panGesture  = UIPanGestureRecognizer()
    var m_iOffSetY: Int = 0
    var m_strCaptchaKey: String = ""
    var m_strAuthToken: String = ""
    var m_bIsLogIn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let strIsLogIn = UserDefaults.standard.string(forKey: "isLogIn")
        let bLogInStatus: Bool = (strIsLogIn == "1") ? true : false
        let bOver5min:Bool = compareDate()
        
        if bLogInStatus && bOver5min {
            renewInfo()
        }
        
        initCaptcha()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(LogInViewController.dragImg(_:)))
        m_imgDrag.isUserInteractionEnabled = true
        m_imgDrag.addGestureRecognizer(panGesture)
    }
    
    func getDate() -> String {
        let time = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let stringDate = timeFormatter.string(from: time)
        return stringDate
    }
    
    func compareDate() -> Bool{
        let strLogInTime = UserDefaults.standard.string(forKey: "logInTime")
        if strLogInTime == nil {
            return true
        }
        let nowTimes = self.getDate()
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let logInDate = timeFormatter.date(from: strLogInTime ?? "")
        let nowDate = timeFormatter.date(from: nowTimes)
        
        let diffSeconds = nowDate!.timeIntervalSinceReferenceDate - logInDate!.timeIntervalSinceReferenceDate
        print("diffSeconds = \(diffSeconds)")
        
        if diffSeconds > 300 {
            return true
        } else {
            return false
        }
        
    }
    
    
    func initCaptcha() {
        let url = URL(string: "https://api.royalqs.com/sso/captcha")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(Captcha.self, from: data)
                    print(responseData)
                    let strWall = responseData.wall
                    let strPiece = responseData.piece
                    self.m_iOffSetY = responseData.offsetY
                    self.m_strCaptchaKey = responseData.key
                    
                    let imgWall: UIImage = self.dataToImage(strResponse: strWall)
                    let imgPiece: UIImage = self.dataToImage(strResponse: strPiece)
                    DispatchQueue.main.async {
                        self.m_imgWall.image = imgWall
                        self.m_imgPiece.image = imgPiece
                        self.m_imgPiece.frame = CGRect(x: 0, y: self.m_iOffSetY, width: 42, height: 42)
                        self.m_imgWall.addSubview(self.m_imgPiece)
                    }
                } catch  {
                    print(error)
                }
            }
        }.resume()
    }
    
    func dataToImage(strResponse: String) -> UIImage {
        let arrResponse = strResponse.split(separator: ",")
        let strData = String(arrResponse[arrResponse.count - 1])
        let dataResponse = Data(base64Encoded: strData, options: .ignoreUnknownCharacters)
        let imgWall: UIImage = UIImage(data: dataResponse!) ?? UIImage()
        return imgWall
    }
    
    @objc func dragImg(_ sender:UIPanGestureRecognizer){
        let y = (m_imgDrag.frame.maxY) / 2
        let translation = sender.translation(in: self.m_vDrag)
        m_imgDrag.center = CGPoint(x: m_imgDrag.center.x + translation.x, y: y)
        sender.setTranslation(CGPoint.zero, in: self.m_vDrag)
        
        let CFDragX = m_imgDrag.frame.origin.x
        let iDragX = Int(CFDragX)
        m_imgPiece.frame = CGRect(x: iDragX, y: m_iOffSetY, width: 42, height: 42)
        
        if sender.state == .ended {
            logIn(DragX: iDragX)
        }
    }
    
    func logIn(DragX: Int) {
        let url = URL(string: "https://api.royalqs.com/sso/users/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        
        let info = LogInBody(device: "iPhone14,5 iPhone iOS 15.5", login_id: "1490205871@qq.com", password: "123456", device_id: "CED10B2A-AF93-407D-974D-92EA779D18F6", captcha_key: m_strCaptchaKey, captcha_x: DragX, version: "4.2.3")
        let data = try? encoder.encode(info)
        request.httpBody = data
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let infoResponse = try decoder.decode(LogInResponse.self, from: data)
                    print(infoResponse)
                    if infoResponse.code == 200 {
                        self.m_bIsLogIn = true
                        UserDefaults.standard.set(self.m_bIsLogIn, forKey: "isLogIn")
                        let nowTimes = self.getDate()
                        UserDefaults.standard.set(nowTimes, forKey: "logInTime")
                        let strToken: String = infoResponse.data.token
                        self.m_strAuthToken = "Bearer " + strToken
                        print("m_strAuthToken = \(self.m_strAuthToken)")
                        self.goToNextVC()
                    }else {
                        print("ErrorMSG == \(infoResponse.msg)")
                    }
                } catch  {
                    print(error)
                }
            }
        }.resume()
         
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! NextViewController
        vc.m_strAuthToken = m_strAuthToken
    }
    
    func goToNextVC() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showNextVC", sender: nil)
        }
        
    }
    
    
    func renewInfo() {
        let url = URL(string: "https://api.royalqs.com/sso/user/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        
        let info = ["Authorization":m_strAuthToken]
        let data = try? encoder.encode(info)
        request.httpBody = data
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let infoResponse = try decoder.decode(LogInResponse.self, from: data)
                    print(infoResponse)
                    if infoResponse.code == 200 {
                       
                        print("Upload")
                        
                    }else {
                        print("ErrorMSG == \(infoResponse.msg)")
                    }
                } catch  {
                    print(error)
                }
            }
        }.resume()
    }
    

}

