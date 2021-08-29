//
//  TouchDelegate.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

public protocol TouchDelegate: AnyObject {
    func linesCreated(_ lines: [TouchLine])
    func linesUpdated(_ lines: [TouchLine])
    func linesFinished(_ lines: [TouchLine])
    func linesCancelled(_ lines: [TouchLine])
}
