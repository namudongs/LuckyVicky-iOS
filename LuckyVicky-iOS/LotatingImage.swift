//
//  LotatingImage.swift
//  LuckyVicky-iOS
//
//  Created by namdghyun on 7/6/24.
//

import SwiftUI

struct RotatingImage: UIViewRepresentable {
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "luckyvicky"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        if isAnimating {
            if uiView.layer.animation(forKey: "rotationAnimation") == nil {
                let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
                rotation.toValue = NSNumber(value: Double.pi * 2)
                rotation.duration = 1
                rotation.isCumulative = true
                rotation.repeatCount = Float.infinity
                uiView.layer.add(rotation, forKey: "rotationAnimation")
            }
        } else {
            uiView.layer.removeAnimation(forKey: "rotationAnimation")
        }
    }
}
