//
//  TouchView.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

import UIKit

public class TouchView: UIView {
    private let queue = DispatchQueue(
        label: "com.petertretyakov.Tactile.TouchQueue",
        qos: .userInteractive,
        attributes: [],
        autoreleaseFrequency: .workItem,
        target: nil
    )
    private var activeLines: [UITouch: Line] = [:]

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
        self.queue.sync {
            let lines = self.startLines(touches: touches, event: event)
            if !lines.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesCreated(lines)
                }
            }
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.queue.sync {
            let lines = self.updateLines(touches: touches, event: event, finish: false)
            if !lines.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesUpdated(lines)
                }
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.queue.sync {
            let lines = self.updateLines(touches: touches, event: event, finish: true)

            let updated = lines.filter { !$0.finished }
            if !updated.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesUpdated(updated)
                }
            }

            let finished = lines.filter { $0.finished }
            if !finished.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesFinished(finished)
                }
            }
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.queue.sync {
            let lines = self.updateLines(touches: touches, event: event, finish: true)

            let updated = lines.filter { !$0.finished }
            if !updated.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesUpdated(updated)
                }
            }

            let finished = lines.filter { $0.finished }
            if !finished.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesCancelled(lines)
                }
            }
        }
    }

    public override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        self.queue.sync {
            var lines: [Line] = []
            for touch in touches {
                guard let line = self.activeLines[touch] else { continue }

                line.update(touch: touch, in: self.destination)
                lines.append(line)

                let properPhase = [.ended, .cancelled].contains(touch.phase)
                let wontUpdate = touch.estimatedPropertiesExpectingUpdates.isEmpty
                if (properPhase && wontUpdate) || line.finished {
                    self.activeLines[touch] = nil
                }
            }

            let updated = lines.filter { !$0.finished }
            if !updated.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesUpdated(updated)
                }
            }

            let finished = lines.filter { $0.finished }
            if !finished.isEmpty {
                DispatchQueue.main.async {
                    self.delegate?.linesFinished(finished)
                }
            }
        }
    }

    private func startLines(touches: Set<UITouch>, event: UIEvent?) -> [Line] {
        var lines: [Line] = []
        for touch in touches {
            let line = Line()
            line.add(touch: touch, in: destination, mode: .standard)
            self.activeLines[touch] = line
            lines.append(line)
        }
        return lines
    }

    private func updateLines(touches: Set<UITouch>, event: UIEvent?, finish: Bool) -> [Line] {
        var lines: [Line] = []
        for touch in touches {
            guard let line = self.activeLines[touch] else { continue }

            line.cleanPredicted()

            (event?.coalescedTouches(for: touch) ?? [touch]).forEach {
                line.add(touch: $0, in: self.destination, mode: .standard)
            }

            event?.predictedTouches(for: touch)?.forEach {
                line.add(touch: $0, in: self.destination, mode: .predicted)
            }

            if finish {
                line.finish(touch: touch)
            }

            if finish && line.finished {
                self.activeLines[touch] = nil
            }

            lines.append(line)
        }
        return lines
    }
}
