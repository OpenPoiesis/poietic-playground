//
//  Command.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

import PoieticCore

// NOTE: Command patter in this application serves as incubator for scriptability and potential
//       infrastructure within either PoieticCore or maybe PoieticApp (CLI & app-support classes)


// TODO: Integrate
struct CommandResult {
    /// Result values to be used for detailed reporting.
    let details: [String:Variant]
}

struct CommandError: Error {
    enum Kind {
        case user
        /// Users should contact application developers.
        case `internal`
    }
    let message: String
    let kind: Kind
    let underlyingError: (any Error)?
    // let canRetry: Bool
    
    init(_ message: String, kind: Kind = .user, underlyingError: (any Error)? = nil) {
        self.message = message
        self.kind = kind
        self.underlyingError = underlyingError
    }
}

/// Protocol for objects that encapsulate actions with a document.
///
/// Commands are representations of user actions.
///
///
@MainActor
protocol Command {
    var name: String { get }
    func run(_ context: CommandContext) throws (CommandError)
}

struct CommandContext {
    let document: Document
    let canvas: DiagramCanvas?
    
    /// Short-hand for `document.design`
    var design: Design { document.design }
    /// Short-hand for `document.world`
    var world: World { document.world }
}

struct CommandInvocation {
    let command: Command
    weak let canvas: DiagramCanvas?
    init(command: Command, canvas: DiagramCanvas? = nil) {
        self.command = command
        self.canvas = canvas
    }
}
