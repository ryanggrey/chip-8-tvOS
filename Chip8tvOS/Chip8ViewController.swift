//
//  ViewController.swift
//  Chip8tvOS
//
//  Created by Ryan Grey on 16/02/2021.
//

import UIKit
import Chip8Emulator
import GameController
import AVFoundation

class Chip8ViewController: UIViewController {
    private var chip8Engine: Chip8Engine = Chip8Engine()
    private var loadedRom: [Byte]?
    private let beepPlayer = BeepPlayer()

    // injected from previous controller
    var romName: RomName!
    var inputMapper: InputMapper<TVInputMappingService>!

    private var chip8View: Chip8View {
        return view as! Chip8View
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopWatchingForControllers()
    }

    private func setup() {
        guard let ram = load(romName: romName) else { return }

        chip8Engine.delegate = self
        setupChip8View()
        runEmulator(with: ram)
        startWatchingForControllers()
    }

    private func setupChip8View() {
        chip8View.backgroundColor = .black
        chip8View.pixelColor = .green
    }

    private func load(romName: RomName) -> [Byte]? {
        return RomLoader.loadRam(from: romName)
    }

    // TODO: move game controller stuff elsewhere
    // TODO: consider game controller stuff for macOS
    private func startWatchingForControllers() {
        if let currentController = GCController.current {
            self.add(gameController: currentController)
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { notification in
            if let gameController = notification.object as? GCController {
                self.add(gameController: gameController)
            }
        }
        notificationCenter.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { notification in
            if let gameController = notification.object as? GCController {
                self.remove(gameController: gameController)
            }
        }

        GCController.startWirelessControllerDiscovery(completionHandler: {})
    }

    private func stopWatchingForControllers() {
        GCController.stopWirelessControllerDiscovery()

        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        notificationCenter.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
    }

    private func add(gameController: GCController) {
        let aButton = gameController.physicalInputProfile["Button A"] as! GCControllerButtonInput
        let xButton = gameController.physicalInputProfile["Button X"] as! GCControllerButtonInput

        let dpadDidChange: GCControllerDirectionPadValueChangedHandler = { [weak self] dpad, xValue, yValue in
            guard let self = self else { return }

            self.liftAllChip8Keys()

            let isXDominant = max(abs(xValue), abs(yValue)) == abs(xValue)

            if isXDominant {
                if xValue < 0 {
                    self.updateChip8Key(isPressed: true, tvInputCode: .left)
                } else if xValue > 0 {
                    self.updateChip8Key(isPressed: true, tvInputCode: .right)
                }
            } else {
                if yValue < 0 {
                    self.updateChip8Key(isPressed: true, tvInputCode: .down)
                } else {
                    self.updateChip8Key(isPressed: true, tvInputCode: .up)
                }
            }

        }

        let aButtonDidChange: GCControllerButtonValueChangedHandler = { [weak self] button, pressure, isPressed in
            self?.updateChip8Key(isPressed: isPressed, tvInputCode: .aButton)
        }

        let xButtonDidChange: GCControllerButtonValueChangedHandler = { [weak self] button, pressure, isPressed in
            self?.updateChip8Key(isPressed: isPressed, tvInputCode: .xButton)
        }

        aButton.pressedChangedHandler = aButtonDidChange
        xButton.pressedChangedHandler = xButtonDidChange

        gameController.physicalInputProfile.allDpads.forEach { dpad in
            dpad.valueChangedHandler = dpadDidChange
        }
    }

    private func remove(gameController: GCController) {
        // TODO: needed?
    }

    private func chip8KeyCode(for tvInputCode: TVInputCode) -> Chip8InputCode? {
        return inputMapper.map(platformInput: tvInputCode, romName: romName)
    }

    private func liftAllChip8Keys() {
        TVInputCode.allCases.forEach { buttonType in
            if let key = self.chip8KeyCode(for: buttonType) {
                self.chip8Engine.handleKeyUp(key: key)
            }
        }
    }

    private func updateChip8Key(isPressed: Bool, tvInputCode: TVInputCode) {
        guard let key = self.chip8KeyCode(for: tvInputCode) else { return }

        if isPressed {
            self.chip8Engine.handleKeyDown(key: key)
        } else {
            self.chip8Engine.handleKeyUp(key: key)
        }
    }

    private func runEmulator(with rom: [Byte]) {
        chip8Engine.start(with: rom)
    }
}

extension Chip8ViewController: Chip8EngineDelegate {
    func beep() {
        beepPlayer.play()
    }

    func render(screen: Chip8Screen) {
        chip8View.screen = screen
        chip8View.setNeedsDisplay()
    }
}
