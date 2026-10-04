//
//  UIStyle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 18/02/2026.
//

enum IconKey: CaseIterable, Hashable {
    case add
    case arrowComment
    case arrowOutlined
    case arrowParameter
    case cancel
    case chevronsLeft
    case chevronsRight
    case connect
    case delete
    case empty
    case error
    case formula
    case hand
    case handleFlow
    case lastStep
    case lineCurved
    case lineOrthogonal
    case lineStraight
    case loop
    case menu
    case nextStep
    case ok
    case place
    case previousStep
    case redo
    case restart
    case run
    case select
    case stop
    case timeWindow
    case undo
    case zoomIn
    case zoomOut
    
    var name: String {
        String(describing: self).toSnakeCase(splitCharacter: "-")
    }
}

enum DisplayScale {
    case standard
    case hiDPI
    init(displayScale: Float) {
        self = displayScale >= 1.5 ? .hiDPI : .standard
    }
}

// TODO: This is not 100% clean, as InterfaceStyle is bound to resource manager here
protocol TraitEnvironment: AnyObject {
    var interfaceStyle: InterfaceStyle { get }
    var displayScale: DisplayScale { get }
//    var userLevel: AudienceLevel { get }
}

class InterfaceStyle {
    enum Appearance {
        case light
        case dark
    }
    
    var appearance: Appearance
    var icons: [IconKey:TextureHandle]

    var primaryTint: Color {
        switch appearance {
        case .dark: .white
        case .light: .black
        }
    }
    
    let resourceManager: ResourceManager
    
    init(resourceManager: ResourceManager, appearance: Appearance = .dark) {
        self.resourceManager = resourceManager
        self.appearance = appearance
        self.icons = [:]
    }
    
    /// Get a texture of an icon mask that will be tinted using primaryTint colour.
    @MainActor
    func texture(forIcon iconKey: IconKey) -> TextureHandle {
        if let texture = icons[iconKey] {
            return texture
        }
        let path = "icons/white/" + iconKey.name + ".png"
        let texture = resourceManager.loadTexture(path)
        return texture
    }
}
