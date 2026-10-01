// 은행 보안 프로그램 메뉴바 토글 — ~/.local/bin/banksec 을 호출한다.
// 빌드는 저장소 루트의 install.sh 가 한다.
import Cocoa

let banksec = NSHomeDirectory() + "/.local/bin/banksec"

struct Product {
    let name: String
    var total = 0
    var running = 0
    var hasPlist = false
    var on: Bool { running > 0 }
    // banksec 이 받는 제품 이름 (영숫자만, 셸에 그대로 넘겨도 안전)
    var slug: String { name.lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) } }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let statusLine = NSMenuItem(title: "확인 중…", action: nil, keyEquivalent: "")
    private let allOnItem = NSMenuItem(title: "모두 켜기", action: #selector(allOn), keyEquivalent: "")
    private let allOffItem = NSMenuItem(title: "모두 끄기", action: #selector(allOff), keyEquivalent: "")
    private let productHeader = NSMenuItem(title: "프로그램별", action: nil, keyEquivalent: "")
    private var productItems: [NSMenuItem] = []
    private var busy = false

    func applicationDidFinishLaunching(_ note: Notification) {
        statusLine.isEnabled = false
        productHeader.isEnabled = false
        allOnItem.target = self
        allOffItem.target = self
        menu.delegate = self
        menu.autoenablesItems = false
        menu.addItem(statusLine)
        menu.addItem(.separator())
        menu.addItem(allOnItem)
        menu.addItem(allOffItem)
        menu.addItem(.separator())
        menu.addItem(productHeader)
        // 제품 항목은 productHeader 바로 아래에 refresh 때마다 다시 채운다
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "메뉴바에서 숨기기", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        refresh()
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func menuWillOpen(_ menu: NSMenu) { refresh() }

    private func refresh() {
        guard !busy else { return }
        DispatchQueue.global().async {
            let result = Self.run("/bin/zsh", [banksec, "status", "--tsv"])
            // 한 줄: 제품 \t label \t enabled \t running \t plist있음
            var byName: [String: Product] = [:]
            for line in result.output.split(separator: "\n") {
                let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                guard f.count >= 5 else { continue }
                var p = byName[f[0]] ?? Product(name: f[0])
                p.total += 1
                if f[3] == "yes" { p.running += 1 }
                if f[4] == "yes" { p.hasPlist = true }
                byName[f[0]] = p
            }
            let products = byName.values.sorted { $0.name.lowercased() < $1.name.lowercased() }
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
        let onCount = products.filter(\.on).count
        setIcon(onCount > 0 ? "lock.shield.fill" : "shield.slash")
        if products.isEmpty {
            statusLine.title = "감지된 은행 보안 프로그램 없음"
        } else if onCount == 0 {
            statusLine.title = "은행 보안: 꺼짐 (\(products.count)개 감지)"
        } else {
            statusLine.title = "은행 보안: \(onCount)/\(products.count)개 켜짐"
        }
        allOnItem.isEnabled = !busy && !products.isEmpty
        allOffItem.isEnabled = !busy && !products.isEmpty

        productItems.forEach(menu.removeItem)
        productItems = products.map { p in
            let mi = NSMenuItem(title: p.name, action: #selector(toggleProduct(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = p.slug
            mi.state = p.on ? .on : .off
            mi.indentationLevel = 1
            if p.hasPlist {
                mi.isEnabled = !busy
                mi.toolTip = p.on ? "실행 중 (\(p.running)/\(p.total)) — 클릭하면 끕니다" : "꺼짐 — 클릭하면 켭니다"
            } else {
                // 서비스 기록만 남고 실행 파일 설정이 없는 경우 — 켜도 실행되지 않는다
                mi.title = "\(p.name) (설치 파일 없음)"
                mi.isEnabled = false
            }
            return mi
        }
        let at = menu.index(of: productHeader) + 1
        for (i, mi) in productItems.enumerated() { menu.insertItem(mi, at: at + i) }
        productHeader.isHidden = products.isEmpty
    }

    private func renderError(_ message: String) {
        setIcon("exclamationmark.shield")
        statusLine.title = message
        allOnItem.isEnabled = false
        allOffItem.isEnabled = false
        productItems.forEach { $0.isEnabled = false }
    }

    private func setIcon(_ symbol: String) {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "은행 보안")
        image?.isTemplate = true
        item.button?.image = image
    }

    @objc private func allOn() { apply("on", product: nil, label: "모든 은행 보안 프로그램을 켜려고") }
    @objc private func allOff() { apply("off", product: nil, label: "모든 은행 보안 프로그램을 끄려고") }

    @objc private func toggleProduct(_ sender: NSMenuItem) {
        guard let slug = sender.representedObject as? String else { return }
        let turningOff = sender.state == .on
        apply(turningOff ? "off" : "on", product: slug,
              label: "\(sender.title)을(를) \(turningOff ? "끄려고" : "켜려고")")
    }

    // 관리자 권한은 macOS 기본 암호 창(Touch ID 지원)으로 받는다.
    // NSAppleScript 를 앱 안에서 실행하면 한 번 인증한 뒤 몇 분간은 다시 묻지 않아서
    // 제품을 여러 개 연달아 켜고 끌 때 편하다.
    private func apply(_ action: String, product: String?, label: String) {
        busy = true
        statusLine.title = action == "on" ? "켜는 중…" : "끄는 중…"
        allOnItem.isEnabled = false
        allOffItem.isEnabled = false
        productItems.forEach { $0.isEnabled = false }
        let cmd = "BANKSEC_UID=\(getuid()) HOME='\(NSHomeDirectory())' /bin/zsh '\(banksec)' \(action) \(product ?? "")"
        let source = "do shell script \"\(cmd)\" with administrator privileges with prompt \"\(label) 합니다.\""
        // 메뉴가 닫히고 상태 문구가 그려진 다음에 실행
        DispatchQueue.main.async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            self.busy = false
            // 사용자가 암호 창을 취소한 경우(-128)는 조용히 넘어간다
            if let error, (error[NSAppleScript.errorNumber] as? Int) != -128 {
                let alert = NSAlert()
                alert.messageText = "은행 보안 프로그램 \(action == "on" ? "켜기" : "끄기") 실패"
                alert.informativeText = (error[NSAppleScript.errorMessage] as? String) ?? "\(error)"
                alert.runModal()
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
