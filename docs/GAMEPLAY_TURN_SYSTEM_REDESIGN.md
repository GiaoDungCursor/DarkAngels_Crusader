# Gameplay Turn System Redesign

## Mục tiêu

Lối chơi hiện tại đang bị chậm vì mỗi lượt chỉ kích hoạt 1 Space Marine, làm người chơi phải bấm `End Turn` liên tục. Với squad 10 người, nhịp này dễ mệt và thiếu cảm giác chỉ huy một đội tinh nhuệ.

Mục tiêu cải tiến là chuyển sang hệ thống **Squad Turn + Action Points**, lấy cảm hứng từ các game tactical turn-based hiện đại trong bối cảnh Warhammer 40K như `Chaos Gate: Daemonhunters`, đồng thời giữ grid, cover, range và CP hiện có.

## Vấn đề hiện tại

- Người chơi chỉ điều khiển 1 marine trong một activation.
- Muốn dùng cả squad phải bấm qua từng người.
- Không dễ tạo combo chiến thuật giữa các marine.
- Reserve, beacon, bomb, overwatch bị rời rạc vì mỗi hành động bị khóa theo lượt cá nhân.
- 10 marine làm nhịp game quá dài nếu mỗi người cần một turn riêng.

## Hệ thống đề xuất: Squad Turn

Mỗi round gồm 2 phase:

1. **Player Squad Phase**
   - Người chơi được điều khiển toàn bộ marine còn sống.
   - Có thể chọn marine theo thứ tự tùy ý.
   - Mỗi marine có Action Points riêng.

2. **Enemy Phase**
   - Khi người chơi bấm `End Squad Turn`, toàn bộ địch mới hành động.
   - Địch di chuyển, bắn, melee, flank hoặc giữ cover.

Sau Enemy Phase, round mới bắt đầu, toàn squad được hồi AP.

## Action Points

Mỗi marine có `2 AP` mỗi round.

| Hành động | AP | CP | Ghi chú |
|---|---:|---:|---|
| Move ngắn | 1 | 0 | Di chuyển tối đa 2 ô |
| Move dài | 2 | 0 | Di chuyển tối đa 4 ô, không được attack sau đó |
| Shoot | 1 | 0 | Range 3 ô, cần line of sight |
| Melee | 1 | 0 | Range 1 ô |
| Overwatch | 1 | 0 | Bắn phản ứng trong Enemy Phase |
| Class Skill | 1 | 1-2 | Tùy class |
| Plant Bomb | 1 | 1 | Chỉ khi đứng cạnh enemy base |
| Deploy Beacon | 1 | 1 | Commander hoặc Techmarine |
| Use Medkit / Heal | 1 | 1 | Apothecary mạnh hơn |
| Reserve Drop | 0 | 2 | Gọi marine từ reserve xuống drop zone |

## Quy tắc hành động

- Một marine có thể `Move + Shoot`.
- Một marine có thể `Shoot + Move`.
- Một marine có thể `Move + Overwatch`.
- Một marine có thể dùng `2 AP` để di chuyển xa.
- Nếu marine đã hết AP thì card bị dim.
- Người chơi có thể chuyển qua lại giữa các marine miễn là còn AP.

## Command Points

CP vẫn là tài nguyên squad-wide.

Đề xuất:

- Bắt đầu mission với `5 CP`.
- Mỗi round hồi `1 CP`.
- Giết elite hoặc hoàn thành objective phụ cho thêm `1-2 CP`.
- CP dùng cho skill mạnh, reserve drop, beacon, bomb.

CP sẽ tạo lựa chọn chiến thuật: dùng plasma overcharge ngay, hay giữ CP để gọi reserve/drop beacon.

## UI mới

### Top Bar

Hiển thị:

- Mission name
- Round
- CP
- Objective progress
- Nút `End Squad Turn`

### Right Squad Panel

Mỗi marine hiển thị:

- Portrait
- HP
- AP còn lại: ví dụ `AP 2/2`, `AP 1/2`, `SPENT`
- Trạng thái: overwatch, wounded, in cover

Click marine nào thì chọn marine đó ngay.

### Bottom Command Card

Command card theo marine đang chọn:

- Move
- Shoot
- Melee
- Skill
- Overwatch
- Beacon
- Bomb
- Armory/Info

Mỗi nút ghi rõ cost:

- `Move 1 AP`
- `Shoot 1 AP`
- `Beacon 1 AP / 1 CP`

### Battlefield Overlay

Khi chọn hành động:

- Ô xanh: move được.
- Ô vàng: shoot được.
- Ô đỏ: melee/danger.
- Ô xanh ngọc: drop/beacon.
- Ô đỏ đậm: plant bomb.
- Ô xám: cover/block.

Khi hover/click một ô, hiện tooltip nhỏ:

- `Move: 1 AP`
- `In enemy range`
- `Cover: -50% ranged damage`
- `Line of sight blocked`

## Enemy AI

Enemy phase nên được cải tiến thành nhiều intent rõ ràng:

### Ork Boy

- Rush marine gần nhất.
- Ưu tiên melee.
- Nếu không tới được thì chạy vào cover gần.

### Nob

- Tìm marine yếu hoặc đứng cô lập.
- Có thể charge 3 ô.

### Loota

- Giữ khoảng cách.
- Ưu tiên đứng cạnh cover.
- Bắn marine không có cover.

### Enemy Base

- Spawn wave theo timer/round.
- Có thể bị phá bằng bomb.
- Khi bị plant bomb, đếm ngược 1 enemy phase rồi nổ.

## Cover

Cover hiện tại nên rõ hơn trong gameplay:

- Đứng cạnh cover nhận `-50% ranged damage`.
- Cover không giảm melee damage.
- Nếu line of sight đi xuyên cover, bắn bị chặn hoặc giảm accuracy.
- UI nên hiện icon shield trên marine đang được cover.

Sau này có thể nâng cấp thành directional cover, nhưng v1 chỉ cần adjacent cover cho dễ hiểu.

## Reserve Drop

Reserve nên là cơ chế chiến thuật chính:

- Người chơi click marine trong reserve.
- Map highlight các drop zone hợp lệ.
- Click ô drop để thả quân.
- Tốn `2 CP`.
- Marine vừa drop xuống có `0 AP` trong round hiện tại, round sau mới hành động.

Drop zone hợp lệ:

- Marine spawn ban đầu.
- Drop beacon do Commander/Techmarine đặt.
- Một số objective tile đã chiếm được.

## Mission Flow mới

Ví dụ Mission 1: `Drop Zone Epsilon: Broken Landing`

1. Start với 4 marine.
2. Objective: giữ landing zone 3 round.
3. Objective phụ: Commander/Techmarine đặt beacon.
4. Gọi reserve xuống từ beacon.
5. Phá 3 enemy bases bằng bomb.
6. Survive final wave.
7. Extraction / Victory screen.

## Vì sao hệ này tốt hơn

- Người chơi có cảm giác chỉ huy squad thật sự.
- Ít bấm `End Turn` vô nghĩa hơn.
- Có nhiều combo hơn:
  - Soren suppress.
  - Titus tiến lên tank.
  - Rusk flank.
  - Nero đặt beacon.
  - Reserve drop xuống giữ cánh.
- 10 marine không còn làm game chậm.
- UI dễ hiểu hơn vì AP hiển thị trực tiếp.

## Kế hoạch implement

### Phase 1: State

- Thêm `actionPoints` vào `Marine`.
- Mỗi marine có `maxActionPoints = 2`.
- Reset AP khi bắt đầu Player Squad Phase.
- Bỏ logic bắt buộc selected marine theo thứ tự.

### Phase 2: Commands

- `issueMove` trừ AP.
- `issueAttack` trừ AP.
- `setOverwatch` trừ AP.
- `plantBomb` trừ AP + CP.
- `deployBeacon` trừ AP + CP.
- `deployReserve` chỉ trừ CP.

### Phase 3: Turn Flow

- Đổi `End Turn` thành `End Squad Turn`.
- Chỉ chuyển Enemy Phase khi người chơi bấm nút này.
- Nếu toàn squad hết AP, nút End Squad Turn sáng nổi bật.

### Phase 4: UI

- Right panel hiển thị AP từng marine.
- Command card hiển thị cost.
- Disable nút khi không đủ AP/CP.
- Battle log ghi rõ hành động và cost.

### Phase 5: Enemy Phase

- Enemy phase xử lý sau khi player kết thúc squad turn.
- AI có intent đơn giản trước:
  - melee rush
  - ranged shoot
  - move to cover
  - spawn base

## Quyết định đề xuất

Nên triển khai hệ **Squad Turn + 2 AP mỗi marine** trước. Đây là thay đổi lớn nhất để game bớt nhàm và bớt bất tiện. Các cải tiến map, cover direction, stealth, cinematic có thể làm sau, nhưng turn system phải là nền móng gameplay.
