//
//  Application+Lifecycle.swift
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/03/2026.
//

import CIimgui

extension Application {
    static let DefaultEventPollTimeout: Int32 = 16
    static let InteractivePreviewEventPollTimeout: Int32 = 4

    func run() {
        loadResources()
        
        self.settingsPanel.bind(self)
        self.controlBar.bind(self)
        self.toolBar.bind(self)
        self.toolBar.currentTool = canvasTools[0]

        // New template design
        let templateURL = ResourceManager.shared.resourceURL(Self.NewDesignTemplatePath)
        do {
            try self.openDesign(url: templateURL)
        }
        catch {
            self.alert(title: "Error",
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

            switch backend.pollEvent(timeout: timeout) {
            case .quit: break loop
            case .skip: continue
            case .none: break
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
        if let actionName = globalShortcutAction() {
            var actionHandled = false
            for panel in panels {
                if panel.isVisible && panel.handleAction(actionName) {
                    actionHandled = true
                }
            }
            if !actionHandled {
                self.handleAction(actionName)
            }
        }
        
    }
    
    func update(_ timeDelta: Double) {
        if let document {
            // Run the Command Queue
            while !document.commandQueue.isEmpty {
                let command = document.commandQueue.removeFirst()
                self.runCommand(command, document: document)
            }
            
            do {
                try document.consumeAndAcceptTransaction()
            }
            catch {
                // This is not user's fault and never should be.
                // The application failed to make sure structural integrity is assured
                Application.shared.alert(title: "Plane validation error (report to developers)",
                                         message: String(describing: error))
                return
            }
            document.update(timeDelta)
        }
        
        if player.isRunning {
            player.update(timeDelta)
        }

        // Update UI components
        canvas.update(timeDelta)
        toolBar.update(timeDelta)
        alertPanel.update(timeDelta)

        for panel in panels {
            panel.update(timeDelta)
        }
        
        // TODO: Is this the right place to call this?
        document?.run(schedule: DocumentCleanupSchedule.self)
    }
    
    func draw() {
        mainMenu()
        canvas.draw()
        
        toolBar.draw()
        alertPanel.draw()
        filePicker.draw()

        for panel in panels {
            guard panel.isVisible else { continue }
            panel.draw()
        }
    }
    
    func processUnhandledInput() {
        let io = ImGui.GetIO().pointee
       
        let events = canvas.recognizeEvents(io)

        for event in events {
            var result: CanvasTool.EngagementResult = .pass
            var toolUsed: CanvasTool? = nil
            
            // 1. Determine which tool handles the event
            if let engagedTool = toolBar.engagedTool {
                // Engaged tool has priority - it gets ALL events
                result = engagedTool.handleEvent(event)
                toolUsed = engagedTool
            }
            else if let currentTool = toolBar.currentTool {
                // No engaged tool - try current tool first
                result = currentTool.handleEvent(event)
                toolUsed = currentTool
                
                // If current tool passed and we have a fallback, try fallback
                if result == .pass,
                   let fallbackTool = toolBar.secondaryTool
                {
                    result = fallbackTool.handleEvent(event)
                    toolUsed = fallbackTool
                }
            }
            
            // 2. Update engagement state based on result
            switch result {
            case .engaged:
                toolBar.engagedTool = toolUsed
                
            case .consumed, .pass:
                toolBar.engagedTool = nil
            }
        }
    }
    
}
