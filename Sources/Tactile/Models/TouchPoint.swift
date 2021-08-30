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

    public let isPencil: Bool
    public let isPredicted: Bool

    public private(set) var position: CGPoint
    public private(set) var force: CGFloat
    public private(set) var altitude: CGFloat
    public private(set) var azimuth: CGFloat

    public internal(set) var isFinished: Bool = false

    init(id: UUID = UUID(), isPredicted: Bool, touch: UITouch, view: UIView?) {
        self.id = id
        self.isPencil = touch.type == .pencil
        self.isPredicted = isPredicted
        self.position = touch.location(in: view)
        self.force = TouchPoint.force(for: touch)
        self.altitude = touch.altitudeAngle
        self.azimuth = touch.azimuthAngle(in: view)
    }

    func update(touch: UITouch, view: UIView?) {
        self.position = touch.location(in: view)
        self.force = TouchPoint.force(for: touch)
        self.altitude = touch.altitudeAngle
        self.azimuth = touch.azimuthAngle(in: view)
    }

    private static func force(for touch: UITouch) -> CGFloat {
        if touch.type == .pencil {
            return max(0.025, touch.force / touch.maximumPossibleForce)
        } else {
            return max(0.25, min(touch.majorRadius / 100.0, 1.0))
        }
    }

    // MARK: - Hashable

    public static func == (lhs: TouchPoint, rhs: TouchPoint) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
