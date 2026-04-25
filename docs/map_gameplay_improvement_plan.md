# Dark Angels - Map, Animation, and Tactical Depth Improvement Plan

## Mục tiêu

Biến bản prototype hiện tại thành một màn chơi chiến thuật hấp dẫn hơn, rõ map hơn, có animation/audio phản hồi tốt hơn, và không còn lỗi nhân vật đi xuyên qua các vùng nhìn trên ảnh là vực, dưới cầu, máy móc, ống dẫn hoặc nền không thể đi.

Hướng kỹ thuật mới: bỏ Tiled/TMX trong giai đoạn này. Game sẽ dùng trực tiếp các ảnh asset hiện có làm background map, còn luật di chuyển, cover, spawn, objective và vùng cấm đi sẽ được định nghĩa bằng dữ liệu grid riêng trong code/JSON.

## Vấn đề hiện tại

1. Map không hiển thị ổn định và nhìn không rõ.
   - Asset map hiện là ảnh `1024x1024`.
   - Prototype trước đang dùng map logic `24x16` với tile `64px`, tức world size `1536x1024`.
   - Khi ảnh `1024x1024` bị kéo thành `1536x1024`, map bị méo ngang, grid không khớp chi tiết ảnh, cover nhìn như đặt lệch khỏi map.

2. Grid đang quá đơn giản.
   - Hiện logic chủ yếu chỉ chặn bằng cover/block thủ công.
   - Các vùng nhìn như vực, dưới cầu, máy móc, mép platform, ống dẫn, hố kỹ thuật vẫn có thể bị coi là ô đi được.
   - Kết quả là marine có thể đi vào nơi visual nói rằng không thể đi.

3. Cover chưa thuộc về map.
   - Cover đang là object đặt lên grid nhưng không được kiểm tra chặt với nền ảnh.
   - Cần cover nằm trên những tile hợp lý: cạnh tường, crate, barricade, console, pillar, machinery.

4. Animation và audio chưa đủ tạo cảm giác game.
   - Unit có các ảnh idle/walk/attack/dead nhưng cần thêm nhịp animation rõ hơn.
   - Di chuyển cần có chuyển động mượt, âm thanh bước chân, bụi/tia lửa nhỏ.
   - Bắn cần muzzle flash, projectile/tracer, hit flash, damage text, âm thanh vũ khí.

5. Mission chưa đủ chiều sâu để chơi khoảng 30 phút.
   - Một map chỉ có move/attack cơ bản sẽ nhanh chán.
   - Cần objective theo pha, pressure từ enemy, fog/line of sight, lựa chọn chiến thuật, CP skill, reinforcements và extraction.

## Quyết định thiết kế kỹ thuật

### 1. Bỏ Tiled trong vertical slice

Không dùng `.tmx` hoặc `flame_tiled` cho bản tiếp theo. Lý do:

- Người làm game chưa cần học thêm quy trình thiết kế Tiled.
- Asset hiện có là ảnh nền lớn, phù hợp với cách làm image-backed tactical map.
- Dữ liệu chiến thuật có thể được định nghĩa bằng code/JSON dễ đọc hơn.

Sau này nếu có artist hoặc map pipeline ổn định, có thể quay lại Tiled. Hiện tại ưu tiên game chạy tốt, map rõ, và luật grid đúng.

### 2. Dùng native map size

Các ảnh map hiện có:

- `assets/images/map.png`
- `assets/images/map_hive_city.png`
- `assets/images/map_ash_wastes.png`

Tất cả đang là `1024x1024`, nên map logic nên chuyển về:

- `gridColumns: 16`
- `gridRows: 16`
- `tileSize: 64`
- `worldSize: 1024x1024`

Không stretch map thành `1536x1024` nữa. Nếu sau này muốn map rộng `24x16`, cần tạo/generate ảnh nền thật sự có size `1536x1024`.

## Map Data Mới

Thêm một lớp dữ liệu chiến thuật cho mỗi map, ví dụ `TacticalMapMask`.

Mỗi tile có thể có các rule:

- `walkable`: đi được.
- `blocked`: không đi được vì tường, máy móc, container lớn.
- `void`: vực, dưới cầu, hố kỹ thuật, vùng không có sàn.
- `bridge`: đi được nhưng chỉ nếu tile là mặt cầu/platform trên cùng.
- `coverLow`: cover nhẹ, giảm sát thương vừa.
- `coverHigh`: cover mạnh, giảm sát thương nhiều.
- `hazard`: vùng nguy hiểm, có thể gây damage hoặc debuff.
- `spawn`: điểm spawn.
- `objective`: điểm nhiệm vụ.
- `extract`: điểm rút lui.

Ví dụ dữ liệu ban đầu có thể viết trong code trước:

```dart
const missionOneMask = [
  '################',
  '#....cc.....vvv#',
  '#....cc.....vvv#',
  '#..####..bbb...#',
  '#........bbb...#',
  '#..vvv.........#',
  '#..vvv...cc....#',
  '#........cc....#',
  '#....hhhh......#',
  '#....hhhh..oo..#',
  '#..........oo..#',
  '#..cc..........#',
  '#..cc....####..#',
  '#..............#',
  '#SSSS......EEE.#',
  '################',
];
```

Legend:

- `#`: blocked
- `.`: walkable
- `v`: void
- `b`: bridge
- `c`: cover
- `h`: hazard
- `o`: objective
- `S`: player spawn
- `E`: enemy spawn/extract area

Sau đó có thể chuyển sang JSON nếu cần chỉnh nhanh.

## Movement Và Pathfinding

### Luật di chuyển

- Marine mỗi lượt đi tối đa `2 tiles`.
- Enemy cũng dùng cùng hệ luật movement.
- Melee range là `1 tile`.
- Ranged range là `3 tiles`.
- A* pathfinding chỉ được đi qua tile hợp lệ.
- `void`, `blocked`, hazard cấm đi nặng hoặc tile ngoài bounds luôn bị loại.
- Enemy hoặc ally đang sống cũng có thể block tile tùy tình huống.

### Highlight phải phản ánh luật thật

Khi chọn marine:

- Tile xanh: có thể move tới trong lượt này.
- Tile vàng: có thể bắn.
- Tile đỏ: có thể melee.
- Tile xám/đen: không thể đi do block/void.
- Cover tile có icon/outline riêng.

Không highlight các ô không thể đi. Đây là điểm quan trọng để người chơi tin map.

## Cover System

Cover không nên chỉ là hình đặt lên map. Cover phải là tile rule.

Luật đề xuất:

- Unit đứng cạnh `coverLow` hoặc `coverHigh` sẽ nhận giảm sát thương từ hướng bắn phù hợp.
- Bản đầu có thể đơn giản: nếu unit đứng trên hoặc cạnh cover tile, giảm damage ranged.
- Bản sau thêm hướng cover: north/south/east/west để tránh cover toàn năng.

Visual:

- Không dùng nguyên `cover_obstacle.png` size `1024x1024` làm obstacle.
- Tạo/crop cover sprite nhỏ theo tile hoặc tiếp tục dùng Canvas-drawn barricade/crate.
- Cover phải nằm đúng trên tile có sàn, không nằm trên vực/dưới cầu.

## Animation Plan

Asset hiện có:

- `marine_idle.png`
- `marine_walk.png`
- `marine_attack.png`
- `marine_dead.png`
- `enemy_idle.png`
- `enemy_walk.png`
- `enemy_attack.png`
- `enemy_dead.png`
- `marine_spritesheet.png`
- `enemy_spritesheet.png`

### Idle

- Marine active có vòng sáng rõ.
- Idle loop có scale pulse nhẹ hoặc breathing bob.
- Selected unit có outline/ring khác active unit.
- Unit đã hành động trong round giảm saturation/opacity nhẹ.

### Movement

- Khi click tile hợp lệ, unit không teleport.
- Unit chạy theo path bằng tween từng tile.
- Thời lượng đề xuất: `0.25s - 0.4s` mỗi tile.
- Thêm dust/spark nhỏ ở chân khi bắt đầu và kết thúc.
- Phát footstep/move audio.

### Attack

- Chuyển state sang attack trong `0.2s - 0.35s`.
- Thêm recoil nhẹ.
- Vẽ muzzle flash.
- Projectile/tracer bay từ shooter tới target.
- Target hit flash màu đỏ/trắng.
- Floating damage text.
- Nếu target chết, chuyển state dead sau hit.

### Enemy Phase

- Enemy không nên di chuyển đồng loạt ngay lập tức.
- Mỗi enemy được highlight lần lượt giống marine.
- Camera có thể pan nhẹ tới enemy active nếu enemy ở ngoài màn hình.
- Điều này giúp phase địch dễ đọc và căng hơn.

## Audio Plan

Giữ các audio hiện có và mở rộng dần:

- `ambient.wav`: loop nền, bắt đầu sau click đầu tiên nếu web autoplay bị chặn.
- `select.wav`: chọn unit.
- `move.wav`: bước chân/servo khi đi.
- `attack.wav`: bắn cơ bản.
- `turn.wav`: đổi lượt.

Thêm mới:

- `bolter.wav`
- `plasma.wav`
- `flamer.wav`
- `melee.wav`
- `enemy_hit.wav`
- `marine_hit.wav`
- `objective.wav`
- `warning.wav`

Audio phải ngắn, rõ, không quá dày. Mỗi command chính nên có phản hồi âm thanh.

## Mission Design 30 Phút

Mục tiêu là mỗi mission không chỉ là giết hết địch, mà là một bài toán chiến thuật kéo dài khoảng 30 phút.

### Cấu trúc một mission

1. Recon and Positioning - 3 đến 5 phút
   - Người chơi chọn hướng tiếp cận.
   - Map có fog/line of sight hoặc ít nhất là enemy chưa lộ hết.
   - Có vài cover và choke point rõ ràng.

2. First Contact - 5 phút
   - Địch xuất hiện theo nhóm nhỏ.
   - Người chơi học nhịp: move 2 tiles, shoot 3 tiles, melee 1 tile, cover.

3. Objective Pressure - 8 đến 10 phút
   - Bật relay, phá beacon, giữ điểm, hoặc lấy intel.
   - Objective buộc squad phải tách đội hoặc rời cover an toàn.

4. Escalation - 8 đến 10 phút
   - Reinforcement xuất hiện từ flank.
   - Enemy có unit đặc biệt: Nob, Loota, Psyker hoặc elite guard.
   - CP skill trở nên quan trọng.

5. Extraction or Final Push - 5 phút
   - Người chơi phải rút về điểm extract hoặc hạ mục tiêu chính.
   - Có quyết định phụ: cứu nhân chứng, hủy tài liệu, hoặc lấy thêm RP.

### Tactical Choices

Để màn chơi có "đấu trí":

- Chọn giữ choke point hay chia squad lấy objective.
- Dùng CP sớm để dọn wave hay giữ cho boss/elite.
- Đứng yên lấy bonus Grim Resolve hay di chuyển để né flank.
- Bắn Loota/Psyker trước hay chặn Boyz/Nob đang lao vào.
- Mạo hiểm lấy secondary objective để nhận thêm RP.

## UI Improvements

Khi chọn một Space Marine:

- Hiện action modes rõ ràng:
  - Move
  - Shoot
  - Melee
  - Ability
  - Overwatch
- Highlight active character của lượt hiện tại.
- Nút End Turn chỉ kết thúc activation của marine hiện tại.
- Sau khi hết 10 marine activation, chuyển sang enemy phase.
- Enemy phase dùng cùng cơ chế đọc được: từng enemy active, move/attack, rồi kết thúc.

Armory/mobile UI cũng cần sửa overflow:

- Card upgrade phải co giãn theo chiều ngang.
- Text tên item dài phải wrap hoặc auto-size.
- Không để ribbon/text đè lên nội dung chính.

## Implementation Roadmap

### Phase 1 - Map Render Stabilization

Files chính:

- `lib/models/tactical_map.dart`
- `lib/game/crusade_game.dart`
- `lib/game/components/grid_overlay_component.dart`

Tasks:

- Chuyển map từ `24x16` sang `16x16` cho asset `1024x1024`.
- Render background đúng native aspect ratio.
- Camera fit map rõ hơn.
- Grid opacity thấp hơn và có thể toggle.
- Không stretch ảnh map.

Acceptance:

- Map hiện rõ.
- Grid khớp từng ô `64px`.
- Cover không bị lệch khỏi chi tiết nền.

### Phase 2 - Tile Mask And Legal Movement

Files chính:

- `lib/models/tactical_map.dart`
- `lib/models/grid_position.dart`
- `lib/services/pathfinder.dart`
- `lib/providers/game_state_provider.dart`

Tasks:

- Thêm `TileRule`/`TileType`.
- Thêm mask cho từng mission.
- A* chỉ đi qua tile hợp lệ.
- `issueMove` reject tile void/blocked/out-of-range.
- Highlight reachable tile dựa trên path thật, không chỉ khoảng cách Manhattan.

Acceptance:

- Marine không thể đi xuống vực/dưới cầu.
- Enemy cũng tuân theo luật như marine.
- Click vào tile không hợp lệ có feedback rõ.

### Phase 3 - Animation And Combat Feedback

Files chính:

- `lib/game/components/marine_component.dart`
- `lib/game/components/enemy_component.dart`
- `lib/game/components/projectile_component.dart`
- `lib/game/components/effects/*`
- `lib/game/crusade_game.dart`

Tasks:

- Idle pulse rõ hơn.
- Move tween theo path từng tile.
- Attack state + muzzle flash + projectile.
- Hit flash + floating damage.
- Dead state giữ xác hoặc fade chậm.
- Active enemy/marine ring trong từng activation.

Acceptance:

- Không còn cảm giác unit teleport.
- Bắn và trúng đạn đọc được bằng mắt.
- Người chơi hiểu ai vừa hành động.

### Phase 4 - Audio Pass

Files chính:

- `assets/audio/`
- `lib/game/crusade_game.dart`

Tasks:

- Chuẩn hóa audio cache.
- Phát select/move/attack/turn/objective.
- Ambient loop theo mission.
- Fallback an toàn nếu web chặn autoplay.

Acceptance:

- Click chọn unit có tiếng.
- Move có tiếng.
- Attack có tiếng khác nhau theo loại vũ khí nếu có asset.
- Objective/turn có tín hiệu âm thanh.

### Phase 5 - 30-Minute Mission Structure

Files chính:

- `lib/models/mission.dart`
- `lib/providers/game_state_provider.dart`
- `lib/screens/command_screen.dart`

Tasks:

- Thêm mission phase state.
- Thêm objective chain.
- Thêm reinforcement schedule.
- Thêm secondary objectives.
- Thêm RP reward theo objective/elite kill.
- Thêm loss condition: squad wipe, objective failed, extraction failed.

Acceptance:

- Một mission có thể chơi 25-35 phút.
- Người chơi có quyết định chiến thuật thật.
- Mission có mở đầu, giữa trận, cao trào, kết thúc.

## Test Plan

### Unit Tests

- A* không đi qua `blocked`.
- A* không đi qua `void`.
- A* cho phép đi qua `bridge`.
- Move command reject path dài hơn 2 tile.
- Shoot accept range `<= 3`.
- Shoot reject range `> 3`.
- Melee chỉ accept adjacent tile.
- Cover damage reduction chỉ apply khi đúng tile/adjacent rule.
- Enemy AI không chọn destination không hợp lệ.

### Widget Tests

- Command screen render battlefield.
- Chọn marine hiện action modes.
- End Turn chuyển active marine.
- Sau hết marine, enemy phase bắt đầu.
- Armory modal không overflow trên mobile width.

### Manual Tests

- Web build load được ảnh map và audio.
- Windows build map không méo.
- Marine không đi được vào vực/dưới cầu.
- Enemy phase dễ đọc.
- Một mission hoàn thành được end-to-end.

## Ưu tiên thực hiện

1. Sửa map render đúng `1024x1024` và grid `16x16`.
2. Thêm tile mask để cấm đi vào vực/dưới cầu.
3. Highlight chỉ tile hợp lệ.
4. Làm move animation theo path.
5. Thêm attack feedback và audio.
6. Thiết kế lại mission theo 5 pha để đạt khoảng 30 phút.

## Definition Of Done

- Map hiển thị rõ, không bị kéo méo.
- Không dùng Tiled trong vertical slice.
- Mỗi tile có luật rõ: đi được, chặn, vực, cầu, cover, objective.
- Marine và enemy dùng cùng luật movement.
- Unit có idle/move/attack/death feedback dễ thấy.
- Command có audio phản hồi.
- Một mission có đủ pha để chơi khoảng 30 phút và tạo áp lực chiến thuật.
