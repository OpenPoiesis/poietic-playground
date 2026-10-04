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

struct ResourceError: Error, CustomStringConvertible {
    enum Kind {
        case notFound
        case unreadable(details: String)
    }
    
    let kind: Kind
    let path: String
    let root: URL?
    var description: String {
        let location = root?.path ?? "<no resource directory>"
        switch kind {
        case .notFound:
            return "Resource '\(path)' not found in `\(location)`"
        case .unreadable(details: let details):
            return "Unable to read resource '\(path)' from '\(location)': \(details)"
        }
    }
}

/// Object for locating resources.
///
/// - Environment variable `POIETIC_RESOURCES`
/// - Bundle for the executable created the by Swift Package Manager
/// - Platform-specific locations
///     - MacOS: Swift package manager bundle (`<PackageName>_<TargetName>.bundle`).
///     - Linux: Appending installation directory name to the environment variables
///         `XDG_DATA_HOME`, `HOME`, `XDG_DATA_DIRS`;
///         then to `/usr/local/share` and `/usr/share`.
///
/// - Note: Windows support is not yet implemented.
///
struct ResourceDirectory {
    static let ResourcesEnvironmentKey = "POIETIC_RESOURCES"
    static let InstallDirectoryName = "poietic-playground"
    // SwiftPM: <PackageName>_<TargetName>.bundle
    static let SwiftPMBundleName = "PoieticPlayground_PoieticPlayground.bundle"
    
    static let Sentinel = "icons"
    
    let rootURL: URL
    
    static func find() -> ResourceDirectory? {
        var result: URL? = nil
        var locations: [URL] = []
        
        if let url = Self.locationFromEnvironmentOverride() {
            locations.append(url)
        }

        if let url = Self.locationFromSwiftPM() {
            locations.append(url)
        }

        locations += platformLocations()
        
        for location in locations {
            let sentinel = location.appendingPathComponent(Self.Sentinel)
            if (try? sentinel.checkResourceIsReachable()) ?? false {
                result = location
                break
            }
        }

        if let result {
            return ResourceDirectory(rootURL: result)
        }
        else {
            return nil
        }
    }
    
    func url(forPath path: String) -> URL {
        return rootURL.appending(path: path)
    }

    func data(forPath path: String) throws (ResourceError) -> Data {
        let fileURL = url(forPath: path)
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            throw ResourceError(kind: .notFound, path: path, root: rootURL)
        }
        do {
            return try Data(contentsOf: fileURL)
        }
        catch {
            let details = error.localizedDescription
            throw ResourceError(kind: .unreadable(details: details), path: path, root: rootURL)
        }
    }
    
    private static func locationFromEnvironmentOverride() -> URL? {
        guard let path = ProcessInfo.processInfo.environment[Self.ResourcesEnvironmentKey],
              !path.isEmpty
        else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }
    
    private static func locationFromSwiftPM() -> URL? {
        let root = Bundle.main.executableURL?.deletingLastPathComponent()
                   ?? Bundle.main.bundleURL
        let bundleURL = root.appendingPathComponent(Self.SwiftPMBundleName, isDirectory: true)
        guard let resourceURL = Bundle(url: bundleURL)?.resourceURL else {
            return nil
        }
        return resourceURL
    }

    
    private static func platformLocations() -> [URL] {
        
#if os(macOS)
        guard let url = Bundle.main.resourceURL else {
            return []
        }
        return [url]
        
#elseif os(Linux)
        let dirs = dataDirectories()
        let urls = dirs.map {
            $0.appendingPathComponent(Self.InstallDirectoryName, isDirectory: true)
        }
        return urls
        
#elseif os(Windows)
        // TODO: Add and test Windows resource discovery, at least basic one.
        return []
#else
        return []
#endif
    }
    
#if os(Linux)
    func dataDirectories() -> [URL] {
        // XDG data directories: `XDG_DATA_HOME`, then the entries of `XDG_DATA_DIRS`.
        let paths: [String] = []
        
        if let dataHome = ProcessInfo.processInfo.environment["XDG_DATA_HOME"],
           !dataHome.isEmpty
        {
            paths.append(dataHome)
        }
        else if let home = ProcessInfo.processInfo.environment["HOME"],
                !home.isEmpty
        {
            paths.append(home)
        }
        
        if let dataDirs = ProcessInfo.processInfo.environment["XDG_DATA_DIRS"],
           dataDirs.isEmpty
        {
            paths.append("/usr/local/share")
            paths.append("/usr/share")
        }
        else {
            let items = dataDirs.split(separator: ":")
            paths += items
        }
        
        let urls = paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
        return urls
    }
#endif

}


class ResourceManager {
    let root: URL
    var backend: any GraphicsBackendProtocol
    var textureCache: [String:TextureHandle] = [:]
    
    init(_ rootPath: String, backend: any GraphicsBackendProtocol) {
        self.root = URL(fileURLWithPath: rootPath)
        self.backend = backend
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
    
    // FIXME: Return default texture instead of failing
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
