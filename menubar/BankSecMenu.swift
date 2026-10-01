// 은행 보안 프로그램 메뉴바 토글 — ~/.local/bin/banksec 을 호출한다.
// 빌드는 저장소 루트의 install.sh 가 한다.
import Cocoa

let banksec = NSHomeDirectory() + "/.local/bin/banksec"

struct Product {
    let name: String
    let slug: String      // banksec 이 받는 제품 이름 (영숫자만, 셸에 그대로 넘겨도 안전)
    let state: String     // on | off | removed | noservice
    let running: Int
    let total: Int
    var on: Bool { state == "on" }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let statusLine = NSMenuItem(title: "확인 중…", action: nil, keyEquivalent: "")
    private let allOnItem = NSMenuItem(title: "모두 켜기", action: #selector(allOn), keyEquivalent: "")
    private let allOffItem = NSMenuItem(title: "모두 끄기", action: #selector(allOff), keyEquivalent: "")
    private let productHeader = NSMenuItem(title: "프로그램별", action: nil, keyEquivalent: "")
    private let removeItem = NSMenuItem(title: "프로그램 삭제", action: nil, keyEquivalent: "")
    private let removeMenu = NSMenu()
    private var productItems: [NSMenuItem] = []
    private var busy = false

    func applicationDidFinishLaunching(_ note: Notification) {
        statusLine.isEnabled = false
        productHeader.isEnabled = false
        allOnItem.target = self
        allOffItem.target = self
        menu.delegate = self
        menu.autoenablesItems = false
        removeMenu.autoenablesItems = false
        removeItem.submenu = removeMenu
        menu.addItem(statusLine)
        menu.addItem(.separator())
        menu.addItem(allOnItem)
        menu.addItem(allOffItem)
        menu.addItem(.separator())
        menu.addItem(productHeader)
        // 제품 항목은 productHeader 바로 아래에 refresh 때마다 다시 채운다
        menu.addItem(.separator())
        menu.addItem(removeItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "메뉴바에서 숨기기", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        refresh()
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func menuWillOpen(_ menu: NSMenu) { if menu === self.menu { refresh() } }

    private func refresh() {
        guard !busy else { return }
        DispatchQueue.global().async {
            let result = Self.run("/bin/zsh", [banksec, "status", "--tsv"])
            // 한 줄: 이름 \t slug \t 상태 \t 실행 중 \t 서비스 수
            let products: [Product] = result.output.split(separator: "\n").compactMap { line in
                let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                guard f.count >= 5 else { return nil }
                return Product(name: f[0], slug: f[1], state: f[2], running: Int(f[3]) ?? 0, total: Int(f[4]) ?? 0)
            }
            DispatchQueue.main.async {
                if result.status != 0 {
                    self.renderError("banksec 을 찾을 수 없어요 (\(banksec))")
                } else {
                    self.render(products)
                }
            }
        }
    }

    private func render(_ products: [Product]) {
        let switchable = products.filter { $0.state == "on" || $0.state == "off" }
        let onCount = switchable.filter(\.on).count
        setIcon(onCount > 0 ? "lock.shield.fill" : "shield.slash")
        if switchable.isEmpty {
            statusLine.title = "켜고 끌 은행 보안 프로그램 없음"
        } else if onCount == 0 {
            statusLine.title = "은행 보안: 꺼짐 (\(switchable.count)개)"
        } else {
            statusLine.title = "은행 보안: \(onCount)/\(switchable.count)개 켜짐"
        }
        allOnItem.isEnabled = !busy && !switchable.isEmpty
        allOffItem.isEnabled = !busy && !switchable.isEmpty

        productItems.forEach(menu.removeItem)
        productItems = products.map { p in
            let mi = NSMenuItem(title: p.name, action: #selector(toggleProduct(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = p.slug
            mi.state = p.on ? .on : .off
            mi.indentationLevel = 1
            switch p.state {
            case "on", "off":
                mi.isEnabled = !busy
                mi.toolTip = p.on ? "실행 중 (\(p.running)/\(p.total)) — 클릭하면 끕니다" : "꺼짐 — 클릭하면 켭니다"
            case "noservice":
                mi.title = "\(p.name) (상시 실행 없음)"
                mi.isEnabled = false
            default:
                // 프로그램은 지워지고 서비스 흔적만 남은 경우 — 켜도 실행되지 않는다
                mi.title = "\(p.name) (삭제됨 · 흔적 남음)"
                mi.isEnabled = false
            }
            return mi
        }
        let at = menu.index(of: productHeader) + 1
        for (i, mi) in productItems.enumerated() { menu.insertItem(mi, at: at + i) }
        productHeader.isHidden = products.isEmpty

        removeMenu.removeAllItems()
        for p in products {
            let mi = NSMenuItem(title: p.state == "removed" ? "\(p.name) — 흔적 정리" : "\(p.name)…",
                                action: #selector(removeProduct(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = p
            mi.isEnabled = !busy
            removeMenu.addItem(mi)
        }
        removeItem.isEnabled = !busy && !products.isEmpty
    }

    private func renderError(_ message: String) {
        setIcon("exclamationmark.shield")
        statusLine.title = message
        allOnItem.isEnabled = false
        allOffItem.isEnabled = false
        removeItem.isEnabled = false
        productItems.forEach { $0.isEnabled = false }
    }

    private func setIcon(_ symbol: String) {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "은행 보안")
        image?.isTemplate = true
        item.button?.image = image
    }

    @objc private func allOn() { runAdmin(["on"], prompt: "모든 은행 보안 프로그램을 켜려고") }
    @objc private func allOff() { runAdmin(["off"], prompt: "모든 은행 보안 프로그램을 끄려고") }

    @objc private func toggleProduct(_ sender: NSMenuItem) {
        guard let slug = sender.representedObject as? String else { return }
        let turningOff = sender.state == .on
        runAdmin([turningOff ? "off" : "on", slug],
                 prompt: "\(sender.title)을(를) \(turningOff ? "끄려고" : "켜려고")")
    }

    // 삭제: 먼저 지울 목록을 보여 주고 확인을 받은 뒤 실행
    @objc private func removeProduct(_ sender: NSMenuItem) {
        guard let p = sender.representedObject as? Product else { return }
        DispatchQueue.global().async {
            let plan = Self.run("/bin/zsh", [banksec, "remove", "--dry-run", p.slug]).output
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "\(p.name)을(를) 삭제할까요?"
                alert.informativeText = "아래 항목이 삭제되고 되돌릴 수 없어요. 다시 필요하면 은행 사이트에서 새로 설치하면 됩니다."
                alert.accessoryView = Self.textView(plan)
                let ok = alert.addButton(withTitle: "삭제")
                ok.hasDestructiveAction = true
                alert.addButton(withTitle: "취소")
                guard alert.runModal() == .alertFirstButtonReturn else { return }
                self.runAdmin(["remove", "--yes", p.slug], prompt: "\(p.name)을(를) 삭제하려고") { output in
                    let done = NSAlert()
                    done.messageText = "\(p.name) 삭제 완료"
                    done.accessoryView = Self.textView(output)
                    done.runModal()
                }
            }
        }
    }

    private static func textView(_ text: String) -> NSView {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 520, height: 260))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let tv = NSTextView(frame: scroll.bounds)
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.string = text.trimmingCharacters(in: .whitespacesAndNewlines)
        tv.autoresizingMask = [.width]
        scroll.documentView = tv
        return scroll
    }

    // 관리자 권한은 macOS 기본 암호 창(Touch ID 지원)으로 받는다.
    // NSAppleScript 를 앱 안에서 실행하면 한 번 인증한 뒤 몇 분간은 다시 묻지 않아서
    // 제품을 여러 개 연달아 켜고 끌 때 편하다.
    private func runAdmin(_ args: [String], prompt: String, onSuccess: ((String) -> Void)? = nil) {
        busy = true
        statusLine.title = "처리 중…"
        allOnItem.isEnabled = false
        allOffItem.isEnabled = false
        removeItem.isEnabled = false
        productItems.forEach { $0.isEnabled = false }
        // args 는 on/off/remove/--yes 와 slug(영숫자)뿐이라 따옴표 없이 넘겨도 안전
        let cmd = "BANKSEC_UID=\(getuid()) HOME='\(NSHomeDirectory())' /bin/zsh '\(banksec)' \(args.joined(separator: " "))"
        let source = "do shell script \"\(cmd)\" with administrator privileges with prompt \"\(prompt) 합니다.\""
        // 메뉴가 닫히고 상태 문구가 그려진 다음에 실행
        DispatchQueue.main.async {
            var error: NSDictionary?
            let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
            self.busy = false
            if let error {
                // 사용자가 암호 창을 취소한 경우(-128)는 조용히 넘어간다
                if (error[NSAppleScript.errorNumber] as? Int) != -128 {
                    let alert = NSAlert()
                    alert.messageText = "실패했어요"
                    alert.informativeText = (error[NSAppleScript.errorMessage] as? String) ?? "\(error)"
                    alert.runModal()
                }
            } else {
                // do shell script 는 줄바꿈을 \r 로 돌려준다
                onSuccess?((result?.stringValue ?? "").replacingOccurrences(of: "\r", with: "\n"))
            }
            self.refresh()
        }
    }

    private static func run(_ path: String, _ args: [String]) -> (status: Int32, output: String, error: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let out = Pipe(), err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do { try p.run() } catch { return (-1, "", "\(error)") }
        let o = out.fileHandleForReading.readDataToEndOfFile()
        let e = err.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(decoding: o, as: UTF8.self), String(decoding: e, as: UTF8.self))
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
