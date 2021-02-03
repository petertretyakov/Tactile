//
//  File.swift
//  Tactile
//
//  Created by Peter Tretyakov on 04.02.2021.
//

public protocol TouchDelegate: AnyObject {
    func linesCreated(_ lines: [Line])
    func linesUpdated(_ lines: [Line])
    func linesFinished(_ lines: [Line])
    func linesCancelled(_ lines: [Line])
}
