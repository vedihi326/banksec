#!/bin/zsh
# banksec 설치 스크립트
#
#   ./install.sh                 CLI + 메뉴바 앱 + 로그인 시 자동 실행
#   ./install.sh --no-menubar    CLI(banksec 명령어)만 설치
#   ./install.sh --no-login      메뉴바 앱은 설치하되 로그인 시 자동 실행 안 함
#   ./install.sh --desktop       바탕화면에 앱 바로가기도 만들기
#
# 한 줄 설치:
#   curl -fsSL https://raw.githubusercontent.com/vedihi326/banksec/main/install.sh | zsh
set -e

REPO_TARBALL="https://github.com/vedihi326/banksec/archive/refs/heads/main.tar.gz"
BIN_DIR="$HOME/.local/bin"
APP="$HOME/Applications/은행보안.app"
BUNDLE_ID="io.github.vedihi326.banksec"
AGENT_LABEL="$BUNDLE_ID.menu"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

MENUBAR=1 LOGIN=1 DESKTOP=0
for arg in "$@"; do
  case $arg in
    --no-menubar) MENUBAR=0; LOGIN=0 ;;
    --no-login)   LOGIN=0 ;;
    --desktop)    DESKTOP=1 ;;
    -h|--help)    sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "알 수 없는 옵션: $arg"; exit 1 ;;
  esac
done

[[ $(uname) == Darwin ]] || { echo "macOS 전용입니다."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "sudo 없이 실행해 주세요. (필요할 때만 암호를 물어봅니다)"; exit 1; }

# curl | zsh 로 실행된 경우 소스를 내려받는다
SRC=${0:A:h}
if [[ ! -f $SRC/banksec || ! -f $SRC/menubar/BankSecMenu.swift ]]; then
  SRC=$(mktemp -d)
  trap 'rm -rf "$SRC"' EXIT
  echo "⬇️  소스 내려받는 중..."
  curl -fsSL "$REPO_TARBALL" | tar -xz -C "$SRC" --strip-components 1
fi

echo "📦 banksec 명령어 설치 → $BIN_DIR/banksec"
mkdir -p "$BIN_DIR"
install -m 755 "$SRC/banksec" "$BIN_DIR/banksec"

if (( MENUBAR )); then
  if ! xcrun --find swiftc >/dev/null 2>&1; then
    echo "⚠️  메뉴바 앱을 빌드하려면 Xcode 명령어 도구가 필요해요."
    echo "    xcode-select --install 로 설치한 뒤 다시 실행하거나,"
    echo "    ./install.sh --no-menubar 로 명령어만 설치하세요."
    exit 1
  fi
  echo "🔨 메뉴바 앱 빌드 → $APP"
  pkill -x BankSecMenu 2>/dev/null || true
  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS"
  xcrun swiftc -O -o "$APP/Contents/MacOS/BankSecMenu" "$SRC/menubar/BankSecMenu.swift"
  cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>BankSecMenu</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>은행보안</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSUIElement</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
EOF
  codesign --force --sign - "$APP" 2>/dev/null

  if (( LOGIN )); then
    echo "🚀 로그인 시 자동 실행 등록"
    mkdir -p "${AGENT_PLIST:h}"
    cat > "$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$AGENT_LABEL</string>
  <key>ProgramArguments</key><array><string>/usr/bin/open</string><string>-a</string><string>$APP</string></array>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
    launchctl bootout gui/$(id -u)/$AGENT_LABEL 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) "$AGENT_PLIST"
  else
    open "$APP"
  fi

  if (( DESKTOP )); then
    ln -sfn "$APP" "$HOME/Desktop/은행보안.app"
  fi
fi

echo
echo "✅ 설치 완료"
echo
"$BIN_DIR/banksec" status
echo
(( MENUBAR )) && echo "• 메뉴바의 방패 아이콘에서 켜기/끄기를 고르세요."
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "• 터미널에서 banksec 명령어를 쓰려면 PATH 에 추가하세요:"
  echo "    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
else
  echo "• 터미널: banksec off | on | status | list"
fi
