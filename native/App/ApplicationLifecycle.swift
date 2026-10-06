import AppKit
import Combine

@MainActor final class MacPlayApplicationDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static weak var shared: MacPlayApplicationDelegate?
    private weak var model: PlayModel?
    private weak var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var modelObservation: AnyCancellable?
    private var windowObservation: NSObjectProtocol?
    private var terminating = false
    private var explicitWindowRequestUntil = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared=self
        windowObservation=NotificationCenter.default.addObserver(forName:NSWindow.didBecomeMainNotification,object:nil,queue:.main) { [weak self] notification in
            Task { @MainActor in
                guard let window=notification.object as? NSWindow,!(window is NSPanel),window.canBecomeMain else {return}
                self?.mainWindow=window
                window.delegate=self
            }
        }
    }

    func install(_ model: PlayModel) {
        Self.shared=self
        if self.model == nil {
            self.model=model
            modelObservation=model.objectWillChange.sink { [weak self] _ in
                DispatchQueue.main.async {self?.updateMenus()}
            }
        }
        if let window=NSApp.windows.first(where:{!($0 is NSPanel) && $0.canBecomeMain}) {
            mainWindow=window;window.delegate=self
        }
        preferencesChanged()
        model.enableAutomaticUSBStart()
    }

    func preferencesChanged() {
        guard let model else {return}
        model.persistPreferences()
        if model.settings.backgroundEnabled == true {
            if statusItem == nil {
                statusItem=NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
                let image=NSImage(systemSymbolName:"car.fill",accessibilityDescription:"MacPlay")
                image?.isTemplate=true
                statusItem?.button?.image=image
                statusItem?.button?.toolTip="MacPlay"
            }
        } else if let item=statusItem {
            NSStatusBar.system.removeStatusItem(item);statusItem=nil
            if mainWindow?.isVisible != true {model.showMainWindow()}
        }
        updateMenus()
    }

    private func menu() -> NSMenu {
        let menu=NSMenu()
        func item(_ title:String,_ action:Selector,enabled:Bool=true) {
            let item=NSMenuItem(title:L(title),action:action,keyEquivalent:"")
            item.target=self;item.isEnabled=enabled;menu.addItem(item)
        }
        item("显示MacPlay",#selector(showMain))
        item("显示CarPlay",#selector(showCarPlay),enabled:model?.running == true)
        menu.addItem(.separator())
        item(model?.receivingOrWaiting == true ? "停止接收" : "启动接收",#selector(toggleReceiver))
        menu.addItem(.separator())
        item("退出MacPlay",#selector(quit))
        return menu
    }

    private func updateMenus() {statusItem?.menu=menu()}
    func applicationDockMenu(_ sender:NSApplication) -> NSMenu? {menu()}
    @objc private func showMain() {
        explicitWindowRequestUntil=Date().addingTimeInterval(1)
        model?.showMainWindow()
    }
    @objc private func showCarPlay() {model?.showCarPlayWindow()}
    func prepareCarPlayPresentation() {
        explicitWindowRequestUntil=Date().addingTimeInterval(1)
        mainWindow?.orderBack(nil)
    }
    @objc private func toggleReceiver() {
        guard let model else {return}
        if model.receivingOrWaiting {model.stop()} else {model.start()}
    }
    @objc private func quit() {NSApp.terminate(nil)}

    func windowShouldClose(_ sender:NSWindow) -> Bool {
        guard sender === mainWindow,!terminating else {return true}
        if model?.settings.backgroundEnabled == true {
            sender.orderOut(nil)
        } else {NSApp.terminate(nil)}
        return false
    }
    func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows:Bool) -> Bool {
        // A Dock menu selection may also generate a reopen event. Preserve its target.
        guard Date() > explicitWindowRequestUntil else {return false}
        model?.showMainWindow();return false
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool {false}
    func applicationShouldTerminate(_ sender:NSApplication) -> NSApplication.TerminateReply {
        terminating=true
        model?.stop(restoreMain:false)
        return .terminateNow
    }
}
