# Orbital Drop, Reinforcement, Cover, and Stealth Design

## Mục tiêu

Nâng mission mở đầu thành một trải nghiệm có nhịp rõ ràng hơn:

1. Mở màn bằng cutscene thả orbital drop.
2. Drop pod đáp xuống và triển khai 4 Space Marine đầu tiên.
3. Người chơi tiến sâu vào map, tương tác môi trường, tạo cover/block mới.
4. Có thể gọi viện trợ thả thêm marine hoặc support xuống battlefield.
5. Cover có tác dụng chiến thuật rõ: giảm xác suất bị bắn hoặc giảm sát thương.
6. Marine có animation núp sau cover.
7. Có stealth mode để lén tiếp cận, trinh sát, tránh báo động hoặc setup phục kích.

## Trải nghiệm người chơi mong muốn

Mission không bắt đầu bằng 10 marine đứng sẵn trên grid nữa. Thay vào đó:

- Người chơi xem một đoạn intro ngắn: tàu chiến trên quỹ đạo, drop pod lao xuống hành tinh.
- Drop pod va chạm xuống điểm đáp.
- Cửa pod mở, 4 marine đầu tiên bước ra.
- UI báo: `Secure Landing Zone`.
- Người chơi phải dùng 4 marine này chiếm điểm, tránh patrol, tận dụng cover, rồi gọi viện trợ.
- Các marine còn lại không xuất hiện ngay; họ là tài nguyên chiến thuật được gọi xuống khi đủ điều kiện.

Nhịp này giúp trận đấu có mở đầu, giữa trận, cao trào, thay vì toàn bộ squad xuất hiện cùng lúc.

## Phase Flow Của Mission

### Phase 1 - Orbital Drop Cutscene

Thời lượng đề xuất: 8-15 giây.

Nội dung:

- Màn hình tối, âm thanh vox/radio.
- Hiện cảnh orbital fleet hoặc nền sao.
- Drop pod cháy sáng lao xuống khí quyển.
- Camera rung nhẹ khi impact.
- Fade vào battlefield.

Yêu cầu kỹ thuật:

- Có thể làm bằng Flutter overlay + Flame effect.
- Không cần full video ban đầu; dùng sprite/bitmap + animation là đủ.
- Có nút `Skip` để bỏ qua cutscene.

Asset cần:

- `drop_pod.png`
- `drop_pod_trail.png` hoặc particle flame/smoke.
- `impact_flash.png` hoặc effect vẽ bằng Canvas.
- Audio:
  - `orbital_drop.wav`
  - `impact.wav`
  - `pod_door.wav`

### Phase 2 - Initial Squad: 4 Marines

Ban đầu chỉ triển khai 4 marine:

1. Cpt. Varro - Commander
2. Iolan - Plasma Gunner
3. Marek - Apothecary
4. Titus hoặc Soren - Tank/Heavy Support

Lý do:

- Dễ học hơn 10 marine ngay từ đầu.
- Người chơi phải ra quyết định với tài nguyên hạn chế.
- Reinforcement trở thành phần thưởng/tactical option.

Rule đề xuất:

- 4 marine đầu spawn quanh drop pod.
- Drop pod tự nó là cover lớn.
- Drop pod có thể là extraction/respawn/reinforcement beacon.
- Sau khi chiếm Landing Zone hoặc đủ CP, người chơi được gọi thêm marine.

### Phase 3 - Secure Landing Zone

Objective đầu:

- Giữ khu vực đáp trong 3 round.
- Tiêu diệt patrol gần đó.
- Tương tác với relay hoặc auspex beacon.

Khi hoàn thành:

- Mở khóa `Call Reinforcement`.
- Mở rộng fog-of-war/vision.
- Spawn thêm enemy wave hoặc patrol phản ứng.

### Phase 4 - Tactical Advance

Người chơi tiến vào map.

Cơ chế chính:

- Tương tác môi trường.
- Tạo cover.
- Phá vật cản.
- Tắt alarm.
- Dùng stealth mode để tránh bị phát hiện.
- Setup Overwatch hoặc ambush.

### Phase 5 - Escalation And Reinforcement

Khi bị phát hiện hoặc hoàn thành objective:

- Enemy gọi quân tiếp viện.
- Người chơi có thể gọi thêm marine xuống.
- Drop pod hoặc teleport beacon thả unit vào các điểm hợp lệ.

## Reinforcement System

### Ý tưởng

Thay vì có đủ 10 marine ngay từ đầu, 6 marine còn lại nằm trong reserve.

Người chơi gọi viện trợ bằng:

- CP
- Objective reward
- Holding landing zone
- Activating comms relay
- Destroying anti-air/void shield jammer

### Reinforcement Types

#### 1. Deploy Marine

Gọi thêm một marine từ reserve.

Ví dụ:

- Gọi Soren khi cần suppressive fire.
- Gọi Rusk khi cần flanking/melee.
- Gọi Nero khi cần sửa cửa/tạo turret.
- Gọi Sevran khi cần dọn hẹp bằng flamer.

Rule:

- Cost: 2-4 CP hoặc mission charge.
- Chỉ deploy ở valid drop tile.
- Không thể deploy trên `blocked`, `void`, `enemy occupied`, hoặc tile trong enemy overwatch.

#### 2. Supply Drop

Thả crate hỗ trợ:

- Medkit
- Ammo cache
- Temporary cover
- CP battery

#### 3. Orbital Support

Gọi fire support:

- Orbital Strike
- Smoke screen
- Auspex scan
- Servo-skull scout

### UI Reinforcement

Thêm nút `Reinforce` cạnh action bar.

Khi bấm:

- Mở panel reserve marine.
- Chọn marine/support.
- Map highlight tile hợp lệ để thả.
- Click tile để xác nhận.

## Environment Interaction

### Mục tiêu

Marine không chỉ đi và bắn. Họ có thể thay đổi battlefield.

### Interaction Types

#### 1. Create Cover

Marine tương tác với môi trường để tạo block/cover mới.

Ví dụ:

- Lật barricade.
- Kéo crate.
- Hạ blast shield.
- Kích hoạt bulkhead.
- Nero dựng turret hoặc deploy shield generator.

Rule:

- Tốn action hoặc ability.
- Tạo tile `cover`.
- Cover tile block movement.
- Unit đứng cạnh cover được giảm nguy cơ bị bắn.

#### 2. Destroy Cover

Một số vũ khí phá cover:

- Flamer thiêu cover nhẹ.
- Plasma phá cover cứng.
- Melee/Chainsword phá barricade.

Rule:

- Cover có HP.
- Khi cover HP về 0, tile trở lại `floor`.

#### 3. Doors And Consoles

Nero hoặc marine bất kỳ có thể tương tác:

- Mở/khóa cửa.
- Tắt alarm.
- Bật cầu.
- Tắt turret địch.
- Kích hoạt auspex scan.

#### 4. Hazard Control

Tương tác với môi trường:

- Xả hơi độc.
- Tắt lửa.
- Bật plasma conduit gây damage vùng.
- Dập hazard để tạo đường đi.

## Cover System V2

### Cover Rule Đề Xuất

Nếu unit đứng cạnh cover hoặc ở tile cover-position hợp lệ:

- Giảm 50% xác suất bị bắn trúng.
- Hoặc giảm 50% damage ranged nhận vào.

Khuyến nghị cho bản đầu:

- Dùng giảm damage 50% trước vì dễ test và deterministic.
- Sau đó mới thêm hit chance nếu có accuracy system.

Rule bản đầu:

```text
Ranged damage vào unit có cover: damage * 0.5
Melee bỏ qua cover.
Flamer bỏ qua một phần cover.
Plasma giảm hiệu quả cover còn 25%.
```

### Cover Facing

Bản đầu:

- Cover hoạt động nếu unit đứng cạnh cover trong phạm vi 1 tile.

Bản nâng cấp:

- Cover có hướng.
- Chỉ giảm damage nếu cover nằm giữa shooter và target.
- Dùng line raycast để kiểm tra.

### Cover Animation

Khi marine ở gần cover:

- Nếu không hành động: idle chuyển sang crouch/brace.
- Khi bị bắn: marine nghiêng người/núp xuống.
- Khi bắn từ cover: marine peek out rồi bắn.

Animation state đề xuất:

- `idle`
- `walk`
- `attack`
- `dead`
- `takeCover`
- `peekShoot`
- `hit`

Nếu chưa có sprite riêng:

- Dùng scale/offset/rotation nhẹ để giả lập:
  - Lower body xuống 4-6px.
  - Slight lean về phía cover.
  - Khi bắn, tween ra ngoài rồi quay lại.

## Stealth Mode

### Mục tiêu

Thêm một lớp chiến thuật trước khi giao tranh lớn nổ ra.

Người chơi có thể:

- Di chuyển chậm hơn nhưng ít bị phát hiện.
- Quan sát patrol.
- Tắt alarm.
- Setup ambush.
- Tránh gọi reinforcement của địch.

### Stealth State

Mission có thể có trạng thái:

- `stealth`
- `alert`
- `combat`
- `lockdown`

#### Stealth

- Enemy patrol theo route.
- Enemy chỉ phát hiện marine trong cone/range.
- Marine chưa bắn hoặc chưa gây tiếng động.
- UI hiển thị vision cone và detection meter.

#### Alert

- Enemy nghi ngờ.
- Patrol đổi hướng.
- Detection meter tăng.
- Nếu người chơi lùi vào cover/dark tile, meter giảm.

#### Combat

- Bị phát hiện hoàn toàn.
- Enemy gọi viện trợ.
- Tất cả enemy gần đó active.

#### Lockdown

- Alarm đã bật.
- Spawn wave theo thời gian.
- Một số cửa khóa lại.

### Detection Rule Bản Đầu

Để dễ làm trước:

```text
Enemy detects marine if:
- distance <= 4 tiles
- line of sight clear
- marine is not behind cover
- marine did not use stealth stance
```

Stealth stance:

- Move range giảm từ 2 xuống 1.
- Không được shoot thường.
- Có thể dùng silent takedown nếu adjacent.
- Detection range của enemy giảm 50%.

### Noise System

Một số hành động tạo noise:

- Boltgun: loud
- Plasma: loud
- Melee: medium
- Silent takedown: low
- Door hack: low
- Flamer: loud
- Orbital drop: massive

Enemy nghe noise sẽ đi kiểm tra vị trí.

Bản đầu có thể đơn giản:

- Shooting trong stealth chuyển mission sang `combat`.
- Silent takedown không chuyển combat nếu target chết ngay và không có enemy khác nhìn thấy.

## Marine Roles Trong Hệ Mới

### Cpt. Varro

- Mở đầu đi cùng squad.
- Gọi reinforcement nhanh hơn.
- Có skill `Command Beacon`: giảm cost deploy marine kế tiếp.

### Iolan

- Plasma phá cover và elite armor.
- Bắn plasma gây noise lớn.
- Overheat vẫn là risk.

### Marek

- Hồi máu.
- Có thể stabilize marine bị wounded.
- Có thể thu geneseed/objective trong stealth mà không gây alarm.

### Soren

- Suppressive fire.
- Giữ choke point.
- Khi ở cover, fire lane mạnh hơn.

### Rusk

- Flanker.
- Silent melee takedown trong stealth.
- Jump/charge qua cover thấp.

### Galen

- Scout/marksman.
- Auspex mark enemy patrol.
- Silent first shot nếu dùng Stalker Bolter upgrade.

### Titus

- Tank.
- Deployable shield.
- Cover bonus mạnh hơn.

### Nero

- Tương tác môi trường tốt nhất.
- Dựng turret.
- Tạo cover.
- Hack door/relay/alarm.

### Cassian

- Flexible veteran.
- Bonus khi ở cover.
- Có thể command small squad move.

### Sevran

- Flamer dọn cover và choke.
- Không phù hợp stealth vì gây noise cao.

## UI/UX Cần Thêm

### Mission Start Cutscene UI

- `Skip` góc phải.
- Radio subtitle ngắn.
- Không nhồi lore dài.

### Reinforcement Panel

Hiển thị:

- Reserve marine.
- Cost.
- Role.
- Deploy condition.
- Tile hợp lệ trên map.

### Stealth HUD

Hiển thị:

- Current mission state: `STEALTH`, `ALERT`, `COMBAT`.
- Detection meter.
- Enemy vision cone.
- Noise warning khi chọn vũ khí loud.

### Cover UI

Hiển thị:

- Icon shield trên tile cover.
- Khi marine đứng cạnh cover: `In Cover -50% ranged damage`.
- Khi target địch trong cover: tooltip `Target in cover`.

### Action Bar Mới

Các action:

- Move
- Shoot
- Melee
- Ability
- Guard
- Stealth
- Interact
- Reinforce

Không nên hiển thị tất cả nếu không dùng được. Nút unavailable có tooltip giải thích.

## Data Model Đề Xuất

### Mission State

Thêm:

```dart
enum AlertState { stealth, alert, combat, lockdown }
```

Trong `GameState`:

```dart
final AlertState alertState;
final int detectionLevel;
final List<Marine> reserveSquad;
final Set<GridPosition> dropZones;
final Set<GridPosition> interactableTiles;
final Map<GridPosition, CoverObject> dynamicCover;
```

### Cover Object

```dart
class CoverObject {
  final String id;
  final GridPosition position;
  final int hp;
  final int maxHp;
  final CoverType type;
  final bool blocksMovement;
  final double rangedDamageMultiplier;
}
```

### Interactable Object

```dart
class InteractableObject {
  final String id;
  final GridPosition position;
  final InteractionType type;
  final int actionCost;
  final List<String> allowedRoles;
}
```

## Implementation Roadmap

### Phase 1 - Cutscene Skeleton

- Thêm `MissionIntroScreen` hoặc overlay trước `CommandScreen`.
- Play drop pod animation đơn giản.
- Skip được.
- Sau cutscene mới tạo `GameState`.

### Phase 2 - Initial 4 Marines And Reserve

- `_initSquad` chỉ active 4 marine đầu.
- 6 marine còn lại vào `reserveSquad`.
- UI squad list chia `Deployed` và `Reserve`.

### Phase 3 - Reinforcement Action

- Thêm `ActionMode.reinforce`.
- Thêm drop zones.
- Chọn reserve marine, click tile hợp lệ, deploy vào squad.

### Phase 4 - Dynamic Cover

- Thêm `dynamicCover`.
- Pathfinder xem dynamic cover là blocker.
- Damage reduction 50%.
- Interact action tạo cover ở tile adjacent.

### Phase 5 - Cover Animation

- Marine component nhận `inCover`.
- Thêm fake crouch/peek animation bằng offset/scale trước.
- Sau đó mới tạo sprite riêng nếu cần.

### Phase 6 - Stealth Mode

- Thêm `AlertState`.
- Thêm enemy detection check.
- Thêm stealth action.
- Enemy patrol nếu chưa combat.
- Shooting loud chuyển sang combat.

### Phase 7 - Mission Design Pass

- Mission 1 đổi thành:
  - Drop pod landing.
  - Secure LZ.
  - Call first reinforcement.
  - Disable beacon.
  - Extract or hold against counterattack.

## Acceptance Criteria

- Mission mở đầu không spawn đủ 10 marine ngay.
- Có cutscene drop pod ngắn, skip được.
- 4 marine đầu xuất hiện quanh drop pod.
- Người chơi gọi được ít nhất 1 reinforcement.
- Có ít nhất 1 interaction tạo cover mới.
- Cover giảm 50% ranged damage.
- Marine có animation/pose khi ở cover.
- Có stealth state trước khi combat.
- Bắn súng lớn làm enemy alert/combat.
- UI giải thích rõ cover, stealth, reinforcement.

## Rủi ro Và Cách Giữ Scope

Rủi ro lớn nhất là làm quá nhiều hệ cùng lúc. Để giữ scope:

1. Làm cutscene bằng animation đơn giản, chưa cần video.
2. Reinforcement chỉ cần deploy marine trước, support drop làm sau.
3. Cover giảm damage deterministic trước, hit chance làm sau.
4. Stealth detection dùng range + LoS đơn giản trước, vision cone làm sau.
5. Cover animation dùng transform fake trước, sprite riêng làm sau.

## Kết Luận

Ý tưởng này nên trở thành hướng chính cho mission đầu. Nó giúp game có:

- Mở màn điện ảnh.
- Nhịp chiến thuật tăng dần.
- Squad progression ngay trong mission.
- Môi trường có giá trị.
- Cover có cảm giác thật.
- Stealth tạo lựa chọn trước combat.

Đây là nền rất tốt để biến prototype thành một vertical slice hấp dẫn hơn.
