//
//  RomPlatformInput.swift
//  CHIP8WatchOS WatchKit Extension
//
//  Created by Ryan Grey on 19/02/2021.
//

import Foundation
import Chip8Emulator

typealias PlatformMapping = [TVInputCode : SemanticInputCode]

struct TVInputMappingService {
    private let mapping: [RomName : PlatformMapping] = [
        .chip8 : [:],
        .airplane : [
            .aButton : .primaryAction
        ],
        .astroDodge: [
            .aButton : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .blinky : [
            .left : .left,
            .right : .right,
            .down : .down,
            .up : .up
        ],
        .breakout: [
            .left : .left,
            .right : .right
        ],
        .cave : [
            .aButton : .primaryAction,
            .up : .up,
            .down : .down,
            .left : .left,
            .right : .right
        ],
        .filter : [
            .left : .left,
            .right : .right
        ],
        .kaleidoscope : [
            .aButton : .primaryAction,
            .up : .up,
            .down : .down,
            .left : .left,
            .right : .right
        ],
        .landing : [
            .aButton : .primaryAction
        ],
        .lunarLander : [
            .aButton : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .maze : [:],
        .missile : [
            .aButton : .primaryAction
        ],
        .pong : [
            .down : .down,
            .up : .up
        ],
        .rocket : [
            .aButton : .primaryAction
        ],
        .spaceFlight : [
            .aButton : .primaryAction,
            .xButton : .secondaryAction,
            .down : .down,
            .up : .up
        ],
        .spaceIntercept : [
            .aButton : .primaryAction,
            .xButton : .secondaryAction,
            .left : .left,
            .up : .up,
            .right : .right
        ],
        .spaceInvaders : [
            .aButton : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .squash : [
            .up : .up,
            .down : .down
        ],
        .tank : [
            .aButton : .primaryAction,
            .left : .left,
            .right : .right,
            .down : .down,
            .up : .up
        ],
        .tapeWorm : [
            .aButton : .primaryAction,
            .left : .left,
            .right : .right,
            .up : .up,
            .down : .down
        ],
        .tetris : [
            .down : .secondaryAction,
            .aButton : .primaryAction,
            .left : .left,
            .right : .right
        ],
        .wipeOff : [
            .left : .left,
            .right : .right
        ],
        .worm : [
            .aButton : .primaryAction,
            .left : .left,
            .right : .right,
            .up : .up,
            .down : .down
        ],
        .xMirror : [
            .aButton : .primaryAction,
            .up : .up,
            .down : .down,
            .left : .left,
            .right : .right
        ]
    ]

    func platformMapping(for romName: RomName) -> PlatformMapping? {
        return mapping[romName]
    }
}

extension TVInputMappingService: PlatformInputMappingService {
    typealias PlatformInputCode = TVInputCode

    func semanticInputCode(from romName: RomName, from platformInputCode: TVInputCode) -> SemanticInputCode? {
        return platformMapping(for: romName)?[platformInputCode]
    }
}
