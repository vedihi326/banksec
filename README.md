# banksec — Mac 은행 보안 프로그램 켜기/끄기

인터넷 뱅킹 때문에 설치한 보안 프로그램(AhnLab Safe Transaction, TouchEn nxKey, IPinside, nProtect, Delfino, AnySign, CrossEX 등)은 **은행을 쓰지 않을 때도 항상 백그라운드에서 돌아갑니다.**

banksec 은 이 프로그램들을 **평소엔 꺼두고, 은행 업무를 볼 때만 켤 수 있게** 해 줍니다.

- 🖱 **메뉴바 토글**: 클릭 한 번으로 켜고 끄기 (Touch ID / 관리자 암호)
- 🔍 **자동 감지**: 설치된 보안 프로그램을 알아서 찾음. 새 프로그램이 설치돼도 설정 불필요
- ♻️ **삭제가 아니라 비활성화**: 언제든 원래대로 되돌릴 수 있음
- 🔒 **재부팅해도 유지**: 꺼둔 상태가 재부팅 후에도 그대로

<p align="center"><code>메뉴바 방패 아이콘 → 은행 보안: 꺼짐 (11개 감지) → [켜기] [끄기]</code></p>

## 설치

터미널(응용 프로그램 › 유틸리티 › 터미널)을 열고 아래 한 줄을 붙여 넣으세요.

```sh
curl -fsSL https://raw.githubusercontent.com/vedihi326/banksec/main/install.sh | zsh
```

설치가 끝나면 **메뉴바에 방패 아이콘**이 생기고, 다음 로그인부터 자동으로 뜹니다.

<details>
<summary>직접 받아서 설치하기 / 설치 옵션</summary>

```sh
git clone https://github.com/vedihi326/banksec.git
cd banksec
./install.sh
```

| 옵션 | 설명 |
|---|---|
| `--no-menubar` | 메뉴바 앱 없이 `banksec` 명령어만 설치 |
| `--no-login` | 로그인 시 메뉴바 앱 자동 실행 안 함 |
| `--desktop` | 바탕화면에 앱 바로가기 추가 |

</details>

**요구 사항**
- macOS 13 이상 (macOS 26 Apple Silicon 에서 테스트)
- 메뉴바 앱은 설치 중에 빌드하므로 Xcode 명령어 도구가 필요합니다. 없으면 설치 스크립트가 안내하며, `xcode-select --install` 로 설치할 수 있습니다.

## 사용법

### 메뉴바

| 메뉴바 아이콘 | 상태 |
|---|---|
| 자물쇠가 그려진 **꽉 찬 방패** | 켜짐 — 보안 프로그램 실행 중 |
| 빗금(／)이 그어진 **빈 방패** | 꺼짐 |
| 느낌표가 그려진 방패 | `banksec` 명령어를 찾지 못함 — 다시 설치하세요 |

1. 평소: 메뉴바 아이콘 › **끄기**
2. 은행 업무 전: **켜기** → 은행 사이트 새로고침
3. 끝나면 다시 **끄기**

메뉴에서 "메뉴바에서 숨기기"를 눌렀다면 응용 프로그램 폴더(`~/Applications`)의 **은행보안** 앱을 실행하면 다시 나타납니다.

### 터미널

```sh
banksec off      # 전부 끄기
banksec on       # 전부 켜기
banksec status   # 서비스별 켜짐/실행 상태
banksec list     # 감지된 서비스와 감지 근거, 남은 프로세스
```

`on` / `off` 는 관리자 암호를 묻습니다.

## 동작 원리

macOS 에서 보안 프로그램은 `launchd` 서비스(LaunchDaemon / LaunchAgent)로 부팅·로그인 때 자동 실행됩니다. banksec 은

- **끄기**: `launchctl disable` (재부팅 후에도 자동 실행 안 함) + `launchctl bootout` (지금 즉시 종료) + 남은 프로세스 정리
- **켜기**: `launchctl enable` + `launchctl bootstrap` (즉시 실행)

프로그램 파일은 건드리지 않습니다.

### 자동 감지

보안 업체 키워드(AhnLab, 라온시큐어, 위즈베라, 인터리젠, 이니텍, 소프트포럼, 마크애니, 드림시큐리티 등 약 35개)로 아래 네 곳을 찾아 합칩니다.

1. **설치 패키지 기록** (`pkgutil`): 보안 업체 패키지가 설치한 서비스. 서비스 이름에 업체명이 없어도 잡힙니다.
2. **서비스 설정 파일**: `/Library/LaunchDaemons`, `/Library/LaunchAgents`, `~/Library/LaunchAgents`
3. **지금 실행 중인 서비스**
4. **꺼둔 서비스 기록**: 꺼둔 뒤 설정 파일이 사라져도 다시 켤 수 있게

### 키워드 추가 / 제외

새로운 업체의 프로그램이 잡히지 않으면 키워드를 추가하세요. 스크립트는 고칠 필요가 없습니다.

```sh
mkdir -p ~/.config/banksec
echo "새업체이름" >> ~/.config/banksec/keywords      # 감지 추가
echo "com.example.label" >> ~/.config/banksec/exclude  # 특정 서비스 감지 제외
```

자주 쓰이는 업체인데 빠져 있다면 이슈나 PR 로 알려 주세요.

## 주의 사항

- 꺼진 상태로 은행 사이트에 들어가면 **"보안 프로그램을 설치하세요"** 안내가 나올 수 있습니다. 설치하지 말고 **켜기** 후 새로고침하세요.
- 은행 사이트에서 보안 프로그램을 **업데이트/재설치**하면 자동 실행이 다시 켜질 수 있습니다. 끝나고 한 번 더 **끄기** 하세요.
- 은행 보안 프로그램이 아닌 서비스가 잡혔다면 `banksec list` 로 확인한 뒤 `~/.config/banksec/exclude` 에 추가하세요.

## 삭제

```sh
curl -fsSL https://raw.githubusercontent.com/vedihi326/banksec/main/uninstall.sh | zsh
```

삭제 전에 꺼둔 보안 프로그램을 원래대로 다시 켤지 물어봅니다. (권장: 예)

## 라이선스

[MIT](LICENSE). 이 도구는 시스템 서비스 설정을 바꿉니다. 사용에 따른 책임은 사용자에게 있습니다.
