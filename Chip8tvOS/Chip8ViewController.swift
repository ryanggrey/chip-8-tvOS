//
//  ViewController.swift
//  Chip8tvOS
//
//  Created by Ryan Grey on 16/02/2021.
//

import UIKit
import Chip8Emulator
import GameController

class Chip8ViewController: UIViewController {
    private var chip8: Chip8!
    private var loadedRom: [Byte]?
    private var cpuTimer: Timer?
    private var displayTimer: Timer?
    private let cpuHz: TimeInterval = 1/600
    private let displayHz: TimeInterval = 1/60
    // TODO: inject from previous controller
    private let romName: RomName = .pong

    private lazy var platformInputMappingService: TVInputMappingService = {
        return TVInputMappingService()
    }()

    private lazy var supportedRomService: PlatformSupportedRomService = {
        return PlatformSupportedRomService(inputMappingService: platformInputMappingService)
    }()

    private lazy var inputMapper: InputMapper<TVInputMappingService> = {
        return InputMapper(platformInputMappingService: platformInputMappingService)
    }()

    private var chip8View: Chip8View {
        return view as! Chip8View
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let ram = load(romName: romName.rawValue) else { return }

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
        guard let romData = NSDataAsset(name: romName, bundle: Bundle.emulator)?.data else { return nil }
        let rom = [Byte](romData)
        let ram = RomLoader.loadRam(from: rom)
        return ram
    }

    private func stopTimers() {
        cpuTimer?.invalidate()
        cpuTimer = nil
        displayTimer?.invalidate()
        displayTimer = nil
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
                self.chip8.handleKeyUp(key: key.rawValue)
            }
        }
    }

    private func updateChip8Key(isPressed: Bool, tvInputCode: TVInputCode) {
        guard let key = self.chip8KeyCode(for: tvInputCode)?.rawValue else { return }

        if isPressed {
            self.chip8.handleKeyDown(key: key)
        } else {
            self.chip8.handleKeyUp(key: key)
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
