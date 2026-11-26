# TEST RESULTS

환경: Windows 11 Pro, Godot **4.7.2.stable.official** (`Godot_v4.7.2-stable_win64_console.exe`), GL Compatibility, VS Code 1.146.
최종 실행일: 2026-11-25

## 1. 엔진 검사
| 명령 | 결과 |
|---|---|
| `--version` | `4.7.2.stable.official.ed1daf0bf` |
| `--headless --path . --import` | 오류 0 (스크립트 파싱·클래스 등록·리소스 임포트) |
| `--headless --path . --quit-after 300` | 메인 메뉴 + 어트랙트 경기 300프레임, 오류 0, 종료 코드 0 |

## 2. 자동 테스트 (`tests/run_tests.gd`)
**47개 테스트 / 305개 검사 전부 통과.** (5차: 벽 규칙·보스 무시 표시 정리 후)

| 구분 | 테스트 | 검증 내용 |
|---|---|---|
| 단위 | level_curve_monotonic_and_invertible | 누적 XP 단조 증가, 레벨↔XP 역변환 (Lv1~99,999) |
| | required_xp_matches_formula | 공식 일치 |
| | max_level_clamp_and_no_overflow | int64 근처 XP → Lv99,999에서 정지 |
| | multi_level_gain_emits_once_with_full_jump | 한 번에 39레벨 상승, 시그널 1회 |
| | xp_penalty_keeps_ratio | 부활 페널티 60%, 최고 레벨 보존 |
| | level_cap_clamps_growth | AI 레벨 상한 (add_xp, set_level 모두) |
| | path_samples_are_evenly_spaced_on_a_line | 구슬 간격 정확 (±0.01px) |
| | path_follows_a_corner | 꺾인 궤적에서 정확한 위치 |
| | path_memory_is_bounded | 5만 스텝 후 점 수 < 300, 필요한 길이는 유지 |
| | path_extrapolates_instead_of_stacking | 기록이 짧을 때 직선 연장 (구슬 쌓임 없음) |
| | body_count_capped_but_length_preserved | Lv99,999: 140구슬, 시각 길이 = 논리 길이, 구슬 겹침 유지 |
| | spatial_hash_query_and_remove | 질의·삭제 |
| | score_formula | 점수 가중치 |
| | game_state_machine_guards | 불법 전이 거부 |
| | save_roundtrip_and_versioning | 저장/로드, 스키마 버전 기록 |
| | arena_clamp_slides | 경계 고정 + 바깥 방향 제거 |
| | food_xp_scales_with_level | 먹이 1개 = 크기와 무관하게 비슷한 레벨 비율 |
| | bite_fraction_grows_with_gap | 물기 비율 공식, 머리 물기 상한 80%, 덩어리 크기 증가·상한 |
| | level_for_length_inverts_full_length | 길이 ↔ 레벨 역변환 |
| | size_gap_is_dramatic | Lv1,000이 Lv10보다 3배 이상 넓고, 훨씬 느리게 선회 |
| 통합 | match_simulates_without_errors | 15초 시뮬레이션, 12마리, 먹이 유지, AI 상태 3종 이상, 타이머 |
| | high_level_stress_stays_bounded | 플레이어 Lv99,999 + AI Lv800: 구슬 상한·경로 메모리 |
| | small_head_into_big_body_slides_off | 약한 머리 → 큰 몸통: 피해 없음, 밀려남 |
| | bigger_mouth_bites_a_chunk_that_becomes_food | 몸통 타격 = 닿은 지점의 덩어리, 레벨 = 남은 길이에 맞는 레벨, 덩어리 먹이 생성, 연쇄 타격 없음 |
| | cut_short_snake_is_really_weaker | 크게 잘린 Lv400 뱀을 온전한 Lv150이 이김 (크기 = 힘) |
| | shielded_target_reports_block | 보호 중인 대상은 안 잘리고 막힘이 보고됨 (UI "SHIELD") |
| | zone_phases_shrink_inside_each_other | 다음 원이 현재 원 안, 1단계 축소 목표 반지름 도달, 2단계 공개 |
| | zone_erosion_burns_snakes_outside | 구역 밖에서 길이·레벨 감소, 끝까지 버티면 사망 |
| | spawns_land_inside_the_next_zone | 부활/생성 지점이 다음 원 안 |
| | boss_weak_spot_only_in_showdown | 정규 시간에는 약한 플레이어가 보스를 못 자름, 쇼다운에는 금색 꼬리 절단 가능 |
| | mouth_only_strikes_in_front | 머리 뒤쪽 접촉은 공격이 아님 |
| | head_bite_scales_with_gap | 머리 물기 = HEAD_BITE, 1.2배 차이 → 적당한 손실 |
| | neck_strike_swallows | 목(앞 15%) 타격 = 삼킴, 보상, 킬 수 |
| | strike_cooldown_makes_lower_body_a_wall | 재공격 대기 중 낮은 레벨 몸통에 닿으면 통과하지 않고 미끄러짐 |
| | calm_boss_notice_level | 정규 시간 보스: Lv399 무시, Lv400부터 공격, 분노 시 전부 공격 |
| | equal_levels_bounce | 같은 레벨 정면 충돌: 피해 없음, 양쪽 보호 |
| | player_revives_then_eliminated | 부활 3회 소모 후 4번째 사망 → ELIMINATED 1회 |
| | boss_kill_is_victory | 보스 목 타격 → 삼킴 → VICTORY |
| | boss_fight_takes_several_strikes | 보스 몸통을 2회 이상 자른 뒤 처치 |
| | boss_body_is_safe_but_its_jaws_are_not | 보스 몸통 충돌은 안전, 평상시 보스는 피라미 무시, 분노한 보스의 입은 작은 플레이어를 삼킴 |
| | rivals_cannot_bite_the_boss | 경쟁자는 약해진 보스에게서도 미끄러지기만 함 |
| | boss_stays_apex | AI 레벨 상한, 보스 레벨 고정, AI가 보스를 잡아도 경기 미종료 |
| | time_up_starts_showdown_not_game_over | 0:00 → SHOWDOWN (경기 계속), 경쟁자 분해, 보스 분노, 최종 자기장 축소 |
| | showdown_timeout_ends_match | 쇼다운 시간 종료 → TIME_UP ("THE TYRANT ENDURES") |
| | screen_flow_menu_game_restart_menu | 실제 Main: 메뉴 → 게임 → 재시작 ×2 → 일시정지 → 메뉴, 일시정지 해제, 이전 화면 해제 확인 |

성능 (테스트 중 측정): 일반 1스텝 **2.0ms**, Lv99,999 스트레스 **3.6ms** (Lv99,999 플레이어: 반지름 61.6, 길이 10,133px, 구슬 140, 경로 점 374).

**알려진 경고:** 테스트 러너 종료 시 `6 ObjectDB instances were leaked`. `--verbose`로 확인하면 재생 중이던 `AudioStreamWAV/PlaybackWAV`가 헤드리스 더미 오디오 드라이버에 붙잡혀 있는 것이다. 게임플레이 객체 누수가 아니며, 종료 시 보이스를 정지하는 처리를 넣었지만 경고는 남는다.

## 3. 실제 화면 시각 검수 (`tests/scenes/visual_capture.gd`, 창 모드 1280×720)
플레이어는 AI 오토파일럿으로 움직인다. 최종 스크린샷은 `.captures/`에 있다.

| # | 화면 | FPS | 검수 결과 |
|---|---|---:|---|
| 01 | 메인 메뉴 | 73* | 어트랙트 경기 배경, 좌측 음영 위 타이틀·버튼 가독성 양호, 최고 기록 표시 |
| 02 | 일반 플레이 | 120 | 머리·몸통 재질 동일, 눈이 진행 방향을 봄, 꼬리 테이퍼 정상, HUD 4코너 배치 |
| 03 | 근접(2.6×) | 120 | 구슬 외곽·하이라이트 선명, 먹이 선명. 레벨업 링 텍스처는 2.6× 확대에서 계단 현상 (실게임 최대 줌 1.4×에서는 문제 없음) |
| 04 | 다수 AI | 114 | 10마리 밀집에도 색·레벨 색상으로 구분 가능 |
| 05 | 레벨업 | 114 | 링이 머리를 따라감, 레벨 숫자 펄스 |
| 05b | 물림 (2차) | 121 | "Viper bit you -35%" 빨간 피드, 레벨 하락, 붉은 틴트, 물린 지점 버스트, 가장자리 비네트(과하지 않게 조정), 위협 링 |
| 06 | 고레벨(Lv852) | 105 | 줌아웃, 긴 몸 연결 자연스러움, 보스 띠·뿔·글로우 식별 |
| 07 | 보스 근접 | 102 | 보스가 최상위 위협으로 읽힘, 이름표 겹침 해소 |
| 08 | 사망 | 102 | 연기, 희생자 색 먹이 분해, 빨간 킬 피드, REVIVING |
| 08b | 부활 | 114 | 포털 링, 반투명 깜박임, PROTECTED, 부활 횟수 감소 |
| 09/10 | 스킨/설정 | 99/83* | 실제 셰이더 미리보기, 잠금 상태, 슬라이더·토글 |
| 11 | 일시정지 | 114 | 중앙 패널, 배경 딤 |
| 12 | 결과 | 120 | 중앙 패널, 결과 제목 색, 6개 지표, RETRY/MAIN MENU |
| 02a | 경기 시작 (3차) | 100 | 키캡 스타일 조작 안내 카드 6초 표시 |
| 06 | 고레벨 (3차) | 95 | Lv866 플레이어 옆 Lv20 뱀이 실처럼 보임 (크기 격차) |
| 10b | HOW TO PLAY (3차) | 114 | 조작 + 규칙 5줄, 화면 안에 맞춤 |
| 13 | 쇼다운 (4차) | 118 | 빨간 SHOWDOWN 시계, "ZONE CLOSING", 보스 카드 "DODGE THE JAWS, CUT ITS GOLD TAIL", 분해된 경쟁자 |
| 05b | 물림 (4차) | 95 | "CUT −76%"(금색)·"−51%"(빨강) 숫자, 보호막 거품, 초록/빨강 레벨 색 |
| 05c | 구역 밖 (4차) | 80 | 푸른 장막, 경계선, 다음 원 점선(화면 기준 점선), "RETURN TO THE ZONE", 미니맵 |
| 11 | 일시정지 (3차) | 117 | 조작 안내 포함 |

\* 메뉴 FPS는 씬 로딩 직후 1초 평균이라 낮게 나온다.

**시각 검수로 발견해 수정한 문제:**
1. 뱀이 거의 검게 렌더링됨: 셰이더가 `COLOR`(텍스처와 곱해진 값)를 채널로 오해함 → `vertex()` varying으로 수정
2. 급성장 시 꼬리 끝이 뭉툭하게 쌓임 → 목표 길이 기준 트림 + 꼬리 외삽
3. 결과/일시정지 패널이 좌상단에 붙음: 전환 트윈이 컨테이너 배치 전 위치로 고정 → 위치를 건드리지 않는 페이드+스케일로 교체
4. 보스 오라가 장식 고리처럼 보임 → 절차적 방사형 글로우로 교체
5. 킬 피드와 보스 방향 표시 겹침 → 킬 피드를 좌상단 패널 아래로 이동
6. 이름표 겹침 → 우선순위 기반 쌓기
7. 레벨업 링이 제자리에 남음 → 머리 추적
8. 2D MSAA가 GL Compatibility에서 오류 → 설정 제거
9. 실행 중 공간 인덱스 범위 초과(오래된 핸들) → 인덱스에서 거부

## 4. 밸런스 프로브 (`tests/balance_probe.gd`, 90초 경기, Hunter 오토파일럿)

### 4차 (자기장 + 단일 타격 규칙 + 크기=힘, 최종)
레벨이 남은 길이를 따라가게 하자 한 번의 타격이 결정적이 되었다. 그래서 다음 순서로 조정했다 (10경기 기준).
| 단계 | 결과 | 원인 분석 |
|---|---|---|
| 자기장 + 길이 기반 레벨 + 접촉점 뒤 전부 절단 | 0/8 승리 | 몸 중간 절단 = −80% 레벨, 연쇄 사망 |
| 탈출 가속·보호 1.5초, 보스가 피라미 무시, AI 먹잇감 기준 강화 | 0~1/8 | 손실 원인 계측: 대부분 공격, 자기장 손실은 미미 |
| 부활 바닥(경기 최고의 40%), 보스 약점(금색 꼬리) | 1~5/8 | 정규 시간에 약점을 노려 32초 승리 → 약점은 쇼다운 전용으로 |
| **덩어리 물어뜯기(닿은 지점에서 일부만), 보스 어그로 700px·대상 40%+, 머리 물기 상한 80%** | **VICTORY 3 / ENDURES 2 / 탈락 5** | 탈락 대부분은 쇼다운의 분노한 보스 |

### 3차 (절단 전투 + 쇼다운, 최종)
| 단계 | 결과 |
|---|---|
| 절단 XP를 "남은 길이에 맞는 레벨"로 계산 | 몸 중간 절단 −80%, 목 근처 −97%로 지나치게 가혹함 (화면 검수에서 발견) |
| **절단 XP를 잘린 비율에 선형으로 (최종)** | **8경기 중 VICTORY 5 (100~130초, 대부분 쇼다운 중)**, THE TYRANT ENDURES 2 (1경기는 보스를 Lv225까지 깎음), 탈락 1 |

### 1차 (충돌 = 사망 규칙)
| 튜닝 단계 | 결과 |
|---|---|
| 초기값 | 5/5 탈락 (27~47초), 최고 Lv103. 사망 절반이 보스 |
| AI 성장↓, 보스 영역형·저속·단신 | 1/6 승리. 나머지는 부활 소진, 사망 원인 대부분 "도망치다 몸통 충돌" |

### 2차 (물기/미끄러짐 규칙, 최종)
| 튜닝 단계 | 결과 |
|---|---|
| 규칙 개편 직후 (3배 차이 삼킴) | 0/6 승리. 보스가 작은 뱀을 잡아먹어 사망 |
| 보스가 피라미 무시 (25% 미만 레벨 무시) | 0/8. 경쟁자에게 삼켜짐 (3~5배 차이) |
| 삼킴 기준 약 6배, 큰 뱀 속도 지수 0.72 → 0.4 | **8경기 중 6경기 시간 종료까지 생존**, 사망 0~2회. 성장은 느림 |
| 물기 획득 75%, 삼킴 보상 0.8, 먹이 가치 ×2 + 레벨 비례 | 생존 유지, 최고 Lv1,003 |
| **레벨 곡선 지수 0.35 → 0.25 (최종)** | **보스 처치 1/8** (60초 Lv1,002 → 81초 승리, 0사망), Lv1,845 1경기, 나머지 대부분 생존 |

최종 8경기:
```
match 1:  … 75s Lv975   90s Lv1845 | TIME UP,  kills 6, deaths 0, rank #1
match 2:  15s Lv23 … | ELIMINATED at 54s, deaths 4
match 3:  … 90s Lv60   | TIME UP, deaths 1
match 4:  … 90s Lv39   | TIME UP, deaths 3
match 5:  … 90s Lv105  | TIME UP, peak Lv473, deaths 2
match 6:  … 90s Lv12   | TIME UP, peak Lv311, deaths 1
match 7:  … 90s Lv851  | TIME UP, deaths 1, rank #4
match 8:  … 60s Lv1002 75s Lv1812 | VICTORY at 81s, peak Lv2162, kills 7, deaths 0
```
해석: 충돌 사망이 없어져 탈락이 크게 줄었다. 성장의 편차가 커서(물기 손실), 잘 풀린 경기는 보스까지 가고 그렇지 않은 경기는 중위권으로 끝난다. 오토파일럿은 보스를 일부러 찾아가지 않으므로, 사람이 하면 보스 도전 빈도는 더 높을 것으로 예상한다. 사람 플레이로 최종 확인이 필요하다.

## 5. 수동 검증이 필요한 항목 (자동화하지 못함)
- 실제 마우스/키보드 조작감 (오토파일럿과 헤드리스 입력으로는 검증 불가)
- 효과음 체감 볼륨·음색 (헤드리스 더미 오디오)
- 전체화면 토글, 1280×720 이외 해상도/비율
- 수십 회 이상 장시간 반복 재시작 시 메모리 추이 (자동 테스트는 3회 재시작까지 확인)
