//
//  ResourceLoader.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 31/01/2026.
//

// TODO: Use enum for known icons/images
// FIXME: Convert fatalErrors to exceptions (if appropriate)

import CIimgui
import Cstb
import Csdl3
import Foundation

struct ResourceError: Error {
    enum ErrorType {
        case invalidData
        case loadingFailed
    }
    let type: ErrorType
    let resource: String
}

class ResourceManager {
    static let DefaultResourcesPath = "Sources/PoieticPlayground/Resources/"

    @MainActor static var shared: (ResourceManager) {
        guard let backend = _shared else {
            fatalError("ResourceManager not initialized")
        }
        return backend
    }
    @MainActor private static var _shared: (ResourceManager)?
    @MainActor static func registerShared(_ manager: ResourceManager) {
        precondition(_shared == nil, "Backend already registered.")
        _shared = manager
    }
    
    let root: URL
    var backend: any GraphicsBackendProtocol
    var textureCache: [String:TextureHandle] = [:]
    
    init(_ rootPath: String = DefaultResourcesPath, backend: any GraphicsBackendProtocol) {
        self.root = Self.locateResourcesRoot(preferredPath: rootPath)
        self.backend = backend
    }
    
    init(rootURL: URL, backend: any GraphicsBackendProtocol) {
        self.root = rootURL
        self.backend = backend
    }

    static func locateResourcesRoot(preferredPath: String? = nil) -> URL {
        let fm = FileManager.default

        func isValid(_ url: URL) -> Bool {
            let marker = url.appendingPathComponent("stock_flow_pictograms.json")
            return fm.fileExists(atPath: marker.path)
        }

        // 1. Explicitly passed preferred path (if it exists and is valid)
        if let preferred = preferredPath {
            let url = URL(fileURLWithPath: preferred)
            if isValid(url) {
                return url
            }
        }

        // 2. Environment variable override
        if let envPath = ProcessInfo.processInfo.environment["POIETIC_RESOURCES_PATH"] {
            let url = URL(fileURLWithPath: envPath)
            if isValid(url) {
                return url
            }
        }

        // 3. Relative to executable path
        if let execURL = Bundle.main.executableURL {
            let execDir = execURL.deletingLastPathComponent()
            let candidates = [
                execDir.appendingPathComponent("../share/poietic-playground"),
                execDir.appendingPathComponent("../share/poietic-playground/Resources"),
                execDir.appendingPathComponent("Resources"),
                execDir.appendingPathComponent("../Resources")
            ]
            for candidate in candidates {
                if isValid(candidate) {
                    return candidate.standardized
                }
            }
        }

        // 4. Standard user and system installation locations
        let homeDir = fm.homeDirectoryForCurrentUser
        let searchPaths = [
            homeDir.appendingPathComponent(".local/share/poietic-playground"),
            homeDir.appendingPathComponent(".local/share/poietic-playground/Resources"),
            URL(fileURLWithPath: "/usr/local/share/poietic-playground"),
            URL(fileURLWithPath: "/usr/local/share/poietic-playground/Resources"),
            URL(fileURLWithPath: "/usr/share/poietic-playground"),
            URL(fileURLWithPath: "/usr/share/poietic-playground/Resources")
        ]
        for path in searchPaths {
            if isValid(path) {
                return path
            }
        }

        // 5. Default repository / CWD fallback
        let fallbackCandidates = [
            URL(fileURLWithPath: DefaultResourcesPath),
            URL(fileURLWithPath: "Resources")
        ]
        for fallback in fallbackCandidates {
            if isValid(fallback) {
                return fallback
            }
        }

        return URL(fileURLWithPath: DefaultResourcesPath)
    }
    
    func resourceURL(_ resourcePath: String) -> URL {
        return root.appending(path: resourcePath)
    }
    
    func resourceURL(_ resourceName: String, pathComponents: [String]) -> URL {
        var result = root
        for component in pathComponents {
            result = result.appending(component: component, directoryHint: .isDirectory)
        }
        return result.appending(component: resourceName, directoryHint: .checkFileSystem)
    }

    func resourceFilePath(_ resourcePath: String) -> URL {
        return root.appending(path: resourcePath)
    }
    
    func loadData(_ path: String) -> Data? {
        let url = resourceURL(path)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data
    }
    
    @MainActor
    func loadTexture(_ path: String) -> TextureHandle {
        if let texture = textureCache[path] {
            return texture
        }
        guard let data = loadData(path) else {
            fatalError("Unable to load texture data \(path).")
        }

        do {
            let texture = try loadTexture(data: data)
            textureCache[path] = texture
            return texture

        }
        catch {
            fatalError("Unable to load texture \(path). Reason: \(error)")
        }
    }

    @MainActor
    private func loadTexture(data: Data) throws -> TextureHandle {
        let backend = GraphicsBackend.shared
        
        let pixels = decodeImageData(data)
        defer { stbi_image_free(pixels.pointer) }
        
        let texture = try backend.createTexture(
            pixels: pixels.pointer,
            width:  pixels.width,
            height: pixels.height
        )
        return texture
    }
    
    private struct DecodedImage {
        let pointer: UnsafeMutableRawPointer
        let width: UInt32
        let height: UInt32
        let channels: UInt32
    }
    
    private func decodeImageData(_ data: Data) -> DecodedImage {
        var w: Int32 = 0
        var h: Int32 = 0
        var channels: Int32 = 0
        
        let raw = data.withUnsafeBytes { buffer -> UnsafeMutablePointer<stbi_uc> in
            guard let base = buffer.baseAddress?.assumingMemoryBound(to: stbi_uc.self) else {
                fatalError("Invalid image data buffer")
            }
            guard let decoded = stbi_load_from_memory(base, Int32(data.count), &w, &h, &channels, 4) else {
                fatalError("stbi_load_from_memory failed")
            }
            return decoded
        }
        
        return DecodedImage(pointer: UnsafeMutableRawPointer(raw),
                            width: UInt32(w),
                            height: UInt32(h),
                            channels: UInt32(channels))
    }
    
}
