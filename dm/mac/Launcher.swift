// Mac app launcher: the settings window shown before the game starts, in the launcher's own process (launcher.c calls dm_mac_launcher before it starts the host). Its settings come from the
// app's Resources/dm/launcher.json (dm/games/settings.py with SETTINGS_PLATFORM=mac); the model and the rows are the iOS launcher's (dm/ios/Sources/LauncherSettings.swift, LauncherRow.swift),
// and so is the store: launcher.<VAR> in the app's preferences, which launcher.c reads when the window is not shown (docs/frontends.md, Saved choices). Basic settings (level basic) come
// first, the others under Advanced settings, each in the list's sections. Play puts the settings into this process's environment, which the host inherits; Quit and closing the window end the
// app without the game. "Show this window at launch" off: no window unless Option is held at launch, and launcher.c applies the saved choices. The window never takes focus by itself: an app
// opened in the background (open -g) keeps its window behind until the player switches to it
import AppKit
import QuartzCore
import SwiftUI

private func info(_ key: String) -> String? { Bundle.main.object(forInfoDictionaryKey: key) as? String }

struct LauncherView: View {
    @ObservedObject var m: LauncherModel
    let done: (Bool) -> Void
    let fit: (CGFloat) -> Void
    @AppStorage("window.show") private var show = true
    @AppStorage("window.advanced") private var advanced = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info("CFBundleName") ?? "Game").font(.title2.weight(.semibold))
                    Text("Version \(info("CFBundleShortVersionString") ?? "1.0")").foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding([.horizontal, .top], 20)
            Form {
                settingSections(basic: true)
                KeyboardMouseSection()
                CloudSavesSection()
                Section {
                    DisclosureGroup("Advanced settings", isExpanded: $advanced) {}
                }
                if advanced {
                    settingSections(basic: false)
                    Section {
                        Button("Reset to tested defaults") { m.reset() }
                            .disabled(!m.changed)
                    } footer: {
                        Text("Brings back all settings this game was tested with.")
                    }
                }
            }
            .formStyle(.grouped)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentSize.height + $0.contentInsets.top + $0.contentInsets.bottom - $0.containerSize.height
            } action: { _, extraHeight in
                fit(extraHeight)
            }
            HStack {
                Toggle("Show this window at launch", isOn: $show).toggleStyle(.checkbox)
                Spacer()
                Button("Quit") { done(false) }
                Button("Play") { done(true) }.keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(minWidth: 520, idealWidth: 560)
    }

    @ViewBuilder private func settingSections(basic: Bool) -> some View {
        ForEach(m.sections(basic: basic), id: \.self) { section in
            let rows = m.rows(in: section, basic: basic)
            if !rows.isEmpty {
                Section(section) {
                    ForEach(rows) { SettingRow(s: $0, m: m) }
                }
            }
        }
    }
}

/// Cloud saves: a folder the save is synced through (dm/host/save_sync.h), the one the iPhone app picks in its launcher's Cloud saves section. It is kept in this app's
/// preferences as cloudSaves.folder, which launcher.c puts into DM_SAVE_SYNC before the host starts; a DM_SAVE_SYNC an env file or the launch environment set wins, and is shown here.
struct CloudSavesSection: View {
    @AppStorage("cloudSaves.folder") private var folder = ""
    private let fixed: String? = {
        let env = ProcessInfo.processInfo.environment
        let keys = ((env["DM_ENV_FILE_KEYS"] ?? "") + " " + (env["DM_ENV_LAUNCH_KEYS"] ?? "")).split(separator: " ")
        return keys.contains("DM_SAVE_SYNC") || env["DM_SAVE_SYNC"] != nil ? env["DM_SAVE_SYNC"] : nil
    }()

    var body: some View {
        Section {
            LabeledContent("Cloud saves") {
                Text(fixed.map { "\(Self.shown($0)) (env.txt)" } ?? (folder.isEmpty ? "Off" : Self.shown(folder)))
                    .foregroundStyle(.secondary).lineLimit(1).truncationMode(.head)
            }
            if fixed == nil {
                HStack {
                    Button(folder.isEmpty ? "Choose a folder…" : "Choose a different folder…", action: choose)
                    if !folder.isEmpty { Button("Turn off") { folder = "" } }
                }
            }
        } footer: {
            Text("Choose the iCloud Drive folder the iPhone app uses for this game. The save comes in when the game starts and goes out after each save; a save that is replaced is kept in the save's -backups folder.")
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false; panel.canCreateDirectories = true
        panel.prompt = "Use for Cloud Saves"
        panel.message = "The folder the iPhone app chose in its launcher's Cloud saves"
        panel.directoryURL = URL(fileURLWithPath: folder.isEmpty ? Self.drive : folder)
        if panel.runModal() == .OK, let url = panel.url { folder = url.path }
    }

    static let drive = NSHomeDirectory() + "/Library/Mobile Documents/com~apple~CloudDocs"   // iCloud Drive, as the Finder shows it

    /// A path under iCloud Drive as the Finder and the Files app name it: iCloud Drive › Documents › dev › Zelda; any other path as it is
    static func shown(_ path: String) -> String {
        guard path == drive || path.hasPrefix(drive + "/") else { return path }
        return (["iCloud Drive"] + path.dropFirst(drive.count).split(separator: "/").map(String.init)).joined(separator: " › ")
    }
}

/// Keyboard and mouse: the layout of dm/host/keymap_mac.h (the host's own table, through swiftc -import-objc-header), each Switch control with two inputs. A slot clicked waits for
/// the next key, or for a mouse button clicked on that slot (KeyRecorder); a click anywhere else stops waiting, and the × beside a slot clears it. Kept in this app's preferences
/// as keyboard.layout, only the controls that differ from the default (DM_KEYMAP's form), which launcher.c puts into DM_KEYMAP; a DM_KEYMAP an env file or the launch environment set
/// wins, and is shown here. Mouse look and its sensitivity are rows of the settings list (DM_MOUSE, DM_MOUSE_SENS, DM_MOUSE_INVERT)
struct KeyboardMouseSection: View {
    @AppStorage("keyboard.layout") private var spec = ""
    @AppStorage("window.keyboard") private var expanded = true
    @StateObject private var rec = KeyRecorder()
    private let fixed: String? = {
        let env = ProcessInfo.processInfo.environment
        let keys = ((env["DM_ENV_FILE_KEYS"] ?? "") + " " + (env["DM_ENV_LAUNCH_KEYS"] ?? "")).split(separator: " ")
        return keys.contains("DM_KEYMAP") || env["DM_KEYMAP"] != nil ? env["DM_KEYMAP"] ?? "" : nil
    }()

    static let count = Int(km_target_count())
    static let slots = Int(KM_SLOTS)
    static let defaults = layout("")
    static func text(_ p: UnsafePointer<CChar>?) -> String { p.map { String(cString: $0) } ?? "" }
    static func layout(_ spec: String) -> [[Int]] { (0..<count).map { t in (0..<slots).map { Int(km_slot(spec, Int32(t), Int32($0))) } } }
    static func spec(of l: [[Int]]) -> String {   // the controls that differ from the default
        (0..<count).compactMap { t in
            l[t] == defaults[t] ? nil : text(km_target_id(Int32(t))) + "=" + l[t].filter { $0 >= 0 }.map { text(km_input_name(Int32($0))) }.joined(separator: " ")
        }.joined(separator: ";")
    }
    private var groups: [String] {
        (0..<Self.count).map { Self.text(km_target_group(Int32($0))) }.reduce(into: []) { if !$0.contains($1) { $0.append($1) } }
    }

    var body: some View {
        let current = Self.layout(fixed ?? spec)
        Section {
            DisclosureGroup("Keyboard and mouse", isExpanded: $expanded) {}
                .onChange(of: expanded) { rec.stop() }
                .onDisappear { rec.stop() }
        } footer: {
            Text(fixed != nil ? "Set by DM_KEYMAP (env.txt or the launch environment)." :
                 "Click a slot, then press a key, or click the slot with a mouse button. With Mouse look on, click the game to steer the camera with the mouse; ⌘ gives the pointer back.")
        }
        if expanded {
            ForEach(groups, id: \.self) { g in
                Section(g) {
                    ForEach((0..<Self.count).filter { Self.text(km_target_group(Int32($0))) == g }, id: \.self) { t in
                        LabeledContent(Self.text(km_target_label(Int32(t)))) {
                            HStack(spacing: 4) { ForEach(0..<Self.slots, id: \.self) { s in slot(t, s, current[t][s]) } }
                        }
                    }
                }
            }
            if fixed == nil {
                Section {
                    Button("Reset keyboard and mouse") { rec.stop(); spec = "" }.disabled(spec.isEmpty)
                }
            }
        }
    }

    private func slot(_ t: Int, _ s: Int, _ input: Int) -> some View {
        let id = KeyRecorder.Slot(target: t, slot: s), waiting = rec.listening == id
        return HStack(spacing: 2) {
            SlotButton(title: waiting ? "Press a key…" : input >= 0 ? Self.text(km_input_label(Int32(input))) : "–", waiting: waiting, rec: rec, slot: id) { bind(t, s, $0) }
                .frame(width: 112)
            Button { bind(t, s, -1) } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
                .buttonStyle(.borderless).help("Clear").opacity(input >= 0 ? 1 : 0).disabled(input < 0)   // a click on it also ends any wait (KeyRecorder)
        }
        .disabled(fixed != nil)
    }

    private func bind(_ t: Int, _ s: Int, _ input: Int) {   // an input moves to its new control, as the host's layout takes it (km_bind)
        var l = Self.layout(spec)
        if input >= 0 { for u in l.indices { for k in l[u].indices where l[u][k] == input { l[u][k] = -1 } } }
        l[t][s] = input
        spec = Self.spec(of: l)
    }
}

/// Waits for the input of one slot: an event monitor sees keys before the window's key equivalents (Return would press Play) and mouse buttons before any control. A key binds,
/// unless it is a ⌘ shortcut (⌘ cannot be bound, and ⌘W or ⌘Q still work); a mouse button binds when it is clicked on the waiting slot, and a click anywhere else ends the wait
final class KeyRecorder: ObservableObject {
    struct Slot: Hashable { let target, slot: Int }
    @Published private(set) var listening: Slot?
    private var monitor: Any?, take: ((Int) -> Void)?
    private weak var view: NSView?

    func start(_ s: Slot, view: NSView, take: @escaping (Int) -> Void) {
        stop()
        listening = s; self.view = view; self.take = take
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] e in self?.handle(e) ?? e }
    }
    func stop() {
        if let m = monitor { NSEvent.removeMonitor(m) }
        monitor = nil; listening = nil; take = nil; view = nil
    }
    private func bind(_ input: Int) { let f = take; stop(); f?(input) }
    private func handle(_ e: NSEvent) -> NSEvent? {
        switch e.type {
        case .keyDown:
            if e.modifierFlags.contains(.command) { stop(); return e }
            let input = Int(km_input_from_key(e.keyCode))
            if input >= 0 { bind(input) } else { NSSound.beep() }   // Caps Lock, Fn and keys with no name in the layout
            return nil
        case .flagsChanged:
            let bit = km_modifier_bit(e.keyCode)
            if bit != 0 && e.modifierFlags.rawValue & UInt(bit) != 0 { bind(Int(km_input_from_key(e.keyCode))) }
            return e
        default:
            guard let v = view, v.window === e.window, v.bounds.contains(v.convert(e.locationInWindow, from: nil)) else { stop(); return e }
            bind(Int(km_input_from_mouse(e.buttonNumber)))
            return nil
        }
    }
}

/// One slot: a push button (AppKit's, so the recorder can tell a click on it from one elsewhere) that starts the wait
struct SlotButton: NSViewRepresentable {
    let title: String, waiting: Bool, rec: KeyRecorder, slot: KeyRecorder.Slot
    let take: (Int) -> Void

    func makeNSView(context: Context) -> NSButton {
        let b = NSButton(title: title, target: context.coordinator, action: #selector(Coordinator.click(_:)))
        b.bezelStyle = .rounded; b.lineBreakMode = .byTruncatingTail
        b.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return b
    }
    func updateNSView(_ b: NSButton, context: Context) {
        context.coordinator.parent = self
        b.title = title; b.bezelColor = waiting ? .controlAccentColor : nil; b.isEnabled = context.environment.isEnabled
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject {
        var parent: SlotButton
        init(_ p: SlotButton) { parent = p }
        @objc func click(_ b: NSButton) { parent.rec.start(parent.slot, view: b, take: parent.take) }
    }
}

private final class Launcher: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model: LauncherModel
    var window: NSWindow?
    var play = false

    init(_ model: LauncherModel) { self.model = model }

    func applicationDidFinishLaunching(_ n: Notification) {
        let name = info("CFBundleName") ?? "Game"
        let menu = NSMenu(), item = NSMenuItem(), app = NSMenu()
        app.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        app.addItem(withTitle: "Quit \(name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = app; menu.addItem(item); NSApp.mainMenu = menu
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 660), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        w.title = name; w.isReleasedWhenClosed = false; w.delegate = self
        w.contentMinSize = NSSize(width: 520, height: 0)
        window = w
        if let screen = w.screen ?? NSScreen.main {
            w.setFrameTopLeftPoint(NSPoint(x: screen.visibleFrame.midX - w.frame.width / 2, y: screen.visibleFrame.maxY))
        }
        let host = NSHostingView(rootView: LauncherView(m: model, done: { [weak self] in self?.finish($0) }, fit: { [weak self] in self?.fit($0) }))
        host.sizingOptions = []   // the Form's measured scroll content owns the height, including after collapse
        w.contentView = host
        host.layoutSubtreeIfNeeded()
        // no activation and no ordering in front of another app's windows: LaunchServices activates an app opened from Finder or the Dock (applicationDidBecomeActive), open -g does not
        if NSApp.isActive { w.makeKeyAndOrderFront(nil) } else { w.orderBack(nil) }
    }
    func applicationDidBecomeActive(_ n: Notification) { window?.makeKeyAndOrderFront(nil) }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {   // ⌘Q, or a logout or restart: the app ends without the game (exit 0, as Quit)
        fputs("launcher: quit without starting the game\n", stderr)
        return .terminateNow   // not terminateCancel, which a logout or restart takes as a refusal and stops
    }
    func windowWillClose(_ n: Notification) { finish(false) }

    func fit(_ extraHeight: CGFloat) {
        guard let w = window, let screen = w.screen else { return }
        let frame = LauncherWindowLayout.fitted(w.frame, extraHeight: extraHeight, visible: screen.visibleFrame)
        if abs(frame.height - w.frame.height) > 0.5 { w.setFrame(frame, display: true) }
    }

    func finish(_ play: Bool) {
        guard let w = window else { return }
        window = nil; self.play = play
        // The main thread blocks in launcher.c's waitpid once run() returns, so the window must leave the screen now: no fade-out (it runs on later run-loop passes),
        // and dmMacLauncher flushes the order-out (AppKit commits it at the end of a pass). Without both, the window stayed on screen, not responding, until the game ended
        w.animationBehavior = .none
        w.delegate = nil; w.orderOut(nil)
        NSApp.stop(nil)
        NSApp.postEvent(NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0)!, atStart: true)   // run returns at the next event
    }
}

enum LauncherWindowLayout {
    static func fitted(_ frame: NSRect, extraHeight: CGFloat, visible: NSRect) -> NSRect {
        let top = min(frame.maxY, visible.maxY)
        let height = min(frame.height + extraHeight, top - visible.minY)
        return NSRect(x: frame.minX, y: top - height, width: frame.width, height: height)
    }
}

// 1: Play (the window's settings are in the environment), 0: the player quit, 2: no window (no launcher.json, or "Show this window at launch" off): launcher.c applies the saved choices
@_cdecl("dm_mac_launcher")
public func dmMacLauncher() -> Int32 {
    guard let url = Bundle.main.resourceURL?.appendingPathComponent("dm/launcher.json"), let data = try? Data(contentsOf: url) else { return 2 }
    guard let file = try? JSONDecoder().decode(SettingsFile.self, from: data), !file.settings.isEmpty else { fputs("[RED] launcher: dm/launcher.json cannot be read; starting the game\n", stderr); return 2 }
    if (UserDefaults.standard.object(forKey: "window.show") as? Bool) == false && !NSEvent.modifierFlags.contains(.option) {
        fputs("launcher: settings window off (hold Option at launch to show it)\n", stderr)
        return 2
    }
    let model = LauncherModel(file.settings)
    let app = NSApplication.shared, launcher = Launcher(model)
    app.setActivationPolicy(.regular)
    app.delegate = launcher
    fputs("launcher: \(file.settings.count) settings shown\n", stderr)
    app.run()
    CATransaction.flush()   // finish's order-out
    app.setActivationPolicy(.prohibited)   // the host is the game's app from here on
    guard launcher.play else { fputs("launcher: quit without starting the game\n", stderr); return 0 }
    model.apply()
    return 1
}
