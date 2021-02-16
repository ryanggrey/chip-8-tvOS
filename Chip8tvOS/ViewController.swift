//
//  ViewController.swift
//  Chip8tvOS
//
//  Created by Ryan Grey on 16/02/2021.
//

import UIKit
import Chip8Emulator

class ViewController: UIViewController {
    private var chip8: Chip8!
    private var loadedRom: [Byte]?
    private var cpuTimer: Timer?
    private var displayTimer: Timer?
    private let cpuHz: TimeInterval = 1/600
    private let displayHz: TimeInterval = 1/60
    private let romName = "Space Invaders [David Winter]"

    var chip8View: Chip8View {
        return view as! Chip8View
    }

    private func setupChip8View() {
        chip8View.pixelColor = .green
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupChip8View()

        guard let romData = NSDataAsset(name: romName)?.data else { return }
        let rom = [Byte](romData)
        let ram = RomLoader.loadRam(from: rom)

        runEmulator(with: ram)
    }

    private func runEmulator(with rom: [Byte]) {
        var chipState = ChipState()
        chipState.ram = rom

        self.chip8 = Chip8(
            state: chipState,
            cpuHz: cpuHz
        )

        startCpu()
        startRendering()
    }

    private func startCpu() {
        cpuTimer = Timer.scheduledTimer(
            withTimeInterval: cpuHz,
            repeats: true,
            block: cpuTimerFired
        )
    }

    private func cpuTimerFired(_: Timer) {
        chip8.cycle()
        if chip8.shouldPlaySound {
            // TODO: play sound
        }
    }

    private func startRendering() {
        displayTimer = Timer.scheduledTimer(
            withTimeInterval: displayHz,
            repeats: true,
            block: displayTimerFired
        )
    }

    private func displayTimerFired(_: Timer) {
        drawChip8IfNeeded()
    }

    private func drawChip8IfNeeded() {
        if chip8.needsRedraw {
            render(screen: chip8.screen)
            chip8.needsRedraw = false
        }
    }

    private func render(screen: Chip8Screen) {
        chip8View.screen = screen
        chip8View.setNeedsDisplay()
    }
}
