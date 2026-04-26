import os
import glob
import re

replacements = {
    "assets/images/armory_background.png": "assets/images/backgrounds/armory_background.png",
    "assets/images/main_menu_bg.png": "assets/images/backgrounds/main_menu_bg.png",
    "assets/images/drop_pod_landing_splash.png": "assets/images/backgrounds/drop_pod_landing_splash.png",
    "assets/images/hub_spaceship.png": "assets/images/backgrounds/hub_spaceship.png",

    "assets/images/shield_icon.png": "assets/images/ui/shield_icon.png",

    "assets/images/marine": "assets/images/sprites/marines/marine",
    "assets/images/enemy": "assets/images/sprites/enemies/enemy",
    "assets/images/bomb.png": "assets/images/sprites/objects/bomb.png",
    "assets/images/cover_obstacle.png": "assets/images/sprites/objects/cover_obstacle.png",
    "assets/images/drop_pod.png": "assets/images/sprites/objects/drop_pod.png",
    "assets/images/projectile.png": "assets/images/sprites/objects/projectile.png",

    "assets/images/map": "assets/images/maps/map",
    "assets/images/victory_cutscene_": "assets/images/cutscenes/victory_cutscene_",
    
    # Flame loadSprite uses paths relative to assets/images/
    "'marine_idle.png'": "'sprites/marines/marine_idle.png'",
    "'marine_walk.png'": "'sprites/marines/marine_walk.png'",
    "'marine_attack.png'": "'sprites/marines/marine_attack.png'",
    "'marine_dead.png'": "'sprites/marines/marine_dead.png'",
    
    "'enemy_idle.png'": "'sprites/enemies/enemy_idle.png'",
    "'enemy_walk.png'": "'sprites/enemies/enemy_walk.png'",
    "'enemy_attack.png'": "'sprites/enemies/enemy_attack.png'",
    "'enemy_dead.png'": "'sprites/enemies/enemy_dead.png'",
    
    "'enemy_base.png'": "'sprites/objects/enemy_base.png'",
    "'bomb.png'": "'sprites/objects/bomb.png'",
    "'drop_pod.png'": "'sprites/objects/drop_pod.png'",
    "'projectile.png'": "'sprites/objects/projectile.png'",
    
    # For TacticalMap background path
    "'map_drop_zone_epsilon_generated.png'": "'maps/map_drop_zone_epsilon_generated.png'",
    "'map_hive_gate_primus_generated.png'": "'maps/map_hive_gate_primus_generated.png'",
    "'map_ash_basilica_generated.png'": "'maps/map_ash_basilica_generated.png'"
}

dart_files = glob.glob('d:/Game_Code/lib/**/*.dart', recursive=True)
for file_path in dart_files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {file_path}")

print("Done updating Dart files.")
