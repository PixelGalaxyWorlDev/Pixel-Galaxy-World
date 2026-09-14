"""Scenes & events untuk Pixel Galaxy World.

Format semua instruksi terverifikasi dari:
- contoh resmi GDevelop (asteroids, rts, camera, flash-object, quiz)
- source engine: BaseObjectExtension.cpp, VariablesExtension.cpp,
  SceneExtension.cpp, TimeExtension.cpp, MouseExtension.cpp,
  AnimatableExtension.cpp
"""
import random
from gd_lib import cond, act, ev, comment, group, once, instance, layer

W, H = 909, 513               # resolusi dasar landscape mobile
WORLD_W, WORLD_H = 3200, 1800  # ukuran dunia (tiles 32px)
TILE = 32

COLONISTS = ["Rex", "Luna", "Bolt"]
MONSTERS = ["Slime", "Zapper", "Golem", "Stalker", "Bat"]


# ============================ helpers ============================
def _set_anim(obj, anim):
    """Set animasi by name — terverifikasi: [obj, "Animation", "=", "\"name\""]"""
    return act("AnimatableCapability::AnimatableBehavior::SetName",
               [obj, "Animation", "=", f"\"{anim}\""])


def _pick_all(obj):
    return cond("PickAllInstances", [obj, ""])


def _assign_job(target, job):
    """Kolonis TERPILIH (isSelected=1) menuju node `target` dengan pekerjaan `job`.

    Sub-event per kolonis: set jobType (teks), jobNode (teks),
    dan jobTargetX/Y = posisi node yang di-tap.
    """
    out = []
    for c in COLONISTS:
        out.append(ev(
            [cond("VarObjet", [c, "isSelected", "=", "1"]),
             cond("VarObjet", [c, "isDown", "=", "0"])],
            [
                act("ModVarObjetTxt", [c, "jobType", "=", f"\"{job}\""]),
                act("ModVarObjetTxt", [c, "jobNode", "=", f"\"{target}\""]),
                act("ModVarObjet", [c, "jobTargetX", "=", f"{target}.X()"]),
                act("ModVarObjet", [c, "jobTargetY", "=", f"{target}.Y()"]),
            ]))
    return out


def _attack_job(who, m):
    """Return list of sub-events: kolonis terpilih menyerang monster m."""
    return [ev([], [
        act("ModVarObjetTxt", [who, "jobType", "=", "\"attack\""]),
        act("ModVarObjetTxt", [who, "jobNode", "=", f"\"{m}\""]),
        act("ModVarObjet", [who, "jobTargetX", "=", f"{m}.X()"]),
        act("ModVarObjet", [who, "jobTargetY", "=", f"{m}.Y()"]),
    ])]


def _harvest_event(who, node):
    """Kolonis dekat node + timer kerja 1.2s → ambil resource."""
    job = {"Tree": "chop", "Rock": "mine", "MetalOre": "mine",
           "CrystalVein": "mine", "BerryBush": "harvest"}[node]
    timer_name = f"work_{who}{node}"
    main = ev([
        cond("VarObjetTxt", [who, "jobType", "=", f"\"{job}\""]),
        cond("VarObjetTxt", [who, "jobNode", "=", f"\"{node}\""]),
        cond("Distance", [who, node, "45", ""]),
        cond("VarObjet", [node, "isHarvested", "=", "0"]),
        cond("VarScene", ["IsPaused", "=", "0"]),
        cond("Timer", ["", "1.2", f"\"{timer_name}\""]),
    ], [
        act("ResetTimer", ["", f"\"{timer_name}\""]),
        act("ModVarObjet", [node, "amount", "-", "1"]),
        _res_gain_action(node),
        act("ModVarObjet", [who, "mood", "+", "1"]),
        _set_anim(who, "idle"),
    ])
    # sub-event: node habis → delete + kolonis berhenti
    main["events"] = [ev([
        cond("VarObjet", [node, "amount", "<=", "0"]),
    ], [
        act("ModVarObjet", [node, "isHarvested", "=", "1"]),
        act("Delete", [node, ""]),
        act("ModVarObjetTxt", [who, "jobType", "=", "\"none\""]),
        act("ModVarObjetTxt", [who, "jobNode", "=", "\"none\""]),
        act("ModVarObjet", [who, "jobTargetX", "=", "-9999"]),
        act("ModVarObjet", [who, "jobTargetY", "=", "-9999"]),
    ])]
    return main


def _res_gain_action(node):
    mapping = {"Tree": ("Wood", 2), "Rock": ("Stone", 2), "MetalOre": ("Metal", 1),
               "CrystalVein": ("Crystal", 1), "BerryBush": ("Food", 2)}
    var, amt = mapping[node]
    return act("ModVarScene", [var, "+", str(amt)])


def _monster_ai(m):
    """Monster kejar kolonis hidup terdekat (AddForceTowardObject)."""
    return ev([
        cond("VarScene", ["IsPaused", "=", "0"]),
    ], [
    ], events=[
        ev([cond("VarObjet", ["Rex", "isDown", "=", "0"])], [
            act("AddForceTowardObject", [m, "Rex", f"{m}.Variable(speed)", "1"]),
            _set_anim(m, "move"),
        ]),
        ev([cond("VarObjet", ["Rex", "isDown", "=", "1"]),
            cond("VarObjet", ["Luna", "isDown", "=", "0"])], [
            act("AddForceTowardObject", [m, "Luna", f"{m}.Variable(speed)", "1"]),
        ]),
        ev([cond("VarObjet", ["Rex", "isDown", "=", "1"]),
            cond("VarObjet", ["Luna", "isDown", "=", "1"]),
            cond("VarObjet", ["Bolt", "isDown", "=", "0"])], [
            act("AddForceTowardObject", [m, "Bolt", f"{m}.Variable(speed)", "1"]),
        ]),
    ])


def _monster_attack(m):
    """Tabrakan monster dengan kolonis + timer 1s → damage."""
    out = [comment(f"serangan {m}")]
    for c in COLONISTS:
        out.append(ev([
            cond("CollisionNP", [m, c, "", ""]),
            cond("VarObjet", [c, "isDown", "=", "0"]),
            cond("Timer", ["", "1", f"\"atk_{m}{c}\""]),
        ], [
            act("ResetTimer", ["", f"\"atk_{m}{c}\""]),
            act("ModVarObjet", [c, "hp", "-", f"{m}.Variable(dmg)"]),
            act("Create", ["", "FXHit", f"{c}.X()", f"{c}.Y()", "\"\""]),
        ]))
    return out


def _colonist_attack(who):
    """Kolonis dengan jobType=attack dekat monster → damage tick."""
    return ev([
        cond("VarObjetTxt", [who, "jobType", "=", "\"attack\""]),
        cond("VarObjet", [who, "isDown", "=", "0"]),
        cond("VarScene", ["IsPaused", "=", "0"]),
    ], [
        _set_anim(who, "attack"),
    ], events=[
        _colonist_attack_target(who, "Slime"),
        _colonist_attack_target(who, "Zapper"),
        _colonist_attack_target(who, "Golem"),
        _colonist_attack_target(who, "Stalker"),
        _colonist_attack_target(who, "Bat"),
    ])


def _colonist_attack_target(who, m):
    return ev([
        cond("VarObjetTxt", [who, "jobNode", "=", f"\"{m}\""]),
        cond("Distance", [who, m, "50", ""]),
        cond("Timer", ["", "0.8", f"\"catk_{who}{m}\""]),
    ], [
        act("ResetTimer", ["", f"\"catk_{who}{m}\""]),
        act("ModVarObjet", [m, "hp", "-", "12"]),
        act("Create", ["", "FXHit", f"{m}.X()", f"{m}.Y()", "\"\""]),
    ], events=[
        ev([cond("VarObjet", [m, "hp", "<=", "0"])], [
            act("Create", ["", "FXExplosion", f"{m}.X()", f"{m}.Y()", "\"\""]),
            act("Delete", [m, ""]),
            act("ModVarObjetTxt", [who, "jobType", "=", "\"none\""]),
            act("ModVarObjetTxt", [who, "jobNode", "=", "\"none\""]),
        ]),
    ])


def _needs_update():
    """Needs kolonis turun perlahan (dinormalisasi GameSpeed)."""
    out = []
    for c in COLONISTS:
        out.append(ev([
            cond("VarObjet", [c, "isDown", "=", "0"]),
            cond("VarScene", ["IsPaused", "=", "0"]),
        ], [
            act("ModVarObjet", [c, "hunger", "-", "0.3 * TimeDelta() * Variable(GameSpeed)"]),
            act("ModVarObjet", [c, "sleep", "-", "0.2 * TimeDelta() * Variable(GameSpeed)"]),
            act("ModVarObjet", [c, "mood", "-", "0.1 * TimeDelta() * Variable(GameSpeed)"]),
        ]))
    return out


def _auto_eat():
    """Hunger < 30 & Food > 0 → makan (+50 hunger)."""
    out = [comment("hunger < 30 & ada makanan → makan (restore hunger, konsumsi food)")]
    for c in COLONISTS:
        out.append(ev([
            cond("VarObjet", [c, "hunger", "<", "30"]),
            cond("VarScene", ["Food", ">", "0"]),
            once(),
        ], [
            act("ModVarObjet", [c, "hunger", "+", "50"]),
            act("ModVarScene", ["Food", "-", "1"]),
        ]))
    return out


def _settle_down():
    """Malam hari & tak ada job → tidur pulihkan sleep & mood."""
    out = [comment("malam hari & tanpa job → tidur pulihkan sleep & mood")]
    for c in COLONISTS:
        out.append(ev([
            cond("VarScene", ["TimeOfDay", ">", "0.8"]),
            cond("VarObjetTxt", [c, "jobType", "=", "\"none\""]),
            cond("VarObjet", [c, "isDown", "=", "0"]),
        ], [
            act("ModVarObjet", [c, "sleep", "+", "5 * TimeDelta() * Variable(GameSpeed)"]),
            act("ModVarObjet", [c, "mood", "+", "2 * TimeDelta() * Variable(GameSpeed)"]),
        ]))
    return out


def _death_check():
    """hp <= 0 → tumbang. Semua tumbang → game over."""
    out = [comment("hp <= 0 → down")]
    for c in COLONISTS:
        out.append(ev([
            cond("VarObjet", [c, "hp", "<=", "0"]),
            cond("VarObjet", [c, "isDown", "=", "0"]),
        ], [
            act("ModVarObjet", [c, "isDown", "=", "1"]),
            act("ModVarObjetTxt", [c, "jobType", "=", "\"none\""]),
            act("TextObject::String", ["TextAlert", "=", f"\"{c} tumbang!\""]),
        ]))
    out.append(comment("semua down → game over"))
    out.append(ev([
        cond("VarObjet", ["Rex", "isDown", "=", "1"]),
        cond("VarObjet", ["Luna", "isDown", "=", "1"]),
        cond("VarObjet", ["Bolt", "isDown", "=", "1"]),
        once(),
    ], [
        act("Wait", ["2"]),
        act("Scene", ["", "\"GameOver\"", "true"]),
    ]))
    return out


def _win_check():
    """Bertahan sampai hari 30 → menang."""
    out = [comment("bertahan sampai Day >= 30 → menang")]
    out.append(ev([
        cond("VarScene", ["Day", ">=", "30"]),
        once(),
    ], [
        act("ModVarScene", ["WinFlag", "=", "1"]),
        act("Wait", ["1"]),
        act("Scene", ["", "\"GameOver\"", "true"]),
    ]))
    return out


def _hud_update():
    """HUD teks tiap frame."""
    return [
        ev([], [
            act("TextObject::String", ["TextRes", "=",
                "\"Kayu \" + ToString(Variable(Wood)) + \"  Batu \" + ToString(Variable(Stone)) + \"  Logam \" + ToString(Variable(Metal)) + \"  Makanan \" + ToString(Variable(Food))"]),
            act("TextObject::String", ["TextDay", "=",
                "\"Hari \" + ToString(Variable(Day)) + \" - \" + ToString(round(Variable(TimeOfDay) * 24)) + \":00"]),
        ]),
        ev([cond("VarObjet", ["Rex", "isSelected", "=", "1"])], [
            act("TextObject::String", ["TextNeeds", "=",
                "\"Rex  HP:\" + ToString(Rex.Variable(hp)) + \"  Lapar:\" + ToString(Rex.Variable(hunger)) + \"  Tidur:\" + ToString(Rex.Variable(sleep))"]),
        ]),
        ev([cond("VarObjet", ["Luna", "isSelected", "=", "1"])], [
            act("TextObject::String", ["TextNeeds", "=",
                "\"Luna  HP:\" + ToString(Luna.Variable(hp)) + \"  Lapar:\" + ToString(Luna.Variable(hunger)) + \"  Tidur:\" + ToString(Luna.Variable(sleep))"]),
        ]),
        ev([cond("VarObjet", ["Bolt", "isSelected", "=", "1"])], [
            act("TextObject::String", ["TextNeeds", "=",
                "\"Bolt  HP:\" + ToString(Bolt.Variable(hp)) + \"  Lapar:\" + ToString(Bolt.Variable(hunger)) + \"  Tidur:\" + ToString(Bolt.Variable(sleep))"]),
        ]),
    ]


# ============================ MAIN MENU ============================
def main_menu_scene():
    events = [
        ev([cond("SceneJustBegins", [""])], [
            act("SceneBackground", ["", "\"40;40;70\""]),
            act("PlaySound", ["", "\"menu.mp3\"", "", "yes"]),
        ]),
        ev([cond("IsCursorOnObject", ["BtnStart", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("Scene", ["", "\"GameScene\"", "true"])]),
        ev([cond("IsCursorOnObject", ["BtnQuit", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("Quit", [""])]),
    ]
    instances = [
        instance("MenuBackground", 0, 0, z=0, custom=True, w=W, h=H),
        instance("TextTitle", 154, 60, z=5),
        instance("TextSub", 204, 120, z=5),
        instance("BtnStart", 354, 240, z=6),
        instance("TextBtnStart", 378, 254, z=7),
        instance("BtnQuit", 354, 330, z=6),
        instance("TextBtnQuit", 398, 344, z=7),
    ]
    return {"name": "MainMenu", "title": "Main Menu", "events": events, "instances": instances}


# ============================ GAME OVER ============================
def game_over_scene():
    events = [
        ev([cond("SceneJustBegins", [""])], [
            act("SceneBackground", ["", "\"20;10;30\""]),
            act("ModVarSceneTxt", ["GameOverStat", "=",
                "Variable(WinFlag) = 1 ? \"KOLONI SELAMAT! Bertahan \" + ToString(Variable(Day)) + \" hari.\" : \"Kolonis bertahan selama \" + ToString(Variable(Day)) + \" hari.\""]),
            act("TextObject::String", ["TextGoStat", "=", "Variable(GameOverStat)"]),
        ]),
        ev([cond("IsCursorOnObject", ["BtnRetry", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("Scene", ["", "\"GameScene\"", "true"])]),
    ]
    instances = [
        instance("TextGameOver", 224, 100, z=5),
        instance("TextGoStat", 304, 200, z=5),
        instance("BtnRetry", 354, 300, z=6),
        instance("TextGoBtn", 390, 314, z=7),
    ]
    return {"name": "GameOver", "title": "Game Over", "events": events, "instances": instances}


# ============================ GAME SCENE ============================
def game_scene():
    return {"name": "GameScene", "title": "Game",
            "events": _game_events(), "instances": _game_instances()}


def _game_instances():
    inst = []
    # --- terrain: grid tile grass & variasi ---
    random.seed(42)
    for ty in range(0, WORLD_H, TILE):
        for tx in range(0, WORLD_W, TILE):
            r = random.random()
            nm = "TileGrass"
            if r > 0.93: nm = "TileDirt"
            inst.append(instance(nm, tx, ty, z=0))
    # --- resource nodes tersebar ---
    spots = [(300, 200), (500, 150), (700, 250), (250, 400), (600, 420), (900, 180),
             (1100, 300), (1400, 200), (1600, 380), (1200, 500), (200, 700), (450, 900),
             (800, 800), (1500, 700), (1800, 500), (2100, 300), (2400, 600), (2700, 400),
             (400, 1200), (1000, 1100), (1700, 1000), (2300, 1100), (2900, 900), (2600, 1400),
             (1300, 1400), (700, 1500), (1900, 1500), (3000, 1500)]
    kinds = [("Tree", 10), ("Rock", 8), ("MetalOre", 3), ("CrystalVein", 2), ("BerryBush", 5)]
    i = 0
    for (x, y) in spots:
        nm, cnt = kinds[i % len(kinds)]
        for k in range(cnt):
            ox = x + random.randint(-60, 60); oy = y + random.randint(-60, 60)
            inst.append(instance(nm, ox, oy, z=1))
        i += 1
    # --- crash pod & kolonis start ---
    inst.append(instance("CrashPod", 380, 260, z=2))
    inst.append(instance("Rex", 300, 330, z=5))
    inst.append(instance("Luna", 340, 360, z=5))
    inst.append(instance("Bolt", 380, 400, z=5))
    # --- HUD atas ---
    inst.append(instance("UIPanel", 0, 0, z=100, custom=True, w=W, h=34))
    inst.append(instance("TextDay", 12, 8, z=101))
    inst.append(instance("TextRes", 240, 8, z=101))
    inst.append(instance("TextAlert", 620, 8, z=101))
    inst.append(instance("BtnPause", 850, 6, z=101))
    inst.append(instance("BtnPlay", 850, 6, z=101))
    inst.append(instance("BtnFast", 818, 6, z=101))
    # --- HUD bawah ---
    inst.append(instance("UIPortrait", 20, H - 70, z=101))
    inst.append(instance("UIPortrait", 80, H - 70, z=101))
    inst.append(instance("UIPortrait", 140, H - 70, z=101))
    inst.append(instance("TextNeeds", 20, H - 110, z=101))
    inst.append(instance("BtnBuild", 800, H - 64, z=101))
    return inst


def _game_events():
    evs = []
    # ============ SETUP ============
    evs.append(group("Setup: variabel awal", [
        ev([cond("SceneJustBegins", [""])], [
            act("ModVarScene", ["Day", "=", "1"]),
            act("ModVarScene", ["TimeOfDay", "=", "0.2"]),
            act("ModVarScene", ["GameSpeed", "=", "1"]),
            act("ModVarScene", ["IsPaused", "=", "0"]),
            act("ModVarScene", ["Wood", "=", "20"]),
            act("ModVarScene", ["Stone", "=", "10"]),
            act("ModVarScene", ["Metal", "=", "0"]),
            act("ModVarScene", ["Crystal", "=", "0"]),
            act("ModVarScene", ["Food", "=", "10"]),
            act("ModVarScene", ["Energy", "=", "0"]),
            act("ModVarScene", ["BuildMode", "=", "0"]),
            act("ModVarScene", ["CamDrag", "=", "0"]),
            act("ModVarScene", ["RaidTimer", "=", "300"]),
            act("ModVarScene", ["WinFlag", "=", "0"]),
            act("ModVarScene", ["Selection", "=", "0"]),
            act("ModVarSceneTxt", ["GameOverStat", "=", "\"-\""]),
            act("ResetTimer", ["", "\"raid\""]),
            act("ResetTimer", ["", "\"nightspawn\""]),
            act("Hide", ["BtnPlay"]),
            act("PlaySound", ["", "\"ambient.mp3\"", "", "yes"]),
        ]),
    ]))
    # ============ KAMERA ============
    evs.append(group("Kamera: drag untuk pan", [
        comment("drag dengan touch/mouse: pan kamera; gerak < 6px dianggap tap"),
        ev([cond("MouseButtonPressed", ["", "Left"])], [
            act("ModVarScene", ["CamDrag", "=", "1"]),
            act("ModVarScene", ["StartX", "=", "MouseX(\"\",0)"]),
            act("ModVarScene", ["StartY", "=", "MouseY(\"\",0)"]),
            act("ModVarScene", ["CamCX", "=", "CameraCenterX(\"\")"]),
            act("ModVarScene", ["CamCY", "=", "CameraCenterY(\"\")"]),
        ]),
        ev([cond("MouseButtonPressed", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "1"])], [
            act("SetCameraCenterX", ["", "=",
                "Variable(CamCX) - (MouseX(\"\",0) - Variable(StartX))", "\"\"", "\"\""]),
            act("SetCameraCenterY", ["", "=",
                "Variable(CamCY) - (MouseY(\"\",0) - Variable(StartY))", "\"\"", "\"\""]),
        ]),
        ev([cond("MouseButtonReleased", ["", "Left"])], [
            act("ModVarScene", ["CamDrag", "=", "0"]),
        ]),
    ]))
    # ============ WAKTU: DAY/NIGHT ============
    evs.append(group("Waktu game: day/night cycle (1 hari = 8 menit)", [
        comment("TimeOfDay 0..1; 1 hari = 480 detik / GameSpeed"),
        ev([cond("VarScene", ["IsPaused", "=", "0"]),
            cond("VarScene", ["GameSpeed", ">", "0"])], [
            act("ModVarScene", ["TimeOfDay", "+",
                "TimeDelta() * Variable(GameSpeed) / 480"]),
        ]),
        ev([cond("VarScene", ["TimeOfDay", ">=", "1"])], [
            act("ModVarScene", ["TimeOfDay", "=", "0"]),
            act("ModVarScene", ["Day", "+", "1"]),
        ]),
        # overlay malam
        ev([cond("VarScene", ["TimeOfDay", ">", "0.7"]),
            cond("VarScene", ["TimeOfDay", "<", "0.98"])], [
            act("Show", ["NightOverlay"]),
        ]),
        ev([cond("VarScene", ["TimeOfDay", "<", "0.7"])], [
            act("Hide", ["NightOverlay"]),
        ]),
    ]))
    # ============ SELEKSI KOLONIS ============
    evs.append(group("Seleksi kolonis via tap", [
        comment("tap kolonis saat tidak drag → terpilih"),
        ev([cond("IsCursorOnObject", ["Rex", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"]),
            cond("VarObjet", ["Rex", "isDown", "=", "0"])], [
            act("ModVarObjet", ["Rex", "isSelected", "=", "1"]),
            act("ModVarObjet", ["Luna", "isSelected", "=", "0"]),
            act("ModVarObjet", ["Bolt", "isSelected", "=", "0"]),
        ]),
        ev([cond("IsCursorOnObject", ["Luna", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"]),
            cond("VarObjet", ["Luna", "isDown", "=", "0"])], [
            act("ModVarObjet", ["Luna", "isSelected", "=", "1"]),
            act("ModVarObjet", ["Rex", "isSelected", "=", "0"]),
            act("ModVarObjet", ["Bolt", "isSelected", "=", "0"]),
        ]),
        ev([cond("IsCursorOnObject", ["Bolt", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"]),
            cond("VarObjet", ["Bolt", "isDown", "=", "0"])], [
            act("ModVarObjet", ["Bolt", "isSelected", "=", "1"]),
            act("ModVarObjet", ["Rex", "isSelected", "=", "0"]),
            act("ModVarObjet", ["Luna", "isSelected", "=", "0"]),
        ]),
    ]))
    # ============ PERINTAH KERJA ============
    evs.append(group("Perintah kerja: kolonis terpilih menuju node yang di-tap", [
        comment("tap pohon/batu/ore/bush dengan kolonis terpilih → kerjakan"),
        ev([cond("IsCursorOnObject", ["Tree", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"])],
           [], events=_assign_job("Tree", "chop")),
        ev([cond("IsCursorOnObject", ["Rock", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"])],
           [], events=_assign_job("Rock", "mine")),
        ev([cond("IsCursorOnObject", ["MetalOre", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"])],
           [], events=_assign_job("MetalOre", "mine")),
        ev([cond("IsCursorOnObject", ["CrystalVein", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"])],
           [], events=_assign_job("CrystalVein", "mine")),
        ev([cond("IsCursorOnObject", ["BerryBush", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"])],
           [], events=_assign_job("BerryBush", "harvest")),
    ]))
    # ============ EKSEKUSI PEKERJAAN ============
    evs.append(group("Eksekusi: kolonis jalan ke target, saat dekat → panen", [
        comment("jalan ke target (semua kolonis dengan job aktif)"),
        ev([cond("VarObjetTxt", ["Rex", "jobType", "!=", "\"none\""]),
            cond("VarScene", ["IsPaused", "=", "0"])], [
            act("AddForceTowardPosition", ["Rex", "Rex.Variable(jobTargetX)",
                                           "Rex.Variable(jobTargetY)",
                                           "Rex.Variable(speed)", "1"]),
            _set_anim("Rex", "walk"),
        ]),
        ev([cond("VarObjetTxt", ["Luna", "jobType", "!=", "\"none\""]),
            cond("VarScene", ["IsPaused", "=", "0"])], [
            act("AddForceTowardPosition", ["Luna", "Luna.Variable(jobTargetX)",
                                           "Luna.Variable(jobTargetY)",
                                           "Luna.Variable(speed)", "1"]),
            _set_anim("Luna", "walk"),
        ]),
        ev([cond("VarObjetTxt", ["Bolt", "jobType", "!=", "\"none\""]),
            cond("VarScene", ["IsPaused", "=", "0"])], [
            act("AddForceTowardPosition", ["Bolt", "Bolt.Variable(jobTargetX)",
                                           "Bolt.Variable(jobTargetY)",
                                           "Bolt.Variable(speed)", "1"]),
            _set_anim("Bolt", "walk"),
        ]),
        comment("job selesai bila target jauh terhapus → target koordinat terkunci"),
        comment("sampai target: jarak < 45px ke node → harvest"),
        _harvest_event("Rex", "Tree"), _harvest_event("Rex", "Rock"),
        _harvest_event("Rex", "MetalOre"), _harvest_event("Rex", "CrystalVein"),
        _harvest_event("Rex", "BerryBush"),
        _harvest_event("Luna", "Tree"), _harvest_event("Luna", "Rock"),
        _harvest_event("Luna", "MetalOre"), _harvest_event("Luna", "CrystalVein"),
        _harvest_event("Luna", "BerryBush"),
        _harvest_event("Bolt", "Tree"), _harvest_event("Bolt", "Rock"),
        _harvest_event("Bolt", "MetalOre"), _harvest_event("Bolt", "CrystalVein"),
        _harvest_event("Bolt", "BerryBush"),
    ]))
    # ============ KEBUTUHAN ============
    evs.append(group("Needs kolonis: hunger/sleep/mood turun perlahan",
                     _needs_update()))
    evs.append(group("Kolonis makan otomatis saat lapar", _auto_eat()))
    evs.append(group("Malam hari kolonis tanpa job tidur", _settle_down()))
    # ============ MONSTER ============
    evs.append(group("Monster: spawn malam hari + raid berkala", [
        comment("malam hari: spawn slime/bat acak di tepi layar"),
        ev([cond("VarScene", ["TimeOfDay", ">", "0.7"]),
            cond("VarScene", ["TimeOfDay", "<", "0.95"]),
            cond("Timer", ["", "8", "\"nightspawn\""]),
            cond("VarScene", ["IsPaused", "=", "0"])], [
            act("ResetTimer", ["", "\"nightspawn\""]),
            act("Create", ["", "Slime",
                "CameraCenterX(\"\") + Random(600) - 300",
                "CameraCenterY(\"\") - 400", "\"\""]),
        ]),
        comment("raid tiap RaidTimer detik: spawn gelombang"),
        ev([cond("Timer", ["", "Variable(RaidTimer)", "\"raid\""]),
            cond("VarScene", ["IsPaused", "=", "0"])], [
            act("ResetTimer", ["", "\"raid\""]),
            act("Create", ["", "Slime",
                "CameraCenterX(\"\") - 500", "CameraCenterY(\"\")", "\"\""]),
            act("Create", ["", "Slime",
                "CameraCenterX(\"\") + 500", "CameraCenterY(\"\")", "\"\""]),
            act("Create", ["", "Zapper",
                "CameraCenterX(\"\") - 450", "CameraCenterY(\"\") + 100", "\"\""]),
            act("TextObject::String", ["TextAlert", "=", "\"RAID! Monster menyerang!\""]),
            act("PlaySound", ["", "\"alert.mp3\"", "", "yes"]),
            act("ModVarScene", ["RaidTimer", "-", "20"]),
        ]),
        comment("monster mengejar kolonis terdekat"),
        _monster_ai("Slime"), _monster_ai("Zapper"), _monster_ai("Golem"),
        _monster_ai("Stalker"), _monster_ai("Bat"),
        comment("serangan monster ke kolonis"),
        *_monster_attack("Slime"), *_monster_attack("Zapper"),
        *_monster_attack("Golem"), *_monster_attack("Stalker"),
        *_monster_attack("Bat"),
    ]))
    # ============ SERANG MONSTER ============
    evs.append(group("Kolonis menyerang monster yang di-tap saat terpilih", [
        ev([cond("IsCursorOnObject", ["Slime", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarObjet", ["Rex", "isSelected", "=", "1"])], [], events=_attack_job("Rex", "Slime")),
        ev([cond("IsCursorOnObject", ["Zapper", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarObjet", ["Rex", "isSelected", "=", "1"])], [], events=_attack_job("Rex", "Zapper")),
        ev([cond("IsCursorOnObject", ["Slime", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarObjet", ["Luna", "isSelected", "=", "1"])], [], events=_attack_job("Luna", "Slime")),
        ev([cond("IsCursorOnObject", ["Zapper", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarObjet", ["Luna", "isSelected", "=", "1"])], [], events=_attack_job("Luna", "Zapper")),
        ev([cond("IsCursorOnObject", ["Slime", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarObjet", ["Bolt", "isSelected", "=", "1"])], [], events=_attack_job("Bolt", "Slime")),
        ev([cond("IsCursorOnObject", ["Zapper", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarObjet", ["Bolt", "isSelected", "=", "1"])], [], events=_attack_job("Bolt", "Zapper")),
        comment("kolonis dekat monster job attack → damage tick"),
        _colonist_attack("Rex"), _colonist_attack("Luna"), _colonist_attack("Bolt"),
    ]))
    # ============ MATI & GAME OVER ============
    evs.append(group("Kolonis tumbang & game over", _death_check()))
    evs.append(group("Kemenangan: bertahan 30 hari", _win_check()))
    # ============ HUD ============
    evs.append(group("HUD: update teks tiap frame", _hud_update()))
    # ============ PAUSE / SPEED ============
    evs.append(group("Tombol pause / play / fast-forward", [
        ev([cond("IsCursorOnObject", ["BtnPause", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("ModVarScene", ["IsPaused", "=", "1"]),
            act("ModVarScene", ["GameSpeed", "=", "0"]),
            act("Hide", ["BtnPause"]), act("Show", ["BtnPlay"]),
        ]),
        ev([cond("IsCursorOnObject", ["BtnPlay", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("ModVarScene", ["IsPaused", "=", "0"]),
            act("ModVarScene", ["GameSpeed", "=", "1"]),
            act("Hide", ["BtnPlay"]), act("Show", ["BtnPause"]),
        ]),
        ev([cond("IsCursorOnObject", ["BtnFast", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("ModVarScene", ["GameSpeed", "=", "3"]),
            act("ModVarScene", ["IsPaused", "=", "0"]),
            act("Hide", ["BtnPlay"]), act("Show", ["BtnPause"]),
        ]),
    ]))
    # ============ BUILD MODE ============
    evs.append(group("Build mode: pilih bangunan → tap tanah untuk pasang", [
        ev([cond("IsCursorOnObject", ["BtnBuild", "", "yes", ""]),
            cond("MouseButtonReleased", ["", "Left"])], [
            act("ModVarScene", ["BuildMode", "=", "1"]),
            act("TextObject::String", ["TextAlert", "=", "\"Build: pilih lokasi (butuh kayu)\""]),
        ]),
        comment("tap di dunia saat build mode → buat WallWood bila kayu cukup"),
        ev([cond("VarScene", ["BuildMode", "=", "1"]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["CamDrag", "=", "0"]),
            cond("VarScene", ["Wood", ">=", "5"])], [
            act("Create", ["", "WallWood",
                "Round(MouseX(\"\",0)/32)*32", "Round(MouseY(\"\",0)/32)*32", "\"\""]),
            act("ModVarScene", ["Wood", "-", "5"]),
            act("ModVarScene", ["BuildMode", "=", "0"]),
            act("PlaySound", ["", "\"build.mp3\"", "", "yes"]),
        ]),
        ev([cond("VarScene", ["BuildMode", "=", "1"]),
            cond("MouseButtonReleased", ["", "Left"]),
            cond("VarScene", ["Wood", "<", "5"]),
            cond("VarScene", ["CamDrag", "=", "0"])], [
            act("ModVarScene", ["BuildMode", "=", "0"]),
            act("TextObject::String", ["TextAlert", "=", "\"Kayu kurang!\""]),
        ]),
    ]))
    return evs
