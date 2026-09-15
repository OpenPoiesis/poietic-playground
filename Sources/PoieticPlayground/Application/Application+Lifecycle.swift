//
//  Application+Lifecycle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import CIimgui
import Foundation
import Diagramming // #TODO: Remove this once we unite Vector2D + Point

extension Application {
    static let DefaultEventPollTimeout: Int32 = 16
    static let InteractivePreviewEventPollTimeout: Int32 = 4

    func run() {
        loadResources()
        
        self.settingsPanel.bind(self)

        // New template design
        let templateURL = ResourceManager.shared.resourceURL(Self.NewDesignTemplatePath)
        do {
            try self.openDesign(url: templateURL)
        }
        catch {
            self.queueAlert(title: "Error",
                       message: "Unable to open template design '\(templateURL)'. Reason: \(error)")
            self.newDesign()
        }
        
        mainLoop()
    }

    func mainLoop() {
        let backend = GraphicsBackend.shared
        var lastTime = ImGui.GetTime()

        loop: while !quitRequested {
            let timeout: Int32
            if let document {
                timeout = document.requiresInteractivePreviewUpdate ? Self.InteractivePreviewEventPollTimeout : Self.DefaultEventPollTimeout
            }
            else {
                timeout = Self.DefaultEventPollTimeout
            }

            // FIXME: [IMPORTANT] Too crowded, clean-it up.
            switch backend.pollEvent(timeout: timeout) {
            case .quit:
                self.handleAction(.quit) // Handle quit with confirmation
            case .skip: continue
            case .none: break
            case .gesture(let gesture):
                guard canvas.isMouseInViewport else { break }
                pendingBackendGestures.append(gesture)
            case .dropFile(path: let path):
                let url = URL(fileURLWithPath: path)
                self.startFlow(OpenDocumentFromURLFlow(context: self, url: url))
            }
            
            backend.newFrame()
            ImGui.NewFrame()
            
            let newTime = ImGui.GetTime()
            let timeDelta = newTime - lastTime
            lastTime = newTime
            
            self.processInput()
            self.update(timeDelta)
            self.draw()
            self.processUnhandledInput()
            
            // BEGIN Debug
//            applicationSessionDebugWindow()
//            ImGui.ShowDebugLogWindow()
//            ImGui.ShowIDStackToolWindow()
//            ImGui.ShowDemoWindow()
            // END Debug
            
            ImGui.Render()
            backend.render()
        }
    }
    func processInput() {
        guard !isInteractionBlocked else { return }
        
        if let action = globalShortcutAction() {
            var actionHandled = false
            for panel in panels {
                if panel.isVisible && panel.handleAction(action) {
                    actionHandled = true
                }
            }
            if !actionHandled {
                self.handleAction(action)
            }
        }
        
    }
    
    func update(_ timeDelta: Double) {
        updateDialogs()
        decisionManager.update()

       
        workspace?.update(timeDelta)

        for panel in panels {
            panel.update(timeDelta)
        }
        
    }
    
    
    func draw() {
        mainMenu()

        workspace?.draw()
        
        for panel in panels {
            guard panel.isVisible else { continue }
            panel.draw()
        }
        
        self.activeModal?.draw()
    }
   
    // TODO: MARK ---- INPUT REFACTORING BELOW ---
    
    func makeInputFrame() -> InputFrame {
        let io = ImGui.GetIO().pointee
        let clicks = io.MouseClickedCount
        let dragDistance = io.MouseDragMaxDistanceSqr
        
        let escapePressed = ImGui.IsKeyPressed(ImGuiKey_Escape)

        let frame = InputFrame(
            pointer: Vector2D(io.MousePos),
            pointerDelta: Vector2D(io.MouseDelta),
            buttonsDown: MouseButtonMask(io.MouseDown),
            buttonsClicked: MouseButtonMask(io.MouseClicked),
            buttonsReleased: MouseButtonMask(io.MouseReleased),
            clickCounts: MouseButtonValues([
                .left: Int(clicks.0),
                .right: Int(clicks.1),
                .middle: Int(clicks.2),
                .other1: Int(clicks.3),
                .other2: Int(clicks.4)
            ], default: 0),
            dragMaxDistance: MouseButtonValues([
                .left: Double(dragDistance.0.squareRoot()),
                .right: Double(dragDistance.1.squareRoot()),
                .middle: Double(dragDistance.2.squareRoot()),
                .other1: Double(dragDistance.3.squareRoot()),
                .other2: Double(dragDistance.4.squareRoot())
            ], default: 0),
            modifiers: KeyModifiers(io.KeyMods),
            scroll: Vector2D(Double(io.MouseWheelH), Double(io.MouseWheel)),
            escapePressed: escapePressed
        )
        return frame
    }
    
    func processUnhandledInput() {
        guard !isInteractionBlocked else {
            workspace?.dropToolEvents()
            return
        }

        let frame = makeInputFrame()
        workspace?.processInput(frame, gestures: pendingBackendGestures)
        pendingBackendGestures.removeAll()
    }
}
