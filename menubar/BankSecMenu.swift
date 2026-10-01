// 은행 보안 프로그램 메뉴바 토글 — ~/.local/bin/banksec 을 호출한다.
// 빌드는 저장소 루트의 install.sh 가 한다.
import Cocoa

let banksec = NSHomeDirectory() + "/.local/bin/banksec"

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let statusLine = NSMenuItem(title: "확인 중…", action: nil, keyEquivalent: "")
    private let onItem = NSMenuItem(title: "켜기", action: #selector(turnOn), keyEquivalent: "")
    private let offItem = NSMenuItem(title: "끄기", action: #selector(turnOff), keyEquivalent: "")
    private var busy = false

    func applicationDidFinishLaunching(_ note: Notification) {
        statusLine.isEnabled = false
        onItem.target = self
        offItem.target = self
        menu.delegate = self
        menu.autoenablesItems = false
        menu.addItem(statusLine)
        menu.addItem(.separator())
        menu.addItem(onItem)
        menu.addItem(offItem)
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
            let result = Self.run("/bin/zsh", [banksec, "status"])
            // banksec status: 헤더 다음 줄부터 "LABEL ENABLED RUNNING"
            let rows = result.output.split(separator: "\n").dropFirst()
                .map { $0.split(separator: " ", omittingEmptySubsequences: true) }
                .filter { $0.count >= 3 }
            let running = rows.filter { $0[2] == "yes" }.count
            DispatchQueue.main.async {
                if result.status != 0 {
                    self.renderError("banksec 을 찾을 수 없어요 (\(banksec))")
                } else {
                    self.render(running: running, total: rows.count)
                }
            }
        }
    }

    // 실제로 실행 중인 서비스가 하나라도 있으면 켜짐으로 본다
    private func render(running: Int, total: Int) {
        let on = running > 0
        setIcon(on ? "lock.shield.fill" : "shield.slash")
        if total == 0 {
            statusLine.title = "감지된 은행 보안 프로그램 없음"
        } else {
            statusLine.title = on ? "은행 보안: 켜짐 (\(running)/\(total) 실행 중)" : "은행 보안: 꺼짐 (\(total)개 감지)"
        }
        onItem.state = on ? .on : .off
        offItem.state = on ? .off : .on
        onItem.isEnabled = !busy && total > 0
        offItem.isEnabled = !busy && total > 0
    }

    private func renderError(_ message: String) {
        setIcon("exclamationmark.shield")
        statusLine.title = message
        onItem.isEnabled = false
        offItem.isEnabled = false
    }

    private func setIcon(_ symbol: String) {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "은행 보안")
        image?.isTemplate = true
        item.button?.image = image
    }

    @objc private func turnOn() { apply("on") }
    @objc private func turnOff() { apply("off") }

    // 관리자 권한은 macOS 기본 암호 창(Touch ID 지원)으로 받는다
    private func apply(_ action: String) {
        busy = true
        statusLine.title = action == "on" ? "켜는 중…" : "끄는 중…"
        onItem.isEnabled = false
        offItem.isEnabled = false
        let verb = action == "on" ? "켜려고" : "끄려고"
        let cmd = "BANKSEC_UID=\(getuid()) HOME='\(NSHomeDirectory())' /bin/zsh '\(banksec)' \(action)"
        let script = "do shell script \"\(cmd)\" with administrator privileges with prompt \"은행 보안 프로그램을 \(verb) 합니다.\""
        DispatchQueue.global().async {
            let result = Self.run("/usr/bin/osascript", ["-e", script])
            DispatchQueue.main.async {
                self.busy = false
                // 사용자가 암호 창을 취소한 경우(-128)는 조용히 넘어간다
                if result.status != 0 && !result.error.contains("-128") {
                    let alert = NSAlert()
                    alert.messageText = "은행 보안 프로그램 \(action == "on" ? "켜기" : "끄기") 실패"
                    alert.informativeText = result.error
                    alert.runModal()
                }
                self.refresh()
            }
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
