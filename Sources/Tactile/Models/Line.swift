//
//  Line.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

import UIKit

public class Line: Hashable {
    public let id: UUID = UUID()

    public private(set) var points: [Point] = []
    private var awaitingUpdates: [NSNumber: Point] = [:]

    public var device: Point.Device {
        self.points.first?.device ?? .finger
    }

    private var inProgress: Bool = true

    public var finished: Bool {
        self.awaitingUpdates.isEmpty && !self.inProgress
    }

    func add(touch: UITouch, in view: UIView?, mode: Point.Mode) {
        if let updateIndex = touch.estimationUpdateIndex, self.awaitingUpdates[updateIndex] != nil {
            update(touch: touch, in: view)
        } else {
            let point = Point(mode: mode, touch: touch, in: view)
            self.points.append(point)

            let canUpdate = !touch.estimatedPropertiesExpectingUpdates.isEmpty && mode == .standard
            if let updateIndex = touch.estimationUpdateIndex, canUpdate {
                self.awaitingUpdates[updateIndex] = point
            } else {
                point.completed = true
            }
        }
    }

    func update(touch: UITouch, in view: UIView?) {
        guard let updateIndex = touch.estimationUpdateIndex, let point = self.awaitingUpdates[updateIndex] else { return }

        point.update(with: touch, in: view)
        if touch.estimatedPropertiesExpectingUpdates.isEmpty {
            self.awaitingUpdates[updateIndex] = nil
            point.completed = true
        }
    }

    func finish(touch: UITouch) {
        self.inProgress = false
        if let updateIndex = touch.estimationUpdateIndex,
           let point = self.awaitingUpdates[updateIndex],
           touch.estimatedPropertiesExpectingUpdates.isEmpty
        {
            self.awaitingUpdates[updateIndex] = nil
            point.completed = true
        }
    }

    func cleanPredicted() {
        self.points.removeAll { $0.mode == .predicted }
    }

    public static func == (lhs: Line, rhs: Line) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
