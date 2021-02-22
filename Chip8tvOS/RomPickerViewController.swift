//
//  RomPickerViewController.swift
//  Chip8tvOS
//
//  Created by Ryan Grey on 20/02/2021.
//

import Foundation
import UIKit
import Chip8Emulator

class RomPickerViewController: UIViewController {
    @IBOutlet weak var romTableView: UITableView!

    private lazy var platformInputMappingService: TVInputMappingService = {
        return TVInputMappingService()
    }()

    private lazy var supportedRomService: PlatformSupportedRomService = {
        return PlatformSupportedRomService(inputMappingService: platformInputMappingService)
    }()

    private lazy var inputMapper: InputMapper<TVInputMappingService> = {
        return InputMapper(platformInputMappingService: platformInputMappingService)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        romTableView.dataSource = self
        romTableView.delegate = self
    }

    private func navigateToChip8ViewController(with romName: RomName) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let chip8ViewController = storyboard.instantiateViewController(identifier: "chip8ViewController") as! Chip8ViewController
        chip8ViewController.romName = romName
        chip8ViewController.inputMapper = self.inputMapper
        present(chip8ViewController, animated: true)
    }
}

extension RomPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let roms = supportedRomService.supportedRoms
        return roms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RomCell.identifier, for: indexPath) as! RomCell
        let romName = supportedRomService.supportedRoms[indexPath.row]
        cell.romLabel.text = romName.rawValue
        return cell
    }
}

extension RomPickerViewController: UITableViewDelegate {
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if let nextFocusedCell = context.nextFocusedView as? RomCell{
            nextFocusedCell.backgroundColor = .white
            nextFocusedCell.romLabel.textColor = .black
        }

        if let previousFocusedCell = context.previouslyFocusedView as? RomCell{
            previousFocusedCell.backgroundColor = .clear
            previousFocusedCell.romLabel.textColor = .white
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let romName = supportedRomService.supportedRoms[indexPath.row]
        navigateToChip8ViewController(with: romName)
    }
}
