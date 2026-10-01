#!/bin/zsh
# banksec 삭제 스크립트
#
#   ./uninstall.sh
#   curl -fsSL https://raw.githubusercontent.com/vedihi326/banksec/main/uninstall.sh | zsh
#
# banksec 으로 꺼둔 은행 보안 프로그램은 삭제 후에도 꺼진 채로 남기 때문에,
# 지우기 전에 다시 켤지 먼저 묻는다.

BIN="$HOME/.local/bin/banksec"
APP="$HOME/Applications/은행보안.app"
AGENT_LABEL="io.github.vedihi326.banksec.menu"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

if [[ -x $BIN ]]; then
  printf "은행 보안 프로그램을 원래대로 다시 켤까요? (권장) [Y/n] "
  read -r answer < /dev/tty
  if [[ ${answer:l} != n* ]]; then
    "$BIN" on || echo "⚠️  다시 켜기에 실패했어요. 나중에 은행 사이트에서 보안 프로그램을 재설치하면 됩니다."
  fi
fi

launchctl bootout gui/$(id -u)/$AGENT_LABEL 2>/dev/null
pkill -x BankSecMenu 2>/dev/null
rm -f "$AGENT_PLIST" "$BIN" "$HOME/Desktop/은행보안.app"
rm -rf "$APP" "$HOME/.cache/banksec"

echo "✅ banksec 을 삭제했어요."
[[ -d $HOME/.config/banksec ]] && echo "   사용자 설정(~/.config/banksec)은 남겨 두었어요. 필요 없으면 지우세요."
