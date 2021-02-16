//
//  Chip8View.swift
//  CHIP-8
//
//  Created by Ryan Grey on 16/02/2021.
//

import UIKit
import Chip8Emulator

class Chip8View: UIView {
    var screen: Chip8Screen?
    var pixelColor: UIColor?

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawPixels(in: context)
    }
    
    private func drawPixels(in context: CGContext) {
        guard let screen = screen, let pixelColor = pixelColor else { return }

        let path = PathFactory.from(
            screen: screen,
            containerSize: self.frame.size,
            isYReversed: false
            )
        context.setFillColor(pixelColor.cgColor)
        context.addPath(path)
        context.fillPath()
    }
}
