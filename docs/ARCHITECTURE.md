# ARCHITECTURE — 클래스 책임과 의존 관계

## 1. 원칙
- **컴포지션 우선:** `SnakeActor`는 컴포넌트를 조립하는 루트일 뿐이고, 이동·경로·몸통·스탯·두뇌·렌더링은 각각 독립 클래스다.
- **결정적 파이프라인:** 각 노드가 `_process`에서 따로 움직이지 않는다. `GameSession`이 정해진 순서로 시스템을 호출한다.
- **UI는 구독만:** HUD/메뉴는 `GameSession` 시그널과 읽기 전용 getter만 쓰고 게임 상태를 바꾸지 않는다.
- **데이터 주도:** 모든 수치는 `Resource`(`resources/`)에 있다. 새 스킨·AI 성향·보스는 `.tres` 추가만으로 만든다 (OCP).
- **전역 상태 최소화:** Autoload는 `Services` 하나뿐이며 경기 상태는 담지 않는다 (에셋·저장·설정·오디오만).

## 2. 레이어와 의존 방향

```
                 ┌──────────── Main (화면 전환) ────────────┐
                 ▼                                           ▼
        MainMenuController                         GameScreenController
        (어트랙트 GameWorld + 메뉴 UI)                 │      │      │
                 │                                    ▼      ▼      ▼
                 │                               GameHUD  PauseMenu ResultScreen   ← UI: 시그널 구독만
                 ▼                                    │
           ┌─────────────────── GameSession (경기 오케스트레이터) ───────────────────┐
           │  LevelSystem  CombatSystem  SpawnSystem  ArenaSystem  ScoreSystem       │
           │  LeaderboardSystem  SnakeSpatialIndex  GameStateMachine  WorldContext   │
           │  MatchDirector  ShowdownDirector  CombatConsequences  RespawnQueue      │
           │  ZoneSystem  ZoneErosion                                                 │
           │  MatchFeedback(연출)  DrawOrderSorter  AttractCamera                     │
           └──────┬───────────────┬──────────────────┬───────────────┬──────────────┘
                  ▼               ▼                  ▼               ▼
             SnakeActor ×12    FoodField          VfxLayer       GameCamera / ArenaFloor
                  │
      ┌───────────┼───────────────┬──────────────┬─────────────┬───────────────┐
      ▼           ▼               ▼              ▼             ▼               ▼
 SnakeMovement SnakePathHistory SnakeBody   SnakeStats   SnakeBrain(추상)  SnakeBodyRenderer
                                                          ├ PlayerBrain ─ PlayerInputSource
                                                          ├ SnakeAIController ─ SnakeAIStateMachine ─ AIState×7
                                                          └ BossController                 ├ SnakeFaceRenderer
                                                                                           └ SnakeCrestRenderer
 모든 레이어 → Services (AssetCatalog, SaveService, SettingsService, AudioService)
 모든 시스템 → config Resources (GameBalance 하위 Resource만 주입받음)
```

- 두뇌(AI/보스)는 `GameSession`이 아니라 **`WorldContext`**(arena, food, index, snakes, player, boss, rng)에만 의존한다 (DIP).
- `SnakeActor`는 구체 컨트롤러를 모르고 `SnakeBrain` 계약만 안다 (LSP: 모든 두뇌가 `think / desired_direction / look_target / speed_factor / on_spawned / on_died`를 같은 의미로 구현).
- 순환 참조 없음: 렌더러 → 액터(읽기), 시스템 → 액터(공개 API), 액터 → 시스템 참조 없음.

## 3. 클래스 책임표

| 클래스 | 파일 | 책임 |
|---|---|---|
| `Main` | core/Main.gd | 메뉴 ↔ 게임 화면 교체, 페이드 전환 |
| `GameSession` | core/GameSession.gd | 시스템 생성·연결, 프레임 파이프라인, `MatchResult` 생성, 이벤트 발행 |
| `MatchDirector` | core/MatchDirector.gd | 시계, 단계(REGULAR→SHOWDOWN→OVER), 종료 예약과 결과 |
| `ShowdownDirector` | core/ShowdownDirector.gd | 쇼다운 진행: 경쟁자 분해, 자기장 최종 단계 시작, 보스 분노 |
| `ZoneSystem` | systems/ZoneSystem.gd | 자기장: 중심·반지름, 대기→축소 단계, 다음 원 공개 |
| `ZoneErosion` | systems/ZoneErosion.gd | 구역 밖 뱀을 꼬리부터 태우고, 끝까지 탄 뱀을 사망 처리 대상으로 반환 |
| `ZoneRenderer` | world/ZoneRenderer.gd | 구역 밖 푸른 장막, 구역 경계선, 다음 원 점선 |
| `CombatConsequences` | core/CombatConsequences.gd | 전투 결과 적용: 잘린 몸 먹이화, 삼킴 보상, 부활/재등장 예약, 보스 처치 승리 |
| `MatchFeedback` | core/MatchFeedback.gd | 이벤트 → VFX/사운드/화면 흔들림 (게임 상태 변경 없음) |
| `RespawnQueue` | core/RespawnQueue.gd | 부활 예약 (지연 + 사망 연출 종료 대기) |
| `GameStateMachine` | core/GameStateMachine.gd | SETUP→PLAYING⇄PAUSED→ENDED 전이 검증 |
| `MatchResult` | core/MatchResult.gd | 경기 결과 데이터 |
| `SnakeActor` | actors/snake/SnakeActor.gd | 컴포넌트 조립, 생명주기(spawn/kill), 반경·길이 보간, 무적 |
| `SnakeMovement` | …/SnakeMovement.gd | 각속도 보간 회전, 속도 보간, 벽 미끄러짐, 튕김 |
| `SnakePathHistory` | …/SnakePathHistory.gd | 머리 궤적 + 누적 거리, 균등 샘플링, 메모리 트림, 꼬리 외삽 |
| `SnakeBody` | …/SnakeBody.gd | 구슬 위치·반지름 계산(렌더·충돌 공용), 꼬리 테이퍼, 삼킴 혹 |
| `SnakeStats` | …/SnakeStats.gd | 총 XP, 레벨(유도), 레벨 상한, 처치/먹이/사망 수, 페널티 |
| `SnakeBrain` | …/SnakeBrain.gd | 조향 계약 (추상) |
| `PlayerInputSource` | …/PlayerInputSource.gd | 마우스/키보드 → 방향 (우선순위 규칙). 터치로 교체 가능 |
| `PlayerBrain` | …/PlayerBrain.gd | 입력을 두뇌 계약에 연결 |
| `SnakeAIController` | …/SnakeAIController.gd | 판단 주기, 인지 갱신, 상태 조향 + 회피 + 경계 합성 |
| `AIPerception` | …/AIPerception.gd | 예측된 위협 입, 장애물 몸통, 최선의 타격 지점, 먹이 군집 |
| `AISteering` | …/AISteering.gd | 16방향 컨텍스트 스티어링 (위험도 맵 + 관심도) |
| `AIContext` | …/AIContext.gd | 상태들이 공유하는 블랙보드 |
| `SnakeAIStateMachine` | …/SnakeAIStateMachine.gd | 상태 등록·전이, 위험 인터럽트 |
| `AIState` + 7개 | …/ai_states/*.gd | 각 상태의 조향과 종료 조건 |
| `BossController` | actors/boss/BossController.gd | 순찰·추격·돌진 예고·돌진·후퇴 |
| `SnakeBodyRenderer` | …/SnakeBodyRenderer.gd | 구슬 드로잉(셰이더), 깜박임, 사망 디졸브 |
| `SnakeFaceRenderer` | …/SnakeFaceRenderer.gd | 눈, 시선, 깜박임, 보스 표정 |
| `SnakeCrestRenderer` | …/SnakeCrestRenderer.gd | 보스 뿔, 글로우(돌진 예고 강도) |
| `LevelSystem` | systems/LevelSystem.gd | XP 공식, 누적표, 레벨↔XP 변환 |
| `CombatSystem` | systems/CombatSystem.gd | 머리 앞쪽 절반 판정 → 몸통 덩어리 물어뜯기/머리 물기/목 삼킴, 보호막 막힘 보고, 대등 튕김, 몸통 미끄러짐 |
| `CombatResult` / `StrikeRecord` / `KillRecord` / `SnakeCut` | systems/… | 한 프레임의 전투 결과 데이터 |
| `SpawnSystem` | systems/SpawnSystem.gd | 뱀 생성, 안전 지점, 초기/부활 레벨, 레벨 상한 지정 |
| `ArenaSystem` | systems/ArenaSystem.gd | 원형 경계, 거리, 무작위 지점 |
| `SnakeSpatialIndex` | systems/SnakeSpatialIndex.gd | 모든 머리·구슬의 공간 해시, 오래된 핸들 거부 |
| `ScoreSystem` | systems/ScoreSystem.gd | 점수 공식 |
| `LeaderboardSystem` | systems/LeaderboardSystem.gd | 0.25초마다 순위 계산, 순위 변화 시그널 |
| `WorldContext` | systems/WorldContext.gd | 두뇌·시스템용 좁은 월드 API |
| `FoodStore` | entities/FoodStore.gd | 먹이 데이터(패킹 배열 풀) + 공간 해시 |
| `FoodField` | entities/FoodField.gd | 생성·보충, 흡수, 사체/잘린 몸 먹이, AI용 군집 탐색 |
| `FoodRenderer` | entities/FoodRenderer.gd | 화면 안 먹이 일괄 드로잉, 최소 화면 크기 보장 |
| `ArenaFloor` | world/ArenaFloor.gd | 타일 바닥, 경계 그림자, 경계선 |
| `GameCamera` | world/GameCamera.gd | 추적, 줌, 흔들림 |
| `VfxLayer` | world/VfxLayer.gd | 스프라이트 이펙트 풀(36), 머리 추적 |
| `Services` (autoload) | services/Services.gd | 서비스 소유 |
| `AssetCatalog` / `AssetIds` | services/… | 텍스처 등록·캐시·누락 보고 / 키 상수 |
| `SaveService` | services/SaveService.gd | 로컬 저장, 버전, 기록 갱신 |
| `SettingsService` | services/SettingsService.gd | 설정 적용·저장 |
| `AudioService` | services/AudioService.gd | 효과음 합성, 보이스 풀, 빈도 제한 |
| `UiTheme` / `UiKit` / `UiFormat` | ui/… | 테마·팔레트 / 컨트롤 팩토리·전환 / 숫자·시간 포맷 |
| `GameScreenController` | ui/… | 경기 시작, 일시정지 입력, 결과 저장, 화면 이동 요청 |
| `GameHUDController` | ui/… | HUD 배치와 시그널 라우팅 |
| `HudStatusPanel` / `HudZonePanel` / `HudBossCard` / `HudGrowthBar` / `KillFeed` / `HudToast` / `HurtVignette` / `ControlsHint` / `Minimap` / `FloatingTextLayer` | ui/hud/… | HUD 구성 요소 (각각 하나의 표시 책임) |
| `NameplateLayer` / `HudLeaderboard` / `BossIndicator` | ui/… | 이름표 / 순위표 / 보스 방향 |
| `PauseMenuController` / `ResultScreenController` / `MainMenuController` / `SkinPreview` | ui/… | 각 화면 |
| `MenuView` / `MenuHowToView` / `MenuSkinsView` / `MenuSettingsView` | ui/menu/… | 메인 메뉴의 개별 화면 |
| `DrawOrderSorter` / `AttractCamera` | world/… | 그리기 순서 정렬 / 메뉴 배경 카메라 |

## 4. 이벤트 (GameSession 시그널)

`game_started`, `game_paused`, `game_resumed`, `game_over(result)`, `level_up(actor, old, new)`, `food_collected(actor, xp)`, `snake_struck(striker, victim, kind, xp_taken, at)`, `strike_blocked(striker, target, at)`, `snake_eroded(actor, xp_lost)`, `phase_changed(phase)`, `snake_died(victim, killer)`, `snake_respawned(actor)`, `combat_resolved(winner, loser)`, `boss_spawned(boss)`, `boss_defeated(by)`, `rank_changed(actor, old, new)`, `leaderboard_updated(entries)`, `time_changed(sec)`, `revives_changed(n)`, `player_respawn_scheduled(delay)`

전역 SignalHub는 두지 않았다. 구독자가 모두 경기 화면 안에 있어서 세션 시그널로 충분하다.

## 5. 확장 방법
- **새 스킨:** `resources/skins/x.tres`(SnakeSkin) 추가 → `GameBalance.player_skins`에 등록
- **새 AI 성향:** `resources/ai/x.tres`(AIPersonality) → `ai_personalities`
- **자기장 단계 변경:** `GameBalance.tres`의 `ZonePhase` 서브리소스(대기·축소 시간, 목표 반지름, 중심 이동량)를 추가/수정
- **새 보스:** `resources/bosses/x.tres`(BossDefinition) → `GameBalance.boss`. 행동이 다르면 `SnakeBrain`을 상속한 새 컨트롤러 추가
- **새 먹이:** `FoodKind` 서브리소스 추가
- **새 AI 상태:** `AIState` 상속 클래스 + `SnakeAIStateMachine._init` 등록
- **모바일 입력:** `PlayerInputSource`와 같은 `read_direction()`을 가진 터치 입력 클래스로 교체
