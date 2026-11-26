# SERPENT ARENA — Godot용 게임 리소스

모든 아틀라스는 정확한 셀 크기로 정렬된 PNG RGBA 파일입니다. 개별 PNG도 함께 제공됩니다.

## 파일
- `atlases/snake_parts_256.png` — 4x4, 셀 256x256, 뱀 머리/몸통/꼬리/보스 파츠
- `atlases/food_orbs_128.png` — 4x4, 셀 128x128, 먹이/보석
- `atlases/vfx_256.png` — 4x4, 셀 256x256, 성장/충돌/부활/보스 이펙트
- `atlases/arena_tiles_128.png` — 4x4, 셀 128x128, 어두운 경기장 바닥 타일
- `atlases/ui_icons_128.png` — 4x4, 셀 128x128, HUD 아이콘
- `atlas_manifest.json` — 모든 셀의 정확한 좌표와 개별 파일명

## Godot 4 사용법
1. `SERPENT_ARENA_ASSETS` 폴더의 내용을 프로젝트 `res://assets/` 안에 복사합니다.
2. `Sprite2D`에서 `Texture`에 해당 atlas PNG를 지정합니다.
3. `Sprite2D.region_enabled = true`로 설정하고 `region_rect`를 manifest의 x/y/w/h 값으로 지정합니다.
4. 더 편한 방식은 개별 PNG를 `Sprite2D.texture`로 바로 사용하는 것입니다.
5. 몸통은 `body_segment_blue.png`를 경로 포인트마다 반복 배치하고, 각 세그먼트에 회전/크기 변화를 적용합니다.
6. 스킨 변경은 `CanvasItem.modulate` 또는 셰이더를 사용하면 추가 시트 없이 색상을 바꿀 수 있습니다.

## 권장 import
- 캐릭터/먹이/UI/VFX: Filter = On, Mipmaps = Off, Compression = Lossless
- 경기장 타일: Filter = Off 또는 프로젝트 픽셀 밀도에 맞춰 선택, Repeat = Enabled
- 모든 리소스는 원본 투명 PNG(RGBA)입니다.

## 참고
이 세트는 게임의 현재 기획(탑다운 뱀 아레나)에 필요한 기본 파츠 중심입니다. 실제 게임에서 뱀의 곡선 몸통은 단일 긴 그림이 아니라 `body_segment` 반복 또는 커스텀 메시/드로잉으로 구성해야 합니다.
