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


class ViewController: UIViewController {
    
    @IBOutlet weak var m_imgWall: UIImageView!
    
    @IBOutlet weak var m_imgDrag: UIImageView!
    
    @IBOutlet weak var m_vDrag: UIView!
    let m_imgPiece: UIImageView = UIImageView (frame: CGRect(x: 0, y: 0, width: 42, height: 42))
    var panGesture  = UIPanGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCaptcha()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.dragImg(_:)))
        m_imgDrag.isUserInteractionEnabled = true
        m_imgDrag.addGestureRecognizer(panGesture)
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
                    let ioffsetY = responseData.offsetY
                    
                    let imgWall: UIImage = self.dataToImage(strResponse: strWall)
                    let imgPiece: UIImage = self.dataToImage(strResponse: strPiece)
                    DispatchQueue.main.async {
                        self.m_imgWall.image = imgWall
                        self.m_imgPiece.image = imgPiece
                        self.m_imgPiece.frame = CGRect(x: 0, y: ioffsetY, width: 42, height: 42)
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
        let dragX = m_imgDrag.frame.origin.x
        print("dragX = \(dragX)")
        logIn(DragX: dragX)
    }
    
    func logIn(DragX: CGFloat) {
        let strX: String = "\(DragX)"
        print("test")

        
        
    }

}

