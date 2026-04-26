# Map & Gameplay Redesign Plan: Planetfall Assault

## Ý tưởng chính

Lấy cảm hứng từ cảm giác triển khai của `Helldivers 1`: người chơi không bị ép bắt đầu cố định ở một góc map, mà được chọn điểm thả quân trên bản đồ chiến dịch. Map có nhiều căn cứ địch, mục tiêu phụ, điểm gọi tiếp viện, và một mục tiêu lớn như `Ork Warboss`. Trọng tâm là lập kế hoạch đổ bộ, đánh mục tiêu, giữ vị trí, rồi rút hoặc gọi thêm quân.

## Mục tiêu cải tiến

| Hạng mục | Hiện tại | Cải tiến đề xuất | Lợi ích |
|---|---|---|---|
| Điểm bắt đầu | Marine spawn cố định ở một cạnh map | Người chơi chọn `Drop Zone` trước khi vào trận | Tăng cảm giác chỉ huy và lựa chọn chiến thuật |
| Map | Grid khá đều, dễ giống bàn cờ | Map chia thành vùng: landing zone, patrol zone, ork base, warboss arena, extraction | Dễ đọc mục tiêu và tạo nhịp chơi |
| Enemy base | Chưa phải trung tâm gameplay | Thêm `Ork Outpost`, `Spore Beacon`, `Ammo Dump`, `Warboss Camp` | Map có mục tiêu rõ, không chỉ bắn từng enemy |
| Warboss | Chưa có vai trò boss rõ | Warboss là mục tiêu lớn, có guard, aura, gọi wave | Tạo cao trào cuối màn |
| Reserve | Gọi reserve từ spawn/drop beacon | Gọi reserve/drop pod xuống vùng hợp lệ gần beacon/flared zone | Giống cảm giác reinforcement của Helldivers |
| Objective | Survive/kill đơn giản | Nhiều objective đồng thời: destroy base, kill boss, extract, recover intel | Tăng độ đấu trí |
| UI map | Hiển thị chiến trường trực tiếp | Trước trận có `Planetfall Map` để chọn drop zone và xem threat | Người chơi hiểu kế hoạch trước khi bấm deploy |

## Core Loop mới

| Bước | Tên phase | Người chơi làm gì | Hệ thống phản hồi |
|---:|---|---|---|
| 1 | Mission Brief | Đọc nhiệm vụ, xem ảnh commander, xem mục tiêu chính/phụ | Hiển thị warboss/base/intel threat |
| 2 | Drop Planning | Chọn điểm thả quân trên tactical map | Vùng hợp lệ sáng xanh, vùng nguy hiểm cảnh báo đỏ |
| 3 | Planetfall | 4 marine đầu đổ bộ xuống điểm đã chọn | Drop pod impact gây sát thương nhỏ xung quanh |
| 4 | Assault | Squad tiến tới căn cứ địch, phá beacon/base | Enemy tuần tra, gọi wave nếu bị báo động |
| 5 | Escalation | Warboss hoặc Nob squad phản công | Threat tăng, reinforcement cần CP/beacon |
| 6 | Extraction | Hoàn thành mục tiêu rồi tới extraction/drop zone | Kết thúc mission, thưởng RP |

## Thiết kế map mới

| Vùng map | Mục đích | Tile/Asset cần có | Gameplay |
|---|---|---|---|
| Drop Zone | Nơi người chơi chọn đổ bộ | Landing scorch, smoke, drop pod marker | An toàn vừa phải, có thể bị patrol phát hiện |
| Patrol Routes | Đường tuần tra địch | Ork patrol markers, scrap barricade | Nếu bắn hoặc bị phát hiện, enemy base tăng alert |
| Ork Outpost | Căn cứ nhỏ | Barricade, turret, ammo pile, ork banner | Phá để giảm wave hoặc lấy RP |
| Spore/Comms Beacon | Điểm gọi viện địch | Antenna, green flare, crude generator | Nếu không phá, mỗi vài round spawn thêm enemy |
| Warboss Camp | Boss arena | Big scrap gate, trophy pile, warboss asset | Warboss có aura, guard, charge attack |
| Extraction Zone | Điểm rút lui | Beacon, smoke flare, landing pad | Sau objective chính mới active |
| Optional Relic/Intel | Mục tiêu phụ | Crate, cogitator, fallen clue | Cho RP/CP/lore unlock |

## Drop Zone System

| Rule | Mô tả |
|---|---|
| Chọn drop trước mission | Người chơi click một ô/vùng hợp lệ trên overview map |
| Không drop vào căn cứ chính | Vùng quá gần Warboss Camp hoặc enemy base bị khóa |
| Drop gần enemy có rủi ro | Nếu chọn gần patrol/base, bắt đầu mission với enemy alert cao |
| Drop pod impact | Khi spawn, gây damage/knockback trong bán kính 1 ô |
| Drop pod là cover | Pod sau khi rơi trở thành block/cover trong map |
| Reserve cần beacon | Reserve chỉ thả xuống gần drop pod gốc hoặc beacon do Commander/Techmarine đặt |

## Ork Base System

| Base type | Chức năng | Nếu bị phá | Nếu bỏ qua |
|---|---|---|---|
| Boyz Camp | Spawn Ork Boy mỗi vài round | Giảm số wave | Wave đông hơn |
| Loota Nest | Bắn xa, cover fire | Giảm ranged pressure | Marine bị pin ở lane mở |
| Nob Barracks | Spawn Nob/elite | Giảm elite spawn | Nob xuất hiện trong boss fight |
| Scrap Turret | Vùng bắn cố định | Mở đường an toàn | Ép player flank |
| Warboss Banner | Buff ork quanh đó | Warboss yếu hơn | Warboss có aura mạnh |

## Ork Warboss Design

| Thuộc tính | Đề xuất |
|---|---|
| Vai trò | Boss cuối mission hoặc roaming commander |
| HP | Cao gấp 3-4 lần Nob |
| Armor | Giảm damage từ bolter thường |
| Weakness | Plasma, melee power weapon, bomb, flamer vs guard |
| Aura | Ork gần Warboss tăng damage/melee |
| Skill 1 | `Waaagh!` gọi thêm Boyz nếu HP còn 70%/40% |
| Skill 2 | `Charge` lao 2-3 ô tới marine gần nhất |
| Skill 3 | `Brutal Cleave` melee AoE nhỏ |
| Counterplay | Phá banner/base trước, dùng cover, kite qua choke point |

## Mission Flow mẫu

| Giai đoạn | Nội dung | Kết quả mong muốn |
|---|---|---|
| Briefing | Commander báo tin Warboss đang chỉ huy cuộc nổi dậy | Người chơi hiểu mục tiêu chính |
| Drop Planning | Chọn 1 trong nhiều vùng thả quân | Có lựa chọn: an toàn xa mục tiêu hoặc nguy hiểm gần base |
| Initial Landing | 4 marine + drop pod rơi xuống | Tạo cover ban đầu |
| Recon | Di chuyển tới outpost gần nhất | Người chơi học patrol/base |
| Sabotage | Plant bomb tại spore beacon hoặc ammo dump | Mở đường giảm wave |
| Reinforce | Đặt beacon và gọi thêm marine | Squad đủ lực đánh boss |
| Boss Assault | Tấn công Warboss Camp | Cao trào combat |
| Extract | Rút về extraction zone | Mission complete |

## UI cần cải tiến theo cơ chế mới

| UI | Thay đổi | Ghi chú |
|---|---|---|
| Mission Select | Thêm preview map nhỏ với các drop zone | Click mission chưa vào game ngay |
| Drop Planning Screen | Cho chọn điểm thả quân | Hiển thị threat radius |
| Tactical Map | Drop pod marker, base icon, warboss icon rõ | Ưu tiên readability |
| Objective Bar | Hiển thị base còn lại, warboss status, extraction | Dễ biết cần làm gì |
| Right Panel | Enemy alert, bases active, reserve status | Giống command sidebar |
| Command Card | Thêm `Call Drop`, `Plant Bomb`, `Deploy Beacon` rõ cost | AP/CP nếu chuyển sang AP system |

## Data Model cần thêm/sửa

| Model | Field mới | Mục đích |
|---|---|---|
| `TacticalMap` | `dropZones` | Các vùng có thể chọn trước mission |
| `TacticalMap` | `enemyBases` | Danh sách căn cứ địch |
| `TacticalMap` | `bossSpawn` | Vị trí Warboss |
| `GameState` | `selectedDropZone` | Điểm đổ bộ đã chọn |
| `GameState` | `enemyAlertLevel` | Mức báo động |
| `GameState` | `activeBases` | Base chưa bị phá |
| `EnemyUnit` | `isBoss`, `abilities` | Hỗ trợ Warboss |
| `MissionObjective` | `killBoss`, `destroyBases`, `extract` | Objective mới |

## Implementation Plan

| Phase | Việc làm | File/khu vực liên quan | Kết quả |
|---:|---|---|---|
| 1 | Thêm `dropZones` vào map data | `tactical_map.dart` | Map biết vùng thả quân hợp lệ |
| 2 | Tạo màn `DropPlanningScreen` | `screens/` | Người chơi chọn điểm thả trước trận |
| 3 | Start squad tại selected drop zone | `game_state_provider.dart` | Marine không còn spawn cố định |
| 4 | Drop pod impact + cover tile | `game_state_provider.dart`, Flame components | Drop pod thành cover/block |
| 5 | Thêm enemy base model | `models/`, `providers/` | Base có HP/state/spawn behavior |
| 6 | Thêm Warboss enemy kind | `enemy_unit.dart`, component asset | Boss xuất hiện đúng asset mới |
| 7 | Update objective system | `MissionObjective`, `_refreshObjectives` | Destroy bases/kill boss/extract |
| 8 | UI icon/base/warboss overlay | `grid_overlay_component.dart`, `command_screen.dart` | Map đọc dễ hơn |
| 9 | Balance mission 1 | `campaignMaps` | Một màn chơi giống planetfall assault |

## Asset cần dùng

| Asset | Cách dùng |
|---|---|
| Ork Warboss image | Boss unit sprite/component |
| Ork Boy/Nob/Loota images | Enemy variety |
| Ork base/outpost images | Objective structures |
| Drop pod image | Spawn cover + reinforcement marker |
| Smoke/flare image | Drop zone/extraction visual |
| Explosion image | Bomb/drop pod impact |

## Quyết định đề xuất

Nên làm trước một vertical slice:

| Ưu tiên | Feature | Lý do |
|---:|---|---|
| 1 | Chọn drop zone trước mission | Thay đổi cảm giác chơi mạnh nhất |
| 2 | Ork base có spawn wave | Làm map có mục tiêu rõ |
| 3 | Warboss boss fight | Tận dụng asset mới và tạo cao trào |
| 4 | Extraction sau objective | Mission có kết thúc chiến thuật |
| 5 | AP/Squad Turn system | Kết hợp sau để giảm bất tiện lượt |

Khi xong, mission sẽ có cảm giác: `chọn điểm đáp -> phá căn cứ -> gọi viện -> săn Warboss -> rút quân`, thay vì chỉ đi từng ô và bắn địch rải rác.
