//
//  CanvasSurface.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 23/02/2026.
//

import Ccairo

enum OverlayError: Error {
    case noSurface
    case noData
    case uploadFailed(any Error)
}

/// Overlay content type
enum OverlayType {
    /// Main content
    case main
    /// Value indicators
    case indicator
    /// Selection and other highlights
    case highlight
    /// Interactive preview
    case preview
}

/// Canvas visual overlay.
///
/// Lifecycles:
///
/// 1. State is ``State/contentDirty``, requires initial rendering of the document.
/// 2. After ``render(_:)`` the state is ``State/textureDirty``, requires texture upload.
/// 3. ``uploadToGPU()`` completes the overlay life cycle, returning it to clean state.
///
class Overlay {
    
    enum State {
        case uninitialized
        case clean
        /// Content (usually design/document) changed and the content needs to be regenerated.
        ///
        /// It is required to (re-)draw into `surface` through `context`.
        case needsRender
        /// Surface content has been changed and we need to upload the texture.
        case needsUpload
    }
    
    /// Name of the overlay for debugging purposes.
    let name: String
    let type: OverlayType
    
    /// Cairo surface pointer `cairo_surface_t *`.
    private var surface: OpaquePointer? // cairo_surface_t*
    /// Cairo context pointer `cairo_t *`.
    private(set) var context: OpaquePointer?
    /// Texture handle, if successfully created by a graphic backend.
    private(set) var texture: TextureHandle?

    private var width: Int32 = 0
    private var height: Int32 = 0
    
    private(set) var state: State = .needsRender
    
    init(name: String, type: OverlayType) {
        self.name = name
        self.type = type
        create(width: 1, height: 1)
    }

    var needsRender: Bool {
        switch state {
        case .needsRender: return true
        case .clean, .needsUpload, .uninitialized: return false
        }
    }
    
    var needsUpload: Bool {
        switch state {
        case .needsUpload: return true
        case .clean, .needsRender, .uninitialized: return false
        }
    }
    
    func setNeedsRender() { self.state = .needsRender }
    func setNeedsUpload() { self.state = .needsUpload }

    @MainActor
    func ensureSize(width: Int32, height: Int32) {
        guard width > 0 && height > 0 else { return }
        
        if width != self.width || height != self.height {
            if let texture {
                GraphicsBackend.shared.destroyTexture(texture)
                self.texture = nil
            }
            create(width: width, height: height)
            self.state = .needsRender
        }
    }

    private func create(width: Int32, height: Int32) {
        self.surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height)

        self.context = cairo_create(surface)
        self.width = width
        self.height = height
        self.state = .needsRender
    }
    
    func destroy() {
        if let surface {
            cairo_surface_destroy(surface)
        }
        if let context {
            cairo_destroy(context)
        }
        self.width = 0
        self.height = 0
        self.state = .uninitialized
    }
    
    func render(_ draw: (CairoRenderingContext) -> Void) {
        guard let context else {
            preconditionFailure("No Cairo context to render overlay to")
        }
        
        cairo_save(context)
        cairo_set_operator(context, CAIRO_OPERATOR_CLEAR)
        cairo_paint(context)
        cairo_restore(context)

        cairo_save(context)
        cairo_set_operator(context, CAIRO_OPERATOR_OVER)
        draw(CairoRenderingContext(context, overlay: type))
        cairo_restore(context)

        self.state = .needsUpload
    }
    
    @MainActor
    func uploadToGPU() throws (OverlayError) {
        guard let surface = surface else {
            throw .noSurface
        }
        
        cairo_surface_flush(surface)
        
        guard let data = cairo_image_surface_get_data(surface) else {
            throw .noData
        }
        
        let w = UInt32(cairo_image_surface_get_width(surface))
        let h = UInt32(cairo_image_surface_get_height(surface))
        
        let backend = GraphicsBackend.shared
        
        if let oldTexture = texture {
            backend.destroyTexture(oldTexture)
        }
        
        do {
            texture = try backend.createTexture(pixels: data, width: w, height: h)
            self.state = .clean
        }
        catch {
            throw .uploadFailed(error)
        }
    }
}

class OverlayStack {
    private var layers: [Overlay] = []
    
    /// Add a layer to the stack (bottom to top order)
    func add(_ overlay: Overlay) {
        layers.append(overlay)
    }
    
    /// Get first surface layer with given name
    func layer(named name: String) -> Overlay? {
        layers.first { $0.name == name }
    }
    
    /// Ensure all layers match given size
    @MainActor
    func ensureSize(width: Int32, height: Int32) {
        for layer in layers {
            layer.ensureSize(width: width, height: height)
        }
    }
    
    /// Upload all dirty layers to GPU
    @MainActor
    func uploadIfNeeded() throws (OverlayError) {
        for layer in layers {
            guard layer.needsUpload else { continue }
            try layer.uploadToGPU()
        }
    }
    
    /// Get textures in draw order (bottom to top)
    func textures() -> [TextureHandle] {
        layers.compactMap { $0.texture }
    }
    
    /// Mark all layers dirty
    func setAllNeedsRender() {
        layers.forEach { $0.setNeedsRender() }
    }
}


