//
//  TouchPoint.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

import Foundation
import UIKit

public class TouchPoint: Identifiable, Hashable {
    public let id: UUID

    public let device: Device
    public let mode: Mode

    public private(set) var position: CGPoint
    public private(set) var force: CGFloat
    public private(set) var altitude: CGFloat
    public private(set) var azimuth: CGFloat

    public var completed: Bool = false

    public enum Device {
        case finger
        case pencil

        init(touchType: UITouch.TouchType) {
            switch touchType {
            case .pencil:
                self = .pencil
            case .direct, .indirect, .indirectPointer:
                self = .finger
            @unknown default:
                self = .finger
            }
        }
    }

    public enum Mode {
        case standard
        case predicted
    }

    init(id: UUID = UUID(), mode: Mode = .standard, touch: UITouch, in view: UIView?) {
        self.id = id
        self.mode = mode

        let device = Device(touchType: touch.type)
        self.device = device

        self.position = touch.location(in: view)
        self.altitude = touch.altitudeAngle
        self.azimuth = touch.azimuthAngle(in: view)

        switch device {
        case .finger:
            self.force = max(0.25, min(touch.majorRadius / 100.0, 1.0))
        case .pencil:
            self.force = max(0.025, touch.force / touch.maximumPossibleForce)
        }
    }

    func update(with touch: UITouch, in view: UIView?) {
        self.position = touch.location(in: view)
        self.altitude = touch.altitudeAngle
        self.azimuth = touch.azimuthAngle(in: view)
        switch device {
        case .finger:
            self.force = max(0.025, min(touch.majorRadius / 100.0, 1.0))
        case .pencil:
            self.force = max(0.025, touch.force / touch.maximumPossibleForce)
        }
    }

    public static func == (lhs: TouchPoint, rhs: TouchPoint) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
