//
//  ViewController.swift
//  Chip8tvOS
//
//  Created by Ryan Grey on 16/02/2021.
//

import UIKit
import Chip8Emulator
import GameController

class ViewController: UIViewController {
    private var chip8: Chip8!
    private var loadedRom: [Byte]?
    private var cpuTimer: Timer?
    private var displayTimer: Timer?
    private let cpuHz: TimeInterval = 1/600
    private let displayHz: TimeInterval = 1/60
    private let romName = "Space Invaders [David Winter]"

    private var leftTimer: Timer?
    private var rightTimer: Timer?
    private var upTimer: Timer?
    private var downTimer: Timer?
    private var actionTimer: Timer?

    private var chip8View: Chip8View {
        return view as! Chip8View
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let ram = load(romName: romName) else { return }

        setupChip8View()
        runEmulator(with: ram)
        startWatchingForControllers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startWatchingForControllers()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // TODO: test
        stopWatchingForControllers()
        stopTimers()
    }

    private func setupChip8View() {
        chip8View.backgroundColor = .black
        chip8View.pixelColor = .green
    }

    private func load(romName: String) -> [Byte]? {
        guard let romData = NSDataAsset(name: romName)?.data else { return nil }
        let rom = [Byte](romData)
        let ram = RomLoader.loadRam(from: rom)
        return ram
    }

    private func stopTimers() {
        cpuTimer?.invalidate()
        cpuTimer = nil
        displayTimer?.invalidate()
        displayTimer = nil
        leftTimer?.invalidate()
        leftTimer = nil
        rightTimer?.invalidate()
        rightTimer = nil
        upTimer?.invalidate()
        upTimer = nil
        downTimer?.invalidate()
        downTimer = nil
    }

    // TODO: move game controller stuff elsewhere
    // TODO: consider game controller stuff for macOS
    private func startWatchingForControllers() {
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
        let movementHandler: GCControllerDirectionPadValueChangedHandler = { [weak self] _, xValue, yValue in
            guard let self = self else { return }

            if max(abs(xValue), abs(yValue)) == abs(xValue) {
                if xValue < 0 {
                    self.tapLeft()
                } else if xValue > 0{
                    self.tapRight()
                }
            } else {
                if yValue < 0 {
                    self.tapDown()
                } else {
                    self.tapUp()
                }
            }
        }

        let buttonHandler: GCControllerButtonValueChangedHandler = { [weak self] button, buttonValue, isPressed in
            guard let self = self else { return }

            self.tapAction()
        }

        if let microGamepad = gameController.microGamepad {
            microGamepad.allowsRotation = true
            microGamepad.dpad.valueChangedHandler = movementHandler
            microGamepad.buttonA.valueChangedHandler = buttonHandler
        }

        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.leftThumbstick.valueChangedHandler = movementHandler
            extendedGamepad.dpad.valueChangedHandler = movementHandler
        }
    }

    private func remove(gameController: GCController) {
        // TODO: needed?
    }

    // TODO: refactor
    private func tapLeft() {
        // TODO: test invalidation and key up handling
        leftTimer?.invalidate()
        leftTimer = nil

        let keyCode = Chip8KeyCode.four.rawValue
        chip8.handleKeyDown(key: keyCode)

        leftTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.chip8.handleKeyUp(key: keyCode)
        }
    }

    private func tapRight() {
        rightTimer?.invalidate()
        rightTimer = nil

        let keyCode = Chip8KeyCode.six.rawValue
        chip8.handleKeyDown(key: keyCode)

        rightTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.chip8.handleKeyUp(key: keyCode)
        }
    }

    private func tapUp() {
        upTimer?.invalidate()
        upTimer = nil

        let keyCode = Chip8KeyCode.two.rawValue
        chip8.handleKeyDown(key: keyCode)

        upTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.chip8.handleKeyUp(key: keyCode)
        }
    }

    private func tapDown() {
        downTimer?.invalidate()
        downTimer = nil

        let keyCode = Chip8KeyCode.eight.rawValue
        chip8.handleKeyDown(key: keyCode)

        downTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.chip8.handleKeyUp(key: keyCode)
        }
    }

    private func tapAction() {
        actionTimer?.invalidate()
        actionTimer = nil

        let keyCode = Chip8KeyCode.five.rawValue
        chip8.handleKeyDown(key: keyCode)

        actionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            // TODO: do we need this? is there a way to detect press/lift at source event?
            self?.chip8.handleKeyUp(key: keyCode)
        }
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
            chip8View.screen = chip8.screen
            chip8View.setNeedsDisplay()
            chip8.needsRedraw = false
        }
    }
}
