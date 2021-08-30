//
//  TouchLine.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

import Foundation
import UIKit

public class TouchLine: Identifiable, Hashable {
    public let id: UUID = UUID()
    public private(set) var points: [TouchPoint] = []

    public var isPencil: Bool {
        self.points.first?.isPencil ?? false
    }

    public var isFinished: Bool {
        self.awaitingUpdates.isEmpty && !self.touchInProgress
    }

    public var finishedRange: Range<Int> {
        let finish = self.points.firstIndex { !$0.isFinished || $0.isPredicted } ?? 0
        return Range(uncheckedBounds: (0, finish))
    }

    public func finishedRange(from start: Int) -> Range<Int> {
        guard self.points.count > start else {
            return Range(uncheckedBounds: (start, start))
        }

        let finish = self.points[start...].firstIndex { !$0.isFinished || $0.isPredicted } ?? start
        return Range(uncheckedBounds: (start, finish))
    }

    // MARK: - Hashable

    public static func == (lhs: TouchLine, rhs: TouchLine) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    func add(touch: UITouch, isPredicted: Bool, view: UIView?) {
        if let updateIndex = touch.estimationUpdateIndex, self.awaitingUpdates[updateIndex] != nil {
            self.update(touch: touch, in: view)
        } else {
            let point = TouchPoint(isPredicted: isPredicted, touch: touch, view: view)
            self.points.append(point)

            let canUpdate = !touch.estimatedPropertiesExpectingUpdates.isEmpty && !isPredicted
            if let updateIndex = touch.estimationUpdateIndex, canUpdate {
                self.awaitingUpdates[updateIndex] = point
            } else {
                point.isFinished = true
            }
        }
    }

    func update(touch: UITouch, in view: UIView?) {
        guard let updateIndex = touch.estimationUpdateIndex,
              let point = self.awaitingUpdates[updateIndex]
        else { return }

        point.update(touch: touch, view: view)
        if touch.estimatedPropertiesExpectingUpdates.isEmpty {
            self.awaitingUpdates[updateIndex] = nil
            point.isFinished = true
        }
    }

    func finish(touch: UITouch) {
        self.touchInProgress = false
        if let updateIndex = touch.estimationUpdateIndex,
           let point = self.awaitingUpdates[updateIndex],
           touch.estimatedPropertiesExpectingUpdates.isEmpty
        {
            self.awaitingUpdates[updateIndex] = nil
            point.isFinished = true
        }
    }

    func cleanPredicted() {
        self.points.removeAll { $0.isPredicted }
    }

    private var awaitingUpdates: [NSNumber: TouchPoint] = [:]
    private var touchInProgress: Bool = true
}
