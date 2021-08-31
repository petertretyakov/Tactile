//
//  TouchView.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

import UIKit

public protocol TouchDelegate: AnyObject {
    func linesCreated(_ lines: Set<TouchLine>)
    func linesUpdated(_ lines: Set<TouchLine>)
    func linesFinished(_ lines: Set<TouchLine>)
    func linesCancelled(_ lines: Set<TouchLine>)
}

public class TouchView: UIView {
    private var activeLines: [UITouch: TouchLine] = [:]

    public weak var delegate: TouchDelegate?
    public weak var destination: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.backgroundColor = .clear
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lines = self.startLines(touches: touches, event: event)
        if !lines.isEmpty {
            self.delegate?.linesCreated(lines)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lines = self.updateLines(touches: touches, event: event, finish: false)
        if !lines.isEmpty {
            self.delegate?.linesUpdated(lines)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lines = self.updateLines(touches: touches, event: event, finish: true)

        let updated = lines.filter { !$0.isFinished }
        if !updated.isEmpty {
            self.delegate?.linesUpdated(updated)
        }

        let finished = lines.filter { $0.isFinished }
        if !finished.isEmpty {
                self.delegate?.linesFinished(finished)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        let lines = self.updateLines(touches: touches, event: event, finish: true)

        let updated = lines.filter { !$0.isFinished }
        if !updated.isEmpty {
            self.delegate?.linesUpdated(updated)
        }

        let finished = lines.filter { $0.isFinished }
        if !finished.isEmpty {
            self.delegate?.linesCancelled(lines)
        }
    }

    public override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        var lines: Set<TouchLine> = []
        for touch in touches {
            guard let line = self.activeLines[touch] else { continue }

            line.update(touch: touch, in: self.destination)
            lines.insert(line)

            let properPhase = [.ended, .cancelled].contains(touch.phase)
            let wontUpdate = touch.estimatedPropertiesExpectingUpdates.isEmpty
            if (properPhase && wontUpdate) || line.isFinished {
                self.activeLines[touch] = nil
            }
        }

        let updated = lines.filter { !$0.isFinished }
        if !updated.isEmpty {
            self.delegate?.linesUpdated(updated)
        }

        let finished = lines.filter { $0.isFinished }
        if !finished.isEmpty {
            self.delegate?.linesFinished(finished)
        }
    }

    private func startLines(touches: Set<UITouch>, event: UIEvent?) -> Set<TouchLine> {
        var lines: Set<TouchLine> = []
        for touch in touches {
            let line = TouchLine()
            line.add(touch: touch, isPredicted: false, view: self.destination)
            self.activeLines[touch] = line
            lines.insert(line)
        }
        return lines
    }

    private func updateLines(touches: Set<UITouch>, event: UIEvent?, finish: Bool) -> Set<TouchLine> {
        var lines: Set<TouchLine> = []
        for touch in touches {
            guard let line = self.activeLines[touch] else { continue }

            line.cleanPredicted()

            (event?.coalescedTouches(for: touch) ?? [touch]).forEach {
                line.add(touch: $0, isPredicted: false, view: self.destination)
            }

            event?.predictedTouches(for: touch)?.forEach {
                line.add(touch: $0, isPredicted: true, view: self.destination)
            }

            if finish {
                line.finish(touch: touch)
            }

            if finish && line.isFinished {
                self.activeLines[touch] = nil
            }

            lines.insert(line)
        }
        return lines
    }
}
