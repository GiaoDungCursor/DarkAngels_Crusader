# Campaign Mission Flow Design

## Mục tiêu

Thiết kế lại cấu trúc một màn chơi để game có cảm giác là một chiến dịch hoàn chỉnh, không chỉ là một map combat đơn lẻ.

Một mission lý tưởng sẽ có flow:

1. Campaign title.
2. Mission briefing bằng portrait chỉ huy và text click-through.
3. Mục tiêu chính và mục tiêu phụ được trình bày rõ.
4. Cutscene thả drop pod.
5. Người chơi bố trí chiến thuật trên map rộng.
6. Hoàn thành objective trong khoảng 15-30 phút.
7. End cutscene: drop pod extraction, reinforcement arrival, hoặc Terminator teleport xuống cover.
8. Mission result: RP, casualties, unlock, next mission hook.

## Campaign Đề Xuất

### Campaign Name

**The Obolus Prime Incursion**

Tên tiếng Việt:

**Chiến Dịch Obolus Prime**

### Tone

- U tối, quân sự, bí mật.
- Dark Angels đến để "giải cứu" hành tinh, nhưng mục tiêu thật là truy dấu The Fallen.
- Người chơi luôn có hai tầng nhiệm vụ:
  - Nhiệm vụ công khai: cứu điểm chiến lược, phá beacon, giữ landing zone.
  - Nhiệm vụ bí mật: thu hồi dữ liệu, thủ tiêu nhân chứng, khóa dấu vết The Fallen.

## Mission Structure Tổng Quát

Mỗi mission gồm 7 phần:

```text
Campaign Screen
  -> Commander Briefing
  -> Loadout / Squad Selection
  -> Orbital Drop Cutscene
  -> Tactical Deployment
  -> Main Gameplay
  -> End Cutscene
  -> Result Screen
```

## 1. Campaign Screen

### Mục đích

Cho người chơi cảm giác đang bước vào một chiến dịch thật.

### Nội dung hiển thị

- Campaign name.
- Planet name.
- Threat level.
- Current operation.
- Mission list.
- Progression path.

### Ví dụ UI Copy

```text
THE OBOLUS PRIME INCURSION
Forge-Hive World: Obolus Prime
Status: Planetary defense collapsing
Public Directive: Secure Imperial assets
Inner Circle Directive: Locate the Fallen signal
```

### Campaign Mission List

1. **Operation Iron Halo**
   - Secure Drop Zone Epsilon.
   - Establish orbital relay.

2. **Operation Blind Reliquary**
   - Enter Hive Gate Primus.
   - Destroy cult beacon.
   - Recover encrypted trace.

3. **Operation Ash Basilica**
   - Assault the ruined basilica.
   - Confirm Fallen presence.
   - Extract or erase all evidence.

## 2. Commander Briefing

### Mục tiêu

Trước khi vào trận, hiện portrait chỉ huy và text nhiệm vụ ở dưới. Người chơi click để qua từng dòng thoại, giống một visual novel / tactical briefing đơn giản.

Không cần video briefing. Phần cinematic video chính nên để dành cho orbital drop.

### Nhân vật briefing

Đề xuất:

**Master Azael Vorn - Inner Circle Liaison**

Vai trò:

- Không trực tiếp ra trận.
- Giao nhiệm vụ bằng giọng lạnh, bí ẩn.
- Nói một phần nhiệm vụ công khai và một phần nhiệm vụ bí mật.

Hoặc dùng:

**Cpt. Varro**

Vai trò:

- Nếu muốn tập trung vào squad, Varro vừa là commander vừa là playable unit.
- Briefing có thể là vox transmission trước khi drop.

### Briefing Layout

Màn hình briefing gồm:

- Portrait chỉ huy lớn ở trên hoặc bên trái.
- Text dialogue ở panel dưới.
- Tên campaign và mission ở header.
- Icon objective nhỏ.
- Người chơi click để chuyển dòng.
- Dòng cuối mở nút `Begin Drop`.

Flow:

```text
Show commander portrait
  -> Dialogue line 1
  -> User click
  -> Dialogue line 2
  -> User click
  -> Dialogue line 3
  -> User click
  -> Show Begin Drop button
  -> Orbital Drop Cutscene
```

### Ví dụ Briefing Text

Mission: **Operation Iron Halo**

```text
MASTER AZAEL VORN:
"Operation Iron Halo begins now."

"Drop Zone Epsilon is lost. You will land with four battle-brothers and secure the relay."

"The public objective is simple: restore orbital coordination and break the enemy beachhead."

"The true directive is not. Recover the encrypted trace before anyone else understands what it is."

"When the pod opens, move fast. Cover will keep you alive. The relay will bring your brothers down."
```

## 3. Loadout / Squad Selection

### Mục tiêu

Người chơi chọn 4 marine đầu tiên hoặc dùng squad mặc định.

### Bản đầu

Để đơn giản:

- Mission 1 bắt buộc dùng 4 marine:
  - Cpt. Varro
  - Iolan
  - Marek
  - Titus hoặc Soren
- 6 marine còn lại vào reserve.

### Bản sau

Cho người chơi tự chọn:

- 4 initial drop marines.
- 6 reserve marines.
- 1 command doctrine.
- 1 orbital support.

## 4. Orbital Drop Cutscene

### Mục tiêu

Tạo cảm giác điện ảnh khi bắt đầu mission.

### Cutscene Flow

```text
Black screen
  -> Vox static
  -> Commander final line from briefing fades out
  -> Planet orbit shot
  -> Drop pod launch
  -> Burning atmospheric entry
  -> Impact flash
  -> Battlefield camera shake
  -> Drop pod door opens
  -> Four marines step out
  -> Player control begins
```

### Thời lượng

- 10-15 giây.
- Có nút `Skip`.

### Implementation Bản Đầu

Không cần video thật.

Dùng:

- Background image orbit/planet.
- Drop pod sprite.
- Tween xuống màn hình.
- Smoke/fire particles.
- Screen shake.
- Fade vào Flame battlefield.

## 5. Tactical Deployment

### Mục tiêu

Trước khi combat lớn, người chơi có thời gian bố trí.

### Player Actions

Trong giai đoạn đầu:

- Move.
- Stealth.
- Interact.
- Take Cover.
- Overwatch.
- Scan.

Không nên cho reinforcement ngay lập tức. Người chơi phải chiếm được objective đầu.

### Deployment Rules

- Drop pod là center spawn.
- Drop pod tạo cover lớn.
- Initial enemy chưa biết vị trí người chơi nếu mission đang ở stealth.
- Có patrol hoặc sentry gần đó.

## 6. Main Gameplay Map

### Map Size

Mục tiêu chơi 15-30 phút.

Map nên lớn hơn prototype hiện tại.

Đề xuất:

- Bản đầu: `24x18` hoặc `24x20`.
- Tile size: `64px`.
- Map image size tương ứng:
  - `1536x1152` cho `24x18`.
  - `1536x1280` cho `24x20`.

Nếu vẫn dùng ảnh `1024x1024`, map sẽ hơi chật cho 15-30 phút. Vì vậy mission mới nên có map generated/custom đúng tỷ lệ.

### Map Layout Cho Mission 1

Mission: **Operation Iron Halo**

Khu vực:

- Drop pod crater.
- Ruined landing pad.
- Cargo lanes.
- Relay station.
- Fuel pipes/hazard zone.
- Ork barricade camp.
- Extraction/secondary drop zone.

### Gameplay Flow 15-30 Phút

#### Phase A - Landing Zone

Thời lượng: 3-5 phút.

Objective:

- Deploy 4 marines.
- Clear nearby patrol.
- Reach cover.
- Secure immediate drop zone.

Gameplay:

- Tutorial nhẹ cho movement, cover, stealth.
- Enemy ít, không quá đông.

#### Phase B - Relay Push

Thời lượng: 5-8 phút.

Objective:

- Tiến tới relay station.
- Tắt alarm hoặc hack console.
- Tránh hoặc xử lý patrol.

Gameplay:

- Người chơi chọn stealth hoặc combat.
- Có vài route:
  - Đường ngắn nhiều enemy.
  - Đường vòng nhiều cover.
  - Đường hazard nhưng ít patrol.

#### Phase C - Reinforcement Window

Thời lượng: 3-5 phút.

Objective:

- Kích hoạt reinforcement beacon.
- Gọi thêm 1-2 marine xuống.

Cut-in:

- Drop pod nhỏ thả supply hoặc marine.
- Hoặc teleport flash cho Terminator nếu unlock.

Gameplay:

- Người chơi chọn reinforcement phù hợp:
  - Soren nếu cần hỏa lực.
  - Nero nếu cần hack/turret.
  - Rusk nếu cần flank.
  - Sevran nếu cần dọn choke.

#### Phase D - Main Objective

Thời lượng: 8-10 phút.

Objective:

- Destroy Ork command beacon.
- Kill Nob/Loota commander.
- Recover encrypted Fallen trace.

Gameplay:

- Enemy wave mạnh hơn.
- Cover và chokepoint quan trọng.
- Có secondary objective tạo risk/reward.

#### Phase E - Extraction / End Cinematic Trigger

Thời lượng: 3-5 phút.

Objective:

- Rút về extraction tile.
- Hoặc hold position cho extraction.
- Hoặc survive tới khi Terminator support teleports in.

Gameplay:

- Enemy counterattack.
- Người chơi phải quyết định rút nhanh hay lấy thêm objective.

## 7. End Cutscene

Sau khi hoàn thành mục tiêu chính, hiện cutscene ngắn.

### Option A - Drop Pod Extraction

Phù hợp khi squad rút khỏi map.

Flow:

```text
Objective complete
  -> Vox: "Extraction beacon confirmed."
  -> Drop pod descends in smoke
  -> Marines move to extraction zone
  -> Door closes
  -> Fade out
```

### Option B - Terminator Teleport Onto Cover

Phù hợp khi mission kết thúc bằng reinforcement/counterattack.

Flow:

```text
Objective complete
  -> Enemy counterattack begins
  -> Teleport homer activates
  -> Lightning flash
  -> Deathwing Terminator teleports behind cover
  -> Terminator fires/raises storm shield
  -> Fade to result screen
```

### Option C - Emergency Extraction Under Fire

Phù hợp khi player thắng nhưng squad bị thương nặng.

Flow:

```text
Smoke barrage
  -> Drop craft silhouette
  -> Bolter fire in background
  -> Surviving marines extracted
  -> Result screen shows wounded status
```

## Mission Result Screen

Hiển thị sau end cutscene:

- Victory/Defeat.
- Main objective completed.
- Secondary objectives.
- RP earned.
- Marines wounded.
- Enemies eliminated.
- Secrets recovered.
- Next mission unlocked.

Ví dụ:

```text
OPERATION IRON HALO COMPLETE

Main Objective:
Landing relay secured.

Hidden Directive:
Encrypted Fallen trace recovered.

Rewards:
+80 RP
+1 Reinforcement Charge unlocked

Squad Status:
Marek wounded
No gene-seed lost
```

## Campaign Progression

### Mission Unlocks

Mission 1 unlocks:

- Reinforcement system.
- Dynamic cover interaction.
- One armory upgrade slot.

Mission 2 unlocks:

- Stealth-focused objectives.
- Auspex scan.
- Silent takedown.

Mission 3 unlocks:

- Terminator teleport support.
- Orbital strike.
- Boss fight.

## UI/UX Flow

### Before Mission

Player sees:

- Campaign name.
- Mission name.
- Commander portrait.
- Clear objectives.
- Initial squad.
- Reserve squad.
- Begin drop button.

### During Mission

Player sees:

- Current phase.
- Main objective.
- Secondary objective.
- Active marine.
- Current mode.
- Cover/stealth/reinforcement hints.
- Reinforcement availability.

### After Mission

Player sees:

- Outcome.
- Rewards.
- Losses.
- Campaign progress.
- Next mission tease.

## Data Model Đề Xuất

### Campaign

```dart
class Campaign {
  final String id;
  final String name;
  final String planet;
  final List<CampaignMission> missions;
}
```

### CampaignMission

```dart
class CampaignMission {
  final String id;
  final String operationName;
  final String publicBriefing;
  final String hiddenDirective;
  final String commanderPortrait;
  final String introCutsceneId;
  final String outroCutsceneId;
  final TacticalMap map;
  final List<MissionPhase> phases;
}
```

### MissionPhase

```dart
class MissionPhase {
  final String id;
  final String title;
  final String objectiveText;
  final MissionPhaseType type;
  final List<String> unlocks;
}
```

### Cutscene Definition

```dart
class CutsceneDefinition {
  final String id;
  final List<CutsceneBeat> beats;
  final bool skippable;
}
```

## Implementation Roadmap

### Phase 1 - Briefing Screen

- Tạo `MissionBriefingScreen`.
- Hiển thị commander portrait.
- Hiển thị operation name, objectives, hidden directive.
- Nút `Begin Drop`.

### Phase 2 - Intro Drop Cutscene

- Tạo `DropPodCutsceneScreen`.
- Animation drop pod đơn giản.
- Skip được.
- Sau cutscene push vào `CommandScreen`.

### Phase 3 - Larger Mission Map

- Tạo map mới `24x18` hoặc `24x20`.
- Generate image đúng size.
- Tạo tile mask tương ứng.
- Chuyển mission 1 sang map rộng.

### Phase 4 - Mission Phases

- Thêm state `missionPhaseIndex`.
- Objective thay đổi theo phase.
- Hoàn thành phase mở khóa reinforcement hoặc trigger enemy response.

### Phase 5 - End Cutscene

- Sau khi objective chính hoàn thành, trigger outro.
- Bản đầu dùng drop pod extraction.
- Bản sau thêm Terminator teleport outro.

### Phase 6 - Result Screen

- Tạo `MissionResultScreen`.
- Hiển thị RP, objective, wounded status, next unlock.

## Acceptance Criteria

- Mỗi mission có operation name rõ ràng.
- Trước mission có commander briefing.
- Người chơi biết mục tiêu chính trước khi vào map.
- Có cutscene drop pod trước gameplay.
- Map đủ rộng để chơi 15-30 phút.
- Mission có nhiều phase thay vì một objective đơn.
- Sau khi hoàn thành objective có outro cutscene.
- Result screen cho biết thành quả và phần thưởng.

## Mission 1 Vertical Slice Đề Xuất

### Operation Name

**Operation Iron Halo**

### Campaign

**The Obolus Prime Incursion**

### Commander

**Master Azael Vorn**

### Main Objective

Secure Drop Zone Epsilon and activate the orbital relay.

### Hidden Directive

Recover encrypted traffic connected to a possible Fallen signal.

### Starting Squad

- Cpt. Varro
- Iolan
- Marek
- Titus

### Reserve

- Soren
- Rusk
- Galen
- Nero
- Cassian
- Sevran

### Mission Phases

1. **Impact**
   - Drop pod lands.
   - Four marines deploy.

2. **Secure The Crater**
   - Clear first patrol.
   - Reach cover.

3. **Relay Advance**
   - Move to relay station.
   - Avoid or trigger alarm.

4. **Call Reinforcement**
   - Activate relay.
   - Deploy one reserve marine.

5. **Break The Beacon**
   - Destroy Ork command beacon.
   - Defeat Nob commander.

6. **Extraction**
   - Hold extraction zone.
   - Outro drop pod arrives.

### Outro Options

Bản đầu:

- Drop pod extraction.

Bản nâng cấp:

- If player completed hidden directive: Terminator teleport support appears.
- If player ignored hidden directive: emergency extraction under fire.

## Kết luận

Một màn chơi nên được đóng gói như một operation trong campaign, có briefing, cutscene, map lớn, phase objectives và outro. Cấu trúc này sẽ làm game có cảm giác hoàn chỉnh hơn nhiều, đồng thời giúp người chơi hiểu vì sao họ đang chiến đấu và mục tiêu tiếp theo là gì.
