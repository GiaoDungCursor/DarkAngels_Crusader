# Veo 3 Cutscene Prompts - Operation Iron Halo

## Mục Đích

File này là bản prompt chuẩn để copy vào Google Veo 3 / Flow / Gemini Video.

Ba phần cinematic cần tạo:

1. **Commander Portrait** - ảnh tĩnh của chỉ huy cho màn mission briefing.
2. **Orbital Drop Gameplay Intro** - drop pod lao từ quỹ đạo xuống Drop Zone Epsilon, cửa mở, 4 marine bước ra.
3. **Mission Outro** - hoàn thành mục tiêu, Terminator teleport xuống cover hoặc drop pod extraction.

Lưu ý:

- Prompt cố tình dùng mô tả **original gothic sci-fi** thay vì yêu cầu logo/biểu tượng chính thức.
- Không yêu cầu official insignia, chapter logo, trademarked emblem.
- Briefing không cần video. Chỉ cần portrait + text dialogue click qua từng dòng.
- Nên tạo mỗi video cutscene thành clip 8 giây trước, sau đó nối trong editor.
- Nếu Veo/Flow cho chọn model, ưu tiên Veo 3.1 hoặc Veo 3 Fast tùy credit.

## Style Bible Chung

Dùng chung cho cả 3 prompt nếu cần:

```text
Original gothic sci-fi tactical war game cinematic, grim military tone, dark green and antique gold color accents, monastic armored super-soldiers, industrial forge-hive world, smoke, sparks, tactical holograms, heavy armor, no official logos, no copyrighted insignia, no readable brand names, cinematic 16:9 composition, high contrast lighting, realistic camera movement, native sound effects, no subtitles unless requested.
```

## Asset 01 - Commander Portrait For Briefing

### Mục Tiêu

Tạo ảnh portrait tĩnh của chỉ huy để dùng trong màn mission briefing.

Flow trong game:

```text
Mission Briefing Screen
  -> Commander portrait lớn ở trên hoặc bên trái
  -> Dialogue text hiện ở dưới
  -> User click để qua từng dòng thoại
  -> Sau dòng cuối, nút Begin Drop
  -> Chuyển sang orbital drop cutscene
```

### Nội Dung Cần Đúng

- Campaign: **The Obolus Prime Incursion**
- Mission: **Operation Iron Halo**
- Chỉ huy giao nhiệm vụ bằng giọng lạnh, bí mật.
- Nêu rõ:
  - Secure Drop Zone Epsilon.
  - Activate orbital relay.
  - Recover encrypted trace connected to a hidden traitor signal.
- Tone: chiến dịch quân sự bí mật, nghiêm trọng.

### Image Prompt

```text
Create a portrait image for an original gothic sci-fi tactical war game mission briefing.

Subject: stern armored commander, middle-aged, severe expression, monastic military presence, dark green and antique gold armor accents, hooded command cloak, subtle battle scars, standing inside a dark warship strategium.

Background: gothic starship command chamber, green tactical hologram glow, brass machinery, cathedral-like arches, distant planet visible through armored viewport.

Composition: vertical portrait, waist-up, commander centered, enough dark negative space near bottom for dialogue UI overlay if needed.

Mood: secretive, disciplined, grim, ceremonial, military.

Style: polished game character portrait, semi-realistic painterly sci-fi, high contrast lighting, dark green and antique gold palette.

Constraints: original design, no official logos, no copyrighted insignia, no readable brand names, no text, no watermark.
```

### Negative Prompt

```text
No modern soldiers, no contemporary military uniforms, no official Warhammer logos, no chapter symbols, no readable real-world text, no cartoon style, no anime style, no comedy, no bright clean sci-fi, no text, no watermark.
```

### Briefing Text Trong Game

Gợi ý dialogue click-through:

```text
MASTER AZAEL VORN:
"Operation Iron Halo begins now."

"Drop Zone Epsilon is lost. You will land with four battle-brothers and secure the relay."

"The public objective is simple: restore orbital coordination and break the enemy beachhead."

"The true directive is not. Recover the encrypted trace before anyone else understands what it is."

"When the pod opens, move fast. Cover will keep you alive. The relay will bring your brothers down."
```

## Cutscene 02 - Orbital Drop Gameplay Intro

### Mục Tiêu Cảnh

Chuyển từ briefing sang hành động: drop pod lao từ quỹ đạo xuống hành tinh, impact vào map, cửa mở, 4 marine bước ra.

### Nội Dung Cần Đúng

- Tàu chiến ở quỹ đạo.
- Drop pod phóng xuống.
- Cháy khi xuyên khí quyển.
- Impact mạnh xuống khu công nghiệp.
- Bụi/khói/tia lửa.
- Cửa pod mở.
- 4 marine đầu tiên bước ra thành đội hình nhỏ.
- Cảm giác chuẩn bị vào gameplay.

### Veo 3 Prompt

```text
Create an 8-second cinematic orbital drop sequence for an original gothic sci-fi tactical war game.

Scene: a massive gothic warship in orbit above a burning industrial forge-hive world. The planet below is covered in city lights, smoke, fires, and storm clouds.

Action: a heavy armored drop pod launches from the warship, tumbles slightly, then burns through the atmosphere with a bright orange plasma trail. The camera follows the pod downward through clouds and ash. The pod slams into an industrial landing zone, creating a shockwave, sparks, dust, and smoke. End on the pod embedded in the ground, door mechanisms beginning to unlock.

Final beat: the pod door opens through steam and four armored super-soldiers step out in disciplined formation, weapons ready, surrounded by smoke and impact debris.

Mood: violent, heroic, heavy, urgent, cinematic.

Visual constraints: original gothic sci-fi drop pod design, no official logos, no copyrighted insignia, no real-world flags, no readable brand names.

Camera: 16:9 cinematic, starts wide in orbit, dynamic tracking shot during descent, impact shake at landing, final close-up on the pod.

Audio: deep launch boom, roaring atmospheric burn, metal stress, heavy impact, dust and debris, mechanical pod locks, heavy boots stepping onto metal.
```

### Negative Prompt

```text
No sleek clean NASA capsule, no modern rocket, no fantasy dragon, no official franchise emblems, no text overlays, no cartoon style, no low-impact landing, no silent video.
```

## Cutscene 03A - Mission Outro: Terminator Teleport

### Mục Tiêu Cảnh

Sau khi objective hoàn thành, Deathwing-style heavy support teleport xuống sau cover để chặn counterattack.

### Nội Dung Cần Đúng

- Objective complete.
- Enemy counterattack sắp tới.
- Teleport homer sáng lên sau cover.
- Terminator-style armored warrior xuất hiện trong ánh chớp.
- Giơ shield hoặc bắn để bảo vệ squad.
- Fade sang result screen.

### Veo 3 Prompt

```text
Create an 8-second cinematic mission outro for an original gothic sci-fi tactical war game.

Scene: a ruined industrial battlefield at night, with heavy cover blocks, cracked metal flooring, smoke, sparks, and distant enemy silhouettes advancing. The main objective has just been completed.

Action: a small teleport beacon behind cover begins pulsing green and gold. Lightning arcs across the battlefield. A massive elite armored warrior in bone-colored terminator-style armor materializes behind the cover, one arm raising a heavy shield while the other aims a storm-like firearm. He fires a short burst toward the approaching enemy silhouettes, protecting the withdrawing squad.

Mood: triumphant, heavy, sacred, intimidating, last-second rescue.

Visual constraints: original heavy armored knight-like sci-fi design, no official logos, no copyrighted insignia, no readable brand names, no gore.

Camera: 16:9 cinematic, low angle from behind cover, flash frame during teleport, slow reveal of the armored warrior, smoke and sparks drifting.

Audio: teleport charge, electric crack, deep armor impact, heavy weapon burst, distant enemy roar fading out.
```

### Negative Prompt

```text
No magic wizard portal, no fantasy armor, no official franchise symbols, no clean white sci-fi lab, no comedy, no readable text, no excessive gore, no civilian crowd.
```

## Cutscene 03B - Mission Outro: Drop Pod Extraction

### Mục Tiêu Cảnh

Phiên bản outro thay thế nếu muốn kết thúc bằng extraction thay vì teleport.

### Nội Dung Cần Đúng

- Objective complete.
- Extraction beacon confirmed.
- Drop pod hoặc extraction craft hạ xuống trong khói.
- Marine rút lui vào extraction zone.
- Door đóng lại, fade out.

### Veo 3 Prompt

```text
Create an 8-second cinematic extraction outro for an original gothic sci-fi tactical war game.

Scene: an industrial battlefield after a completed objective. Smoke rolls across metal flooring, warning lights flash, and distant enemies fire from the haze.

Action: an extraction beacon activates on the ground. A heavy armored drop pod descends through smoke with retro thrusters firing. Four armored super-soldiers withdraw toward it in disciplined formation, one covering the rear. The pod door opens with steam, the squad enters, and the door slams shut as tracer fire crosses the smoke.

Mood: tense victory, disciplined retreat, grim military success.

Visual constraints: original gothic sci-fi armor and extraction pod, no official logos, no copyrighted insignia, no readable brand names, no gore.

Camera: 16:9 cinematic, medium-wide battlefield shot, slight handheld impact shake as the pod lands, final close-up on door locking.

Audio: extraction beacon ping, thrusters, steam release, heavy boots, distant gunfire, metal door slam.
```

### Negative Prompt

```text
No helicopter, no modern aircraft, no clean spaceship interior, no official emblems, no readable text overlays, no comedy, no cartoon style.
```

## Khuyến Nghị Tạo Video

### Nếu Tạo Trong Google Flow

- Tạo từng scene riêng.
- Dùng cùng style bible để giữ nhất quán.
- Nếu Flow có scene extension, dùng clip 02 nối từ clip 01.
- Nên tạo vài variant cho cutscene 02 vì drop pod impact dễ bị sai scale.

### Nếu Tạo Trong Gemini Video

- Dán từng prompt riêng.
- Nếu có lựa chọn video/audio, bật audio.
- Nếu có image-to-video, có thể dùng ảnh concept của game làm reference trước.

### Thứ Tự Nên Tạo

1. Asset 01 - Commander Portrait trước, vì briefing UI cần ảnh.
2. Cutscene 02 - Orbital Drop Gameplay Intro, vì đây là cảnh video quan trọng nhất.
3. Chọn một trong hai outro:
   - 03A nếu muốn kết thúc hoành tráng bằng Terminator teleport.
   - 03B nếu muốn kết thúc rõ gameplay bằng extraction.

## Link Chính Thức Để Tạo Video

- Google Flow: https://labs.google/flow/about
- Gemini Video Generation: https://gemini.google/overview/video-generation/
- Gemini App: https://gemini.google.com/
- Gemini API Video Docs: https://ai.google.dev/gemini-api/docs/video

Nếu chỉ gen portrait chỉ huy, dùng công cụ image generation bất kỳ hoặc Gemini image generation. Veo/Flow dùng cho video orbital drop và outro.

## Ghi Chú Sản Xuất

Veo thường làm tốt hơn nếu prompt có:

- Scene rõ.
- Action rõ.
- Camera rõ.
- Audio rõ.
- Negative constraints rõ.

Tránh prompt quá dài về lore. Lore nên chuyển thành hình ảnh và hành động cụ thể.

## Checklist Duyệt Kết Quả

Sau khi tạo video, kiểm tra:

- Có đúng tone gothic sci-fi quân sự không?
- Có tránh official logo/symbol không?
- Portrait chỉ huy có đủ nghiêm, bí mật, gothic sci-fi không?
- Briefing text trong game có đọc được từng dòng khi user click không?
- Cutscene 02 có drop pod từ orbit xuống impact và 4 marine bước ra không?
- Cutscene 03A có teleport xuống cover không?
- Cutscene 03B có extraction pod và squad rút lui không?
- Audio có khớp hành động không?
- Video có dùng được làm intro/outro trong game không?
