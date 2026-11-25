//
//  ResourceManager.swift
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

/// A directory with the application resources: fonts, notations and design templates.
///
/// ``find()`` accepts the first root that contains the sentinel file
/// specified in ``Sentinel`` (`fonts/poietic-icons.ttf`).
///
/// The roots are searched in this order:
///
/// 1. The directory named by the `POIETIC_RESOURCES` environment variable.
/// 2. The Swift Package Manager resource directory:
///    `PoieticPlayground_PoieticPlayground.bundle` (or `.resources` under the
///    native build system) inside an application bundle or next to the executable.
/// 3. Linux only: `poietic-playground` inside the XDG data directories:
///    `XDG_DATA_HOME` (default `$HOME/.local/share`), then the entries of
///    `XDG_DATA_DIRS` (default `/usr/local/share:/usr/share`).
///
/// - Note: Windows support is not implemented yet.
///
struct ResourceDirectory {
    static let ResourcesEnvironmentKey = "POIETIC_RESOURCES"
    static let InstallDirectoryName = "poietic-playground"

    /// Swift Package Manager resource directory name, without the suffix.
    ///
    /// The suffix follows the build system rather than the platform: the current
    /// one appends `.bundle` everywhere, while the native one appends `.resources`
    /// outside Apple platforms. Both are tried, so that neither can break the lookup.
    static let SwiftPMBundleName = "PoieticPlayground_PoieticPlayground"
    static let SwiftPMBundleSuffixes = [".bundle", ".resources"]

    /// A root is accepted only when it contains this file.
    static let Sentinel = "fonts/poietic-icons.ttf"
    
    let rootURL: URL
    
    /// The first resource root that is accepted, or `nil` when there is none.
    static func find() -> ResourceDirectory? {
        for root in candidateRoots() {
            if isResourceRoot(root) {
                return ResourceDirectory(rootURL: root)
            }
        }
        return nil
    }

    /// Resource roots to try, in order of precedence.
    ///
    static func candidateRoots() -> [URL] {
        var roots: [URL] = []

        if let url = locationFromEnvironmentOverride() {
            roots.append(url)
        }

        roots += locationsFromSwiftPM()
        roots += platformLocations()

        return roots
    }

    /// Whether the given location is a resource root, that is, whether it
    /// contains the sentinel file (see ``Sentinel``).
    static func isResourceRoot(_ location: URL) -> Bool {
        FileManager.default.fileExists(atPath: location.appending(path: Self.Sentinel).path)
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
    
    /// Resource roots created by Swift Package Manager, if any.
    ///
    /// `Bundle(path:)` accepts the flat resource directory as well as the bundle,
    /// and `resourceURL` is the directory containing the resources in both cases.
    private static func locationsFromSwiftPM() -> [URL] {
        // In an application bundle: `Contents/Resources`.
        // For a command line executable: the directory containing the executable.
        let bases: [URL?] = [
            Bundle.main.resourceURL,
            Bundle.main.bundleURL,
        ]

        var locations: [URL] = []
        for base in bases {
            guard let base else { continue }
            
            for suffix in Self.SwiftPMBundleSuffixes {
                let directory = base.appending(path: Self.SwiftPMBundleName + suffix,
                                               directoryHint: .isDirectory)
                guard let bundle = Bundle(path: directory.path),
                      let root = bundle.resourceURL
                else { continue }
                locations.append(root)
            }
        }
        return locations
    }
    
    private static func platformLocations() -> [URL] {
        
#if os(Linux)
        let environment = ProcessInfo.processInfo.environment
        return dataDirectories(in: environment).map {
            $0.appending(path: Self.InstallDirectoryName, directoryHint: .isDirectory)
        }
        
#elseif os(Windows)
        // TODO: Add and test Windows resource discovery, at least basic one.
        return []
#else
        // macOS: the SwiftPM bundle lookup above covers both the application bundle and
        //        a `swift run` build.
        return []
#endif
    }
    
    /// Base data directories, in the order they should be searched.
    ///
    /// Reads paths based on the XDG Base Directory specification:
    ///
    /// 1. `XDG_DATA_HOME` (default `$HOME/.local/share`)
    /// 2. The entries of `XDG_DATA_DIRS` (default `/usr/local/share` and `/usr/share`).
    ///
    /// Relative paths are ignored.
    static func dataDirectories(in environment: [String: String]) -> [URL] {
        var paths: [String] = []

        if let dataHome = environment["XDG_DATA_HOME"], !dataHome.isEmpty {
            paths.append(dataHome)
        }
        else if let home = environment["HOME"], !home.isEmpty {
            paths.append(home + "/.local/share")
        }

        if let dataDirs = environment["XDG_DATA_DIRS"], !dataDirs.isEmpty {
            paths.append(contentsOf: dataDirs.split(separator: ":").map(String.init))
        }
        else {
            paths.append(contentsOf: ["/usr/local/share", "/usr/share"])
        }

        return paths.filter { $0.hasPrefix("/") }
                    .map { URL(fileURLWithPath: $0, isDirectory: true) }
    }
    
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
    
    // FIXME: Candidate for removal
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
