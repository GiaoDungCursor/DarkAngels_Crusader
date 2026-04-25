from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance


TILE = 64
OUT_DIR = Path("assets/images")


MAPS = {
    "map_drop_zone_epsilon_generated.png": [
        "################",
        "#...vvv....CCEE#",
        "#SS..vv..C.....#",
        "#SS..bb..C..C..#",
        "#SS..bb.....C..#",
        "#SS..vv..C.....#",
        "#SS......C..O..#",
        "#....CC.....O..#",
        "#....CC..hhh...#",
        "#..C.....hhh...#",
        "#..C..bb.......#",
        "#.....bb..CC...#",
        "#..X......CC.EE#",
        "#..X..vv.......#",
        "#.....vv.......#",
        "################",
    ],
    "map_hive_gate_primus_generated.png": [
        "################",
        "#X...C...vv.EE.#",
        "#XSS.C...vv....#",
        "#SSS.C..bbb....#",
        "#SSS....bOb..C.#",
        "#SS.....bOb..C.#",
        "#...CC..bbb....#",
        "#...CC.....vv..#",
        "#.......C..vvE.#",
        "#..hhh..C......#",
        "#..hhh.....CC..#",
        "#......vv..CC..#",
        "#..C...vv......#",
        "#..C......bbbE.#",
        "#.........bbb..#",
        "################",
    ],
    "map_ash_basilica_generated.png": [
        "################",
        "#..vv....C..EE.#",
        "#SSvv....C.....#",
        "#SSbb..CC......#",
        "#SSbb..CC..h...#",
        "#SSvv......h...#",
        "#SSvv..####....#",
        "#......#OO#..E.#",
        "#..C...#OO#....#",
        "#..C...####.CC.#",
        "#......hhh..CC.#",
        "#..bbb.........#",
        "#..bbb.....E...#",
        "#XX.....vv.....#",
        "#XX.....vv.....#",
        "################",
    ],
}


PALETTE = {
    ".": ((54, 61, 67), (78, 87, 94)),
    "S": ((42, 64, 52), (66, 102, 76)),
    "E": ((74, 43, 39), (112, 58, 50)),
    "O": ((47, 72, 68), (35, 139, 103)),
    "X": ((64, 67, 54), (116, 102, 61)),
    "#": ((22, 26, 31), (42, 48, 54)),
    "v": ((5, 7, 11), (18, 10, 16)),
    "b": ((44, 47, 50), (77, 78, 74)),
    "C": ((36, 42, 48), (66, 72, 77)),
    "h": ((61, 28, 18), (160, 58, 24)),
}


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(lerp(c1[i], c2[i], t) for i in range(3))


def draw_floor(draw: ImageDraw.ImageDraw, x: int, y: int, ch: str, rng: random.Random) -> None:
    left = x * TILE
    top = y * TILE
    base, accent = PALETTE.get(ch, PALETTE["."])
    jitter = rng.random() * 0.32
    fill = mix(base, accent, jitter)
    draw.rectangle((left, top, left + TILE, top + TILE), fill=fill)
    inset = 5
    draw.rectangle(
        (left + inset, top + inset, left + TILE - inset, top + TILE - inset),
        outline=mix(fill, (110, 121, 126), 0.18),
        width=1,
    )
    if rng.random() < 0.55:
        yy = top + rng.randint(16, 48)
        draw.line((left + 8, yy, left + TILE - 8, yy), fill=mix(fill, (5, 7, 9), 0.35), width=1)
    if rng.random() < 0.35:
        xx = left + rng.randint(14, 50)
        draw.line((xx, top + 8, xx, top + TILE - 8), fill=mix(fill, (120, 130, 132), 0.15), width=1)


def draw_block(draw: ImageDraw.ImageDraw, x: int, y: int, rng: random.Random) -> None:
    left = x * TILE
    top = y * TILE
    draw.rectangle((left, top, left + TILE, top + TILE), fill=(13, 16, 20))
    draw.rectangle((left + 8, top + 8, left + TILE - 8, top + TILE - 8), fill=(25, 29, 33), outline=(73, 79, 82), width=2)
    for i in range(3):
        yy = top + 18 + i * 12
        draw.line((left + 13, yy, left + TILE - 13, yy), fill=(11, 13, 16), width=2)


def draw_void(draw: ImageDraw.ImageDraw, x: int, y: int, rng: random.Random) -> None:
    left = x * TILE
    top = y * TILE
    draw.rectangle((left, top, left + TILE, top + TILE), fill=(4, 6, 10))
    for i in range(5):
        y0 = top + rng.randint(0, TILE)
        draw.line((left, y0, left + TILE, y0 + rng.randint(-10, 10)), fill=(21, 9, 16), width=1)
    draw.rectangle((left + 2, top + 2, left + TILE - 2, top + TILE - 2), outline=(42, 20, 30), width=2)


def draw_bridge(draw: ImageDraw.ImageDraw, x: int, y: int, rng: random.Random) -> None:
    left = x * TILE
    top = y * TILE
    draw.rectangle((left, top, left + TILE, top + TILE), fill=(42, 45, 48))
    for i in range(0, TILE, 12):
        draw.line((left + i, top + 4, left + i - 18, top + TILE - 4), fill=(90, 91, 86), width=2)
    draw.rectangle((left + 4, top + 4, left + TILE - 4, top + TILE - 4), outline=(121, 118, 96), width=2)
    draw.line((left + 6, top + 12, left + TILE - 6, top + 12), fill=(142, 132, 74), width=2)
    draw.line((left + 6, top + TILE - 12, left + TILE - 6, top + TILE - 12), fill=(142, 132, 74), width=2)


def draw_cover(draw: ImageDraw.ImageDraw, x: int, y: int, rng: random.Random) -> None:
    draw_floor(draw, x, y, ".", rng)
    left = x * TILE
    top = y * TILE
    draw.rounded_rectangle((left + 10, top + 17, left + TILE - 10, top + TILE - 13), radius=4, fill=(45, 51, 58), outline=(138, 145, 150), width=2)
    for i in range(3):
        x0 = left + 15 + i * 13
        draw.polygon(
            [(x0, top + 45), (x0 + 7, top + 45), (x0 + 15, top + 31), (x0 + 8, top + 31)],
            fill=(216, 169, 58),
        )


def draw_hazard(draw: ImageDraw.ImageDraw, x: int, y: int, rng: random.Random) -> None:
    left = x * TILE
    top = y * TILE
    draw.rectangle((left, top, left + TILE, top + TILE), fill=(45, 24, 18))
    for i in range(4):
        yy = top + 10 + i * 12 + rng.randint(-2, 2)
        draw.line((left + 4, yy, left + TILE - 4, yy + rng.randint(-4, 4)), fill=(222, 82, 31), width=3)
    draw.rectangle((left + 3, top + 3, left + TILE - 3, top + TILE - 3), outline=(245, 139, 52), width=2)


def draw_marker(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int]) -> None:
    left = x * TILE
    top = y * TILE
    draw.rectangle((left + 18, top + 18, left + TILE - 18, top + TILE - 18), outline=color, width=3)
    draw.line((left + 26, top + TILE // 2, left + TILE - 26, top + TILE // 2), fill=color, width=2)
    draw.line((left + TILE // 2, top + 26, left + TILE // 2, top + TILE - 26), fill=color, width=2)


def render_map(name: str, layout: list[str]) -> None:
    rng = random.Random(name)
    width = len(layout[0]) * TILE
    height = len(layout) * TILE
    image = Image.new("RGB", (width, height), (10, 12, 15))
    draw = ImageDraw.Draw(image)

    for y, row in enumerate(layout):
        for x, ch in enumerate(row):
            if ch == "#":
                draw_block(draw, x, y, rng)
            elif ch == "v":
                draw_void(draw, x, y, rng)
            elif ch == "b":
                draw_bridge(draw, x, y, rng)
            elif ch == "C":
                draw_cover(draw, x, y, rng)
            elif ch == "h":
                draw_hazard(draw, x, y, rng)
            else:
                draw_floor(draw, x, y, ch, rng)
                if ch == "S":
                    draw_marker(draw, x, y, (79, 189, 122))
                elif ch == "E":
                    draw_marker(draw, x, y, (218, 80, 72))
                elif ch == "O":
                    draw_marker(draw, x, y, (51, 214, 166))
                elif ch == "X":
                    draw_marker(draw, x, y, (216, 169, 58))

    # Subtle pipes and cables across walkable areas for an industrial feel.
    for _ in range(18):
        y = rng.randrange(1, len(layout) - 1) * TILE + rng.randint(14, 50)
        x1 = rng.randint(0, width // 2)
        x2 = rng.randint(width // 2, width)
        color = rng.choice([(24, 37, 34), (55, 27, 25), (68, 72, 70)])
        draw.line((x1, y, x2, y + rng.randint(-16, 16)), fill=color, width=rng.randint(2, 4))

    # Final grid seams and vignette.
    for i in range(0, width + 1, TILE):
        draw.line((i, 0, i, height), fill=(13, 18, 24), width=1)
    for i in range(0, height + 1, TILE):
        draw.line((0, i, width, i), fill=(13, 18, 24), width=1)

    image = ImageEnhance.Brightness(image).enhance(1.35)
    image = ImageEnhance.Contrast(image).enhance(1.12)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(OUT_DIR / name)


def main() -> None:
    for name, layout in MAPS.items():
        render_map(name, layout)


if __name__ == "__main__":
    main()
