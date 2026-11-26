# ASSET CATALOG — 리소스 검수 결과와 사용처

원본: `SERPENT_ARENA_Godot_Assets/SERPENT_ARENA_ASSETS/` (삭제·이동·수정하지 않음)
프로젝트 사본: `res://assets/serpent_arena/` (검수 통과 + 실제 사용 파일만)
코드 접근: `AssetCatalog` + `AssetIds` 상수 (경로 하드코딩 없음, 누락 시 `push_error`)

## 1. 검수 방법

Pillow 등 외부 패키지 없이 Python 표준 라이브러리로 PNG를 직접 디코딩해 검사했습니다 (CRC, 필터, 알파 채널 실측). 이어서 모든 아틀라스를 눈으로 검수하고, 실제 Godot 화면(창 모드 캡처)에서 다시 확인했습니다.

| 항목 | 결과 |
|---|---|
| 파일 수 | 개별 PNG 75 + 아틀라스 5 + manifest + README |
| 손상 | 0 (전 파일 CRC·디코딩 정상) |
| 포맷 | 전부 8-bit RGBA, non-interlaced |
| 투명 배경 | 실제 알파 채널. 체커보드가 픽셀로 박힌 이미지 0 |
| 아틀라스 규격 | 뱀/VFX 1024² (셀 256), 먹이/경기장/UI 512² (셀 128): manifest와 일치 |
| manifest 좌표 | 80 프레임 전부 아틀라스 내부, 개별 PNG와 픽셀 대조 |
| 개별 PNG ↔ 아틀라스 | 76/80 완전 일치. `death_smoke`, `speed_streak_*`: 최대 오차 2 (압축 반올림, 무시 가능). **`arena_05_center_glow`: 평균 10.2, 최대 125 차이** (아틀라스와 개별 파일이 다른 이미지, 미사용) |
| 잘림/여백 | 캐릭터·먹이·VFX·아이콘 모두 셀 경계에 닿는 픽셀 0 (잘림 없음) |
| 중복 | `arena_13~16` = `arena_01~04` 와 동일 픽셀 |
| 타일링 | `arena_01_dots`, `arena_04_speckle`, `arena_12_plain`: 좌우/상하 이음매 오차 0. `arena_02_hex`: 이음매 오차가 내부 변화량보다 작음(사용 가능). `arena_03_grid`: 한쪽 가장자리에만 선 (반복 시 격자로 정상). `arena_10_corner`: 비반복 타일 |

### 실측 기하 (드로잉 스케일 기준)

| 리소스 | 불투명 구 지름 | 비고 |
|---|---|---|
| `body_segment_*.png` (256²) | 133 px, 중심 (128,128) | `AssetIds.BEAD_SPRITE_RADIUS_PX = 66.5` |
| `food_small_gold` (128²) | 49 px | |
| `food_medium_gold`, `food_red/purple/cyan/green` | 63 px | `sprite_radius_px = 31.5` |
| `food_large_gold` | 79 px | `39.5` |
| `food_rare_orange` | 73 px | `36.5` |
| `gem_*` | 87×95 px | `45.0` |

## 2. 사용 리소스 (26개 PNG)

모두 Import 설정: Lossless, **Mipmaps ON** (축소 드로잉 시 반짝임 방지), 필터 Linear+Mipmaps.

| 키 (`AssetIds`) | 파일 | 사용처 |
|---|---|---|
| `SNAKE_BEAD` | snakes/body_segment_blue.png | 모든 뱀의 머리·몸통·꼬리 (셰이더로 색 변경) |
| `FOOD_RED/PURPLE/CYAN/GREEN` | food/food_*.png | 일반 먹이 (1 XP), 사체 먹이 |
| `FOOD_MEDIUM_GOLD` | food/food_medium_gold.png | 중형 먹이 (3 XP), Amber/Gold 스킨 사체 |
| `FOOD_LARGE_GOLD` | food/food_large_gold.png | 대형 먹이 (8 XP) |
| `FOOD_RARE` | food/food_rare_orange.png | 희귀 먹이 (25 XP, 오라) |
| `GEM_BLUE/PURPLE/GREEN` | food/gem_*.png | 특수 보석 (60 XP, 오라) |
| `FOOD_SMALL_GOLD` | food/food_small_gold.png | 텍스처 누락 시 대체용 |
| `VFX_RARE_AURA` | vfx/rare_food_aura.png | 희귀/보석 밑 은은한 오라 |
| `VFX_LEVELUP_GOLD` | vfx/levelup_ring_gold.png | 플레이어 레벨업 링 (머리 추적) |
| `VFX_IMPACT_GOLD` | vfx/impact_burst_gold.png | 처치 순간 충돌 지점 |
| `VFX_DEATH_SMOKE` | vfx/death_smoke.png | 사망 |
| `VFX_RESPAWN_PORTAL` | vfx/respawn_portal.png | 부활 (머리 추적) |
| `VFX_BOSS_BURST` | vfx/boss_burst_red.png | 보스 처치 |
| `VFX_SPARKLE_WHITE` | vfx/sparkle_white.png | 희귀/보석 획득 |
| `VFX_SPARKLE_CYAN` | vfx/sparkle_cyan.png | 동레벨 정면 충돌(튕김) |
| `ARENA_FLOOR` | arena_tiles/arena_01_dots.png | 경기장 바닥 (2× 스케일 반복) |
| `ARENA_FLOOR_HEX` | arena_tiles/arena_02_hex.png | 대체 바닥 (`ArenaConfig.floor_texture_key`로 교체 가능) |
| `ICON_CLOCK/HEART/SKULL/CROWN` | ui_icons/*.png | 타이머, 부활, 보스, 1위 표시 |

정적 VFX 이미지는 프레임 애니메이션으로 위장하지 않고, 크기·투명도·회전 곡선(`VfxLayer.DEFS`)으로만 움직입니다.

## 3. 사용하지 않은 리소스와 사유 (규칙 27-1, 27-4)

| 리소스 | 판정 | 사유 |
|---|---|---|
| `player_head_blue`, `enemy_head_*`, `boss_head_red` | **반려** | 정면을 보는 이모지형 얼굴(눈+입)이라 탑다운 회전 시 얼굴이 옆·거꾸로 돌아가고 시선을 진행 방향과 맞출 수 없음. 대안: 같은 구슬 + 진행 방향을 보는 절차적 눈 (`SnakeFaceRenderer`) |
| `tail_tip_blue`, `boss_tail_red_gold` | **반려** | 수정(크리스털) 조각 형태라 둥근 구슬 몸통과 재질·형태가 다름. 대안: 같은 구슬을 꼬리 쪽으로 점점 작게 (`SnakeBody` taper) |
| `boss_horn` | **반려** | 밑동에 베이지색 타원 잔여물이 그려져 있음 (생성 오류). 대안: 같은 외곽선·광원 규칙으로 그린 절차적 뿔 (`SnakeCrestRenderer`) |
| `boss_segment_red_gold` | **반려** | 모든 마디마다 뿔+금색 고리가 붙어 반복 시 지저분함. 대안: 구슬 3개마다 금색 띠 (`SnakeSkin.band_every`) |
| `body_segment_cyan/gold/green/pink/purple` | 미사용 | 품질 문제는 없음. 단일 원본 + 셰이더 색 변경이 재질 일관성과 확장성(새 스킨 = .tres 1개)에서 우월 |
| `boss_aura_red` | **반려(적용 후 교체)** | 실제 화면에서 단단한 테두리와 하이라이트 호가 장식 고리처럼 보임. 대안: 절차적 방사형 글로우 |
| `levelup_ring_blue` | 미사용 | 경쟁자 레벨업 연출을 빼서 화면 소음을 줄임 |
| `food_rainbow` | **반려** | 흰 외곽선 등 다른 오브젝트와 그림체가 다름 |
| `food_glow_*` | 미사용 | 일반 먹이에 발광은 과함 (27-7) |
| `star_gold` | 미사용 | 먹이 종류 과다. 보석 3종으로 충분 |
| `heal_glow_green`, `speed_streak_*` | 미사용 | 대응하는 게임 기능 없음 (회복/부스트 없음) |
| `death_skull_glow` | 미사용 | 연기만으로 사망이 충분히 전달됨, 해골 아이콘은 UI 전용 |
| `arena_08_blue_glow` | **반려** | X자 모아레 패턴 아티팩트 |
| `arena_05_center_glow` | **반려** | 아틀라스와 개별 파일 불일치 + 경기장에 어울리지 않는 흰 원 |
| `arena_03_grid`, `arena_06/07/09/10/11`, `arena_13~16` | 미사용 | 격자/경고 줄무늬는 과함, 경계는 절차적 드로잉이 더 깔끔, 13~16은 중복 |
| `magnet` | **반려** | 자석 형태가 잘려 'U' 조각만 남음 |
| `trophy`, `boss`(아이콘) | **반려** | 형태가 어색함 (사각 트로피, 얼굴 달린 별) |
| `play`, `pause`, `home`, `gear`, `shield`, `lightning`, `coin`, `gem`(UI), `star`(UI) | 미사용 | 버튼은 텍스트 + Theme로 구성. 아이콘 남용 방지 |

> 아틀라스 파일은 복사하지 않았습니다. 개별 PNG가 모두 정상이므로 개별 PNG만 쓰고, 같은 이미지를 두 번 메모리에 올리지 않도록 했습니다.
