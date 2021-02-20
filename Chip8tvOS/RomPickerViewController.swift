//
//  RomPickerViewController.swift
//  Chip8tvOS
//
//  Created by Ryan Grey on 20/02/2021.
//

import Foundation
import UIKit

class RomPickerViewController: UIViewController {
    @IBOutlet weak var romTableView: UITableView!

    private lazy var platformInputMappingService: TVInputMappingService = {
        return TVInputMappingService()
    }()

    private lazy var supportedRomService: PlatformSupportedRomService = {
        return PlatformSupportedRomService(inputMappingService: platformInputMappingService)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        romTableView.dataSource = self
    }
}

extension RomPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }


}
