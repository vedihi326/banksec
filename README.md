# banksec — Mac 은행 보안 프로그램 켜기/끄기

인터넷 뱅킹 때문에 설치한 보안 프로그램(AhnLab Safe Transaction, TouchEn nxKey, IPinside, nProtect, Delfino, AnySign, CrossEX 등)은 **은행을 쓰지 않을 때도 항상 백그라운드에서 돌아갑니다.**

banksec 은 이 프로그램들을 **평소엔 꺼두고, 은행 업무를 볼 때만 켤 수 있게** 해 줍니다.

- 🖱 **메뉴바 토글**: 클릭 한 번으로 켜고 끄기 (Touch ID / 관리자 암호)
- ☑️ **프로그램별 선택**: 필요한 것만 골라서 켜고 끄기 (예: TouchEn 만 켜기)
- 🗑 **선택 삭제**: 안 쓰는 프로그램은 골라서 깨끗이 삭제, 지워진 프로그램의 찌꺼기도 정리
- 🔍 **자동 감지**: 설치된 보안 프로그램을 알아서 찾음. 새 프로그램이 설치돼도 설정 불필요
- ♻️ **삭제가 아니라 비활성화**: 언제든 원래대로 되돌릴 수 있음
- 🔒 **재부팅해도 유지**: 꺼둔 상태가 재부팅 후에도 그대로

```
메뉴바 방패 아이콘 ▾
  은행 보안: 1/8개 켜짐
  ─────────────
  모두 켜기
  모두 끄기
  ─────────────
  프로그램별
     AhnLab Safe Transaction
   ✓ TouchEn nxKey
     nProtect Online Security
     INISAFE CrossWeb EX (삭제됨 · 흔적 남음)
     ...
  ─────────────
  프로그램 삭제 ▸
```

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

1. 평소: 메뉴바 아이콘 › **모두 끄기**
2. 은행 업무 전: **모두 켜기** → 은행 사이트 새로고침
3. 끝나면 다시 **모두 끄기**

**프로그램별로 켜고 끄기**: "프로그램별" 아래의 제품 이름을 클릭하면 그 제품만 켜지거나 꺼집니다. 체크(✓) 표시가 있으면 실행 중입니다. 자주 가는 은행에 필요한 것만 켜 두고 싶을 때 쓰세요.
암호를 한 번 입력하면 몇 분 동안은 다시 묻지 않아서 여러 개를 연달아 바꾸기 편합니다.

제품 옆 표시의 뜻:

| 표시 | 뜻 |
|---|---|
| (삭제됨 · 흔적 남음) | 프로그램은 지워졌는데 자동 실행 설정·설치 기록 같은 찌꺼기가 남은 상태. **프로그램 삭제** 메뉴로 정리할 수 있습니다. |
| (상시 실행 없음) | 설치는 돼 있지만 백그라운드에서 항상 돌지는 않는 프로그램. 켜고 끌 필요는 없고 삭제만 할 수 있습니다. |

**프로그램 삭제**: 메뉴의 "프로그램 삭제 ▸"에서 제품을 고르면 **지워질 항목 목록을 먼저 보여 주고**, 확인을 누르면 삭제합니다.

메뉴에서 "메뉴바에서 숨기기"를 눌렀다면 응용 프로그램 폴더(`~/Applications`)의 **은행보안** 앱을 실행하면 다시 나타납니다.

### 터미널

```sh
banksec status              # 제품별 켜짐/꺼짐 상태
banksec off                 # 전부 끄기
banksec on                  # 전부 켜기
banksec on touchen          # TouchEn nxKey 만 켜기
banksec off ahnlab nprotect # 여러 개 골라서 끄기
banksec list                # 제품별 서비스, 감지 근거, 남은 프로세스
banksec remove -n touchen   # TouchEn 을 지우면 무엇이 지워지는지 미리 보기
banksec remove touchen      # 목록을 보여 주고 확인 후 삭제
```

제품 이름은 `banksec status` 의 "명령어에 쓸 이름" 열에 나옵니다. 대소문자·띄어쓰기는 무시하고 이름 일부만 써도 됩니다 (`touchen`, `ahnlab`). `on` / `off` 는 관리자 암호를 묻습니다.

```
$ banksec status
제품                       명령어에 쓸 이름          상태
AhnLab Safe Transaction    ahnlabsafetransaction     꺼짐
TouchEn nxKey              touchennxkey              켜짐 (2/3)
nProtect Online Security   nprotectonlinesecurity    꺼짐
MarkAny ePageSAFER         markanyepagesafer         상시 실행 없음
INISAFE CrossWeb EX        inisafecrosswebex         삭제됨 (흔적 남음)
```

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

감지된 서비스는 이름 규칙에 따라 제품 단위로 묶입니다. (예: `com.astx.firewall.Agent` + `com.astx.firewall.Daemon` → AhnLab Safe Transaction)

### 키워드 · 제품 이름 추가 / 제외

새로운 업체의 프로그램이 잡히지 않거나 제품 이름이 서비스 이름 그대로 나오면 설정 파일에 추가하세요. 스크립트는 고칠 필요가 없습니다.

```sh
mkdir -p ~/.config/banksec
echo "새업체이름" >> ~/.config/banksec/keywords                 # 감지 추가
echo "새 제품 이름:업체키워드|제품키워드" >> ~/.config/banksec/products  # 제품 묶음 규칙 (표시 이름:정규식)
echo "com.example.label" >> ~/.config/banksec/exclude             # 특정 서비스 감지 제외
```

자주 쓰이는 업체인데 빠져 있다면 이슈나 PR 로 알려 주세요.

### 삭제는 어떻게 하나요

설치 패키지 기록(어떤 파일을 설치했는지)을 기준으로 그 제품의 파일, 폴더, 자동 실행 설정, 브라우저 연결 파일, 설치 기록을 지웁니다. 실수로 다른 걸 지우지 않도록 다음을 지킵니다.

- **다른 보안 프로그램과 함께 쓰는 파일은 남깁니다.** 예를 들어 TouchEn 과 CrossEX 가 함께 설치한 브라우저 연결 파일은 TouchEn 만 지울 때 남습니다.
- `/Applications`, `/Library`, `~/Library` 아래만 지우고 시스템 경로(`/System`, `/usr`, `/Library/Apple`)는 건드리지 않습니다.
- 폴더를 통째로 지우는 건 **폴더 이름이 제품과 맞고, 안에 다른 프로그램 파일이 없을 때만**입니다. 공용 폴더는 비어도 남깁니다.
- 경로에 업체 이름이 없는 파일은 설치 기록상 그 제품만 소유한 경우에만 지웁니다.
- 지운 뒤 은행 사이트에서 다시 설치하면 정상적으로 동작하도록 꺼둔 기록도 풀어 둡니다.

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
