"""Definitions: resources & objects untuk Pixel Galaxy World."""
import os
from gd_lib import sprite_object, animation, sprite_frame, text_object, obj_var, behavior

_HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(_HERE, "..", "project", "resources")

def scan_resources():
    """Scan semua PNG di resources → entri resource GDevelop."""
    out = []
    for root, _, files in os.walk(RES):
        for f in sorted(files):
            if not f.endswith(".png"):
                continue
            rel = os.path.relpath(os.path.join(root, f), os.path.join(_HERE, "..", "project")).replace("\\", "/")
            out.append({
                "alwaysLoaded": True, "file": rel, "kind": "image", "metadata": "",
                "name": f, "smoothed": False, "userAdded": True})
    return out

# ---------- frame lists ----------
def frames(prefix, n, w, h):
    return [sprite_frame(f"{prefix}-{i}.png", w, h) for i in range(n)]

def static(image, w, h):
    return [sprite_frame(image, w, h)]

# ---------- karakter kolonis ----------
def colonist(name, idle_img):
    return sprite_object(
        name,
        [animation(frames(name.lower(), 4, 32, 48), name="walk", looping=True, time_between=0.15),
         animation(static(idle_img, 32, 48), name="idle"),
         animation(static(name.lower() + "-5.png", 32, 48), name="attack"),
         animation(static(name.lower() + "-4.png", 32, 48), name="work")],
        variables=[obj_var("hp", 100), obj_var("hunger", 100), obj_var("sleep", 100),
                   obj_var("mood", 100), obj_var("speed", 120), obj_var("state", "idle"),
                   obj_var("jobTargetX", -9999), obj_var("jobTargetY", -9999),
                   obj_var("jobType", "none"), obj_var("jobNode", "none"),
                   obj_var("isSelected", 0),
                   obj_var("isDown", 0), obj_var("name", name)])

# ---------- monster ----------
def monster(name, hp, dmg, speed):
    return sprite_object(
        name,
        [animation(frames(name.lower(), 4, 64, 64), name="move", looping=True, time_between=0.2),
         animation(frames(name.lower(), 2, 64, 64), name="attack", time_between=0.15)],
        variables=[obj_var("hp", hp), obj_var("dmg", dmg), obj_var("speed", speed),
                   obj_var("state", "roam")])

def all_objects():
    objects = []
    # --- kolonis ---
    objects.append(colonist("Rex", "rex-4.png"))
    objects.append(colonist("Luna", "luna-4.png"))
    objects.append(colonist("Bolt", "bolt-4.png"))
    # --- monster ---
    objects.append(monster("Slime", 40, 5, 60))
    objects.append(monster("Zapper", 30, 8, 90))
    objects.append(monster("Golem", 150, 15, 40))
    objects.append(monster("Stalker", 80, 20, 100))
    objects.append(monster("Bat", 25, 6, 110))
    # --- resource nodes ---
    for nm, img, res, amt in [("Tree", "item-0.png", "wood", 5),
                              ("Rock", "item-1.png", "stone", 5),
                              ("MetalOre", "item-2.png", "metal", 4),
                              ("CrystalVein", "item-3.png", "crystal", 3),
                              ("BerryBush", "item-4.png", "food", 4)]:
        objects.append(sprite_object(
            nm, [animation(static(img, 48, 48), name="default")],
            variables=[obj_var("resource", res), obj_var("amount", amt), obj_var("isHarvested", 0)]))
    # --- bangunan ---
    builds = [("WallWood", "building-10.png", "wall", "wood", 5),
              ("WallStone", "building-1.png", "wall", "stone", 5),
              ("Door", "building-12.png", "door", "wood", 3),
              ("Bed", "building-13.png", "bed", "wood", 6),
              ("Table", "building-14.png", "table", "wood", 4),
              ("Campfire", "building-0.png", "heat", "wood", 4),
              ("FarmPlot", "building-20.png", "farm", "wood", 3),
              ("SolarPanel", "building-3.png", "energy", "metal", 8),
              ("Turret", "building-5.png", "defense", "metal", 10),
              ("Lamp", "building-15.png", "light", "metal", 4),
              ("Stove", "building-17.png", "cook", "metal", 5),
              ("ResearchBench", "building-18.png", "research", "wood", 8)]
    for nm, img, cat, res, cost in builds:
        objects.append(sprite_object(
            nm, [animation(static(img, 64, 64), name="default")],
            variables=[obj_var("category", cat), obj_var("cost", cost),
                       obj_var("costRes", res), obj_var("isBuilt", 1), obj_var("isBlueprint", 0)]))
    # --- crash pod (landmark start) ---
    objects.append(sprite_object(
        "CrashPod", [animation(static("building-9.png", 96, 96), name="default")],
        variables=[obj_var("isScavenged", 0)]))
    # --- item drop ---
    objects.append(sprite_object(
        "ItemDrop", [animation(static("item-9.png", 24, 24), name="default")],
        variables=[obj_var("resType", "wood"), obj_var("amount", 1)]))
    # --- projectile turret ---
    objects.append(sprite_object(
        "Bullet", [animation(static("fx-6.png", 16, 16), name="default")],
        variables=[obj_var("dmg", 10)]))
    # --- efek ---
    objects.append(sprite_object(
        "FXExplosion", [animation(frames("fx", 4, 48, 48), name="boom", time_between=0.1)]))
    objects.append(sprite_object(
        "FXHit", [animation(frames("fx", 2, 48, 48), name="hit", time_between=0.1)]))
    # --- ground tiles (Sprite sederhana, bukan tilemap agar simpel di mobile) ---
    objects.append(sprite_object(
        "TileGrass", [animation(static("grass.png", 32, 32), name="default")], collision_auto=False))
    objects.append(sprite_object(
        "TileDirt", [animation(static("dirt.png", 32, 32), name="default")], collision_auto=False))
    # --- UI objects ---
    objects.append(sprite_object(
        "UIButton", [animation(static("ui-1.png", 48, 48), name="default")],
        variables=[obj_var("btnId", "")]))
    objects.append(sprite_object(
        "UIPortrait", [animation(static("ui-2.png", 48, 48), name="default")],
        variables=[obj_var("owner", "")]))
    objects.append(sprite_object(
        "UIPanel", [animation(static("ui-0.png", 256, 96), name="default")], collision_auto=False))
    objects.append(sprite_object(
        "UIIcon", [animation(static("ui-14.png", 24, 24), name="default")],
        variables=[obj_var("iconId", "")]))
    # --- tombol sprite (icons: pause=ui-6, play=ui-7, fast=ui-5, hammer/build=ui-15, panel=ui-0) ---
    # frame w/h = ukuran native gambar; scaling via customSize instance.
    def button(name, img, w, h):
        return sprite_object(
            name, [animation(static(img, w, h), name="default")],
            variables=[obj_var("btnId", name)])
    objects.append(button("BtnStart", "ui-0.png", 96, 46))
    objects.append(button("BtnQuit", "ui-0.png", 96, 46))
    objects.append(button("BtnRetry", "ui-0.png", 96, 46))
    objects.append(button("BtnPause", "ui-6.png", 96, 89))
    objects.append(button("BtnPlay", "ui-7.png", 96, 89))
    objects.append(button("BtnFast", "ui-5.png", 96, 90))
    objects.append(button("BtnBuild", "ui-15.png", 96, 93))
    # --- text objects ---
    objects.append(text_object("TextDay", "Hari 1", 16, (255, 255, 255)))
    objects.append(text_object("TextRes", "Kayu 0  Batu 0  Logam 0  Makanan 0", 14, (255, 220, 100)))
    objects.append(text_object("TextAlert", "", 18, (255, 80, 80)))
    objects.append(text_object("TextNeeds", "", 12, (200, 230, 255)))
    objects.append(text_object("TextTitle", "PIXEL GALAXY WORLD", 32, (255, 230, 90)))
    objects.append(text_object("TextSub", "Koloni Pixel di Planet Kepler-Pixel 7", 14, (180, 200, 230)))
    objects.append(text_object("TextBtnStart", "MULAI PERMAINAN", 20, (255, 255, 255)))
    objects.append(text_object("TextBtnQuit", "KELUAR", 16, (220, 220, 220)))
    objects.append(text_object("TextGameOver", "KOLONI HANCUR", 32, (255, 90, 90)))
    objects.append(text_object("TextGoStat", "", 16, (240, 240, 240)))
    objects.append(text_object("TextGoBtn", "MAIN LAGI", 20, (255, 255, 255)))
    objects.append(text_object("TextMenuBG", "", 1, (255, 255, 255)))
    # --- background menu (sprite besar) ---
    objects.append(sprite_object(
        "MenuBackground", [animation(static("menu-background.png", 909, 513), name="default")],
        collision_auto=False))
    objects.append(sprite_object(
        "TitleArt", [animation(static("title-art.png", 909, 513), name="default")],
        collision_auto=False))
    objects.append(sprite_object(
        "NightOverlay", [animation(static("night-overlay.png", 32, 32), name="default")], collision_auto=False))
    objects.append(sprite_object(
        "BuildGhost", [animation(static("building-10.png", 64, 64), name="default")],
        variables=[obj_var("buildType", "WallWood")]))
    return objects

# behaviorsSharedData standar (semua scene butuh ini utk Text/Sprite capabilities)
SHARED_BEHAVIORS = [
    {"name": "Animation", "type": "AnimatableCapability::AnimatableBehavior"},
    {"name": "Effect", "type": "EffectCapability::EffectBehavior"},
    {"name": "Flippable", "type": "FlippableCapability::FlippableBehavior"},
    {"name": "Opacity", "type": "OpacityCapability::OpacityBehavior"},
    {"name": "Resizable", "type": "ResizableCapability::ResizableBehavior"},
    {"name": "Scale", "type": "ScalableCapability::ScalableBehavior"},
    {"name": "Text", "type": "TextContainerCapability::TextContainerBehavior"},
]
