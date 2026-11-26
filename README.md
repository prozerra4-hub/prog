# SERPENT ARENA

배틀그라운드식으로 좁아지는 자기장 속에서 90초 동안 먹고, 경쟁자를 물어뜯고 삼키며 성장한 뒤, 최종전(SHOWDOWN)에서 Lv1,000 보스 **Crimson Tyrant**의 금색 꼬리를 깎아 쓰러뜨리는 탑다운 성장형 아레나 IO 액션 게임입니다. 조작과 규칙은 게임 메인 메뉴의 **HOW TO PLAY**에서도 볼 수 있습니다.

- 엔진: **Godot 4.7.2** (GDScript, GL Compatibility 렌더러)
- 해상도: 1280×720 기준, `canvas_items` 스트레치(16:9 외 비율도 확장 대응)
- 외부 플러그인/라이브러리: 없음

## 실행

### Godot 에디터
1. Godot 4.7.x 실행 → **Import** → `C:\Users\jin\Desktop\work\g2\project.godot` 선택
2. `F5` (메인 씬: `res://scenes/main/Main.tscn`)

### 명령줄 (PowerShell)
```powershell
$godot = "C:\Users\jin\Desktop\dev\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
& $godot --path C:\Users\jin\Desktop\work\g2
```

### VS Code
`.vscode/tasks.json`에 작업이 등록되어 있습니다 (`Ctrl+Shift+P` → *Tasks: Run Task*).

| 작업 | 내용 |
|---|---|
| Run Game | 게임 실행 |
| Run Tests | 단위 + 통합 테스트 (헤드리스) |
| Import Project | 리소스/클래스 캐시 재생성 |
| Visual Capture | 실제 창에서 QA 시나리오 스크린샷 저장 |
| Balance Probe | 오토파일럿으로 90초 경기 시뮬레이션 리포트 |

GDScript 언어 서버를 쓰려면 *godot-tools* 확장을 설치하고 Godot 에디터를 열어 두세요 (`settings.json`에 에디터 경로 설정됨).

## 조작

| 입력 | 동작 |
|---|---|
| 마우스 | 머리 → 커서 방향으로 이동 |
| WASD / 방향키 | 방향 조작 (누르고 있는 동안 마우스보다 우선) |
| ESC / P | 일시정지 |

## 테스트

```powershell
& $godot --headless --path . -s tests/run_tests.gd        # 단위 + 통합 (종료 코드 0 = 통과)
& $godot --path . -s tests/scenes/visual_capture.gd -- --out=C:/temp/captures
& $godot --headless --path . -s tests/balance_probe.gd -- --matches=6
```

결과는 [docs/TEST_RESULTS.md](docs/TEST_RESULTS.md)에 기록되어 있습니다.

## 폴더 구조

```
project.godot
assets/serpent_arena/      검수 통과한 리소스 사본 (원본: SERPENT_ARENA_Godot_Assets/, 수정 금지)
scenes/                    main/ game/ actors/snake/ ui/
scripts/
  core/                    Main, GameSession, GameStateMachine, MatchResult
  config/                  밸런스 Resource 클래스 (GameBalance, SnakeTuning, CombatRules …)
  actors/snake/            SnakeActor + 컴포넌트, AI 컨트롤러/상태머신, ai_states/
  actors/boss/             BossController
  systems/                 LevelSystem, CombatSystem, SpawnSystem, ArenaSystem, ScoreSystem, LeaderboardSystem, SnakeSpatialIndex
  entities/                FoodField
  world/                   ArenaFloor, GameCamera, VfxLayer
  services/                Services(autoload), AssetCatalog, SaveService, SettingsService, AudioService
  ui/                      UiTheme, UiKit, HUD/메뉴/일시정지/결과 컨트롤러
  util/                    SpatialHash
resources/                 balance/GameBalance.tres, skins/, ai/, bosses/
shaders/snake_skin.gdshader
tests/                     run_tests.gd, unit/, integration/, scenes/(시각 캡처)
docs/                      설계·아트·에셋·로그·테스트 문서
```

## 문서

- [GAME_DESIGN.md](docs/GAME_DESIGN.md): 규칙, 경기 흐름, 밸런스
- [ART_DIRECTION.md](docs/ART_DIRECTION.md): 비주얼 스타일 가이드
- [ARCHITECTURE.md](docs/ARCHITECTURE.md): 클래스 책임과 의존 관계
- [TECHNICAL_DESIGN.md](docs/TECHNICAL_DESIGN.md): 몸통 추적, 충돌, 성능 설계
- [ASSET_CATALOG.md](docs/ASSET_CATALOG.md): 리소스 검수 결과와 사용처
- [DEVELOPMENT_LOG.md](docs/DEVELOPMENT_LOG.md): 단계별 진행 내역
- [TEST_RESULTS.md](docs/TEST_RESULTS.md): 테스트·QA 결과

## 저장 데이터

`user://serpent_arena_save.cfg` (Windows: `%APPDATA%\Godot\app_userdata\SERPENT ARENA\`). 스키마 버전 1.
