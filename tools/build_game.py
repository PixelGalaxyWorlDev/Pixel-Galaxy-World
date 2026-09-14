#!/usr/bin/env python3
"""Assembler Pixel Galaxy World -> project/game.json (GDevelop 5 project).

Cara pakai:
    cd tools && python3 build_game.py

Menghasilkan project/game.json yang valid:
- properties (orientation landscape, 909x513, package com.kenopsia.pixelgalaxyworld)
- 156 resources (152 image + 4 audio)
- 59 objects (kolonis, monster, bangunan, UI, text)
- 3 layouts: MainMenu, GameScene, GameOver
- global variables G_Title/G_Stat (string)
- firstLayout "MainMenu", gdVersion 5.0.280
"""
import json, os, sys, uuid

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)

import gd_objects as go
import gd_scenes as gs


# ---------------------------------------------------------------- helpers
def layer(name="", visible=True):
    return {
        "ambientLightColorB": 200, "ambientLightColorG": 200,
        "ambientLightColorR": 200,
        "camera2DPlaneMaxDrawingDistance": 5000,
        "camera3DFarPlaneDistance": 10000,
        "camera3DFieldOfView": 45,
        "camera3DNearPlaneDistance": 3,
        "cameraType": "",
        "followBaseLayerCamera": False,
        "isLightingLayer": False,
        "isLocked": False,
        "name": name,
        "renderingType": "",
        "visibility": visible,
        "cameras": [{
            "defaultSize": True, "defaultViewport": True,
            "height": 0, "width": 0,
            "viewportBottom": 1, "viewportLeft": 0,
            "viewportRight": 1, "viewportTop": 0,
        }],
        "effects": [],
    }


def ui_settings():
    return {
        "grid": False, "gridType": "rectangular",
        "gridWidth": 32, "gridHeight": 32, "gridDepth": 32,
        "gridOffsetX": 0, "gridOffsetY": 0, "gridOffsetZ": 0,
        "gridColor": 10401023, "gridAlpha": 0.8,
        "snap": False, "zoomFactor": 1, "windowMask": False,
        "selectedLayer": "", "gameEditorMode": "instances-editor",
    }


def make_layout(scene):
    """scene: {'name','title','events','instances'} -> layout dict GDevelop."""
    return {
        "name": scene["name"],
        "mangledName": scene["name"],
        "title": scene["title"],
        "events": scene["events"],
        "instances": scene["instances"],
        "objects": [],
        "objectsFolderStructure": {"folderName": "__ROOT"},
        "objectsGroups": [],
        "variables": [],
        "behaviorsSharedData": go.SHARED_BEHAVIORS,
        "layers": [layer()],
        "uiSettings": ui_settings(),
        "stopSoundsOnStartup": False,
        "disableInputWhenNotFocused": True,
        "standardSortMethod": True,
        "b": 255, "r": 255, "v": 255,
    }


# ---------------------------------------------------------------- build
def build():
    resources = go.scan_resources()
    objects = go.all_objects()

    game = {
        "firstLayout": "MainMenu",
        "gdVersion": {"build": 280, "major": 5, "minor": 6, "revision": 0},
        "properties": {
            "adaptGameResolutionAtRuntime": True,
            "antialiasingMode": "MSAA",
            "antialisingEnabledOnMobile": False,
            "author": "KenopsiaHUB-101",
            "authorIds": [],
            "authorUsernames": ["KenopsiaHUB-101"],
            "categories": ["game"],
            "currentPlatform": "GDevelop JS platform",
            "description": "Kolonisasi planet pixel: bertahan 30 hari, panen, bangun, lawan monster malam. Mobile colony-sim terinspirasi RimWorld untuk GDevelop.",
            "extensionProperties": [],
            "folderProject": False,
            "latestCompilationDirectory": "",
            "loadingScreen": {
                "backgroundColor": 0,
                "backgroundFadeInDuration": 0.2,
                "backgroundImageResourceName": "",
                "gdevelopLogoStyle": "light",
                "logoAndProgressFadeInDuration": 0.2,
                "logoAndProgressLogoFadeInDelay": 0,
                "minDuration": 1.5,
                "progressBarColor": 16777215,
                "progressBarHeight": 20,
                "progressBarMaxWidth": 200,
                "progressBarMinWidth": 40,
                "progressBarWidthPercent": 30,
                "showGDevelopSplash": True,
                "showProgressBar": True,
            },
            "maxFPS": 60,
            "minFPS": 20,
            "name": "Pixel Galaxy World",
            "orientation": "landscape",
            "packageName": "com.kenopsia.pixelgalaxyworld",
            "pixelsRounding": True,
            "platformSpecificAssets": {
                "android-icon-144": "", "android-icon-192": "", "android-icon-36": "",
                "android-icon-48": "", "android-icon-72": "", "android-icon-96": "",
                "android-windowSplashScreenAnimatedIcon": "",
                "desktop-icon-512": "",
                "ios-icon-100": "", "ios-icon-1024": "", "ios-icon-114": "",
                "ios-icon-120": "", "ios-icon-152": "", "ios-icon-167": "",
                "ios-icon-180": "", "ios-icon-20": "", "ios-icon-29": "",
                "ios-icon-40": "", "ios-icon-50": "", "ios-icon-57": "",
                "ios-icon-58": "", "ios-icon-60": "", "ios-icon-72": "",
                "ios-icon-76": "", "ios-icon-87": "",
            },
            "platforms": [{"name": "GDevelop JS platform"}],
            "playableDevices": [],
            "playableUrl": "",
            "projectUuid": str(uuid.uuid4()),
            "scaleMode": "linear",
            "sizeOnStartupMode": "",
            "templateSlug": "",
            "useExternalInputWindow": False,
            "version": "1.0.0",
            "verticalSync": False,
            "watermark": {"placement": "bottom-left", "showWatermark": True},
            "windowWidth": 909,
            "windowHeight": 513,
        },
        "resources": resources,
        "objects": objects,
        "objectsFolderStructure": {"folderName": "__ROOT"},
        "objectsGroups": [],
        "variables": [
            {"folded": False, "name": "G_Title", "type": "string", "value": "KOLONI HANCUR"},
            {"folded": False, "name": "G_Stat", "type": "string", "value": "-"},
        ],
        "layouts": [
            make_layout(gs.main_menu_scene()),
            make_layout(gs.game_scene()),
            make_layout(gs.game_over_scene()),
        ],
        "externalEvents": [],
        "eventsFunctionsExtensions": [],
        "externalLayouts": [],
    }
    return game


# ---------------------------------------------------------------- validation
def validate(game):
    errors, warnings = [], []
    P = os.path.join(_HERE, "..", "project")

    # 1. JSON serializable
    try:
        json.dumps(game)
    except Exception as e:
        errors.append(f"JSON serialization: {e}")

    obj_names = {o["name"] for o in game["objects"]}
    res_names = {r["name"] for r in game["resources"]}

    # 2. instance <-> object
    for lay in game["layouts"]:
        for inst in lay["instances"]:
            if inst["name"] not in obj_names:
                errors.append(f"[{lay['name']}] instance '{inst['name']}' tidak punya object")

    # 3. events -> object references (param pertama kondisi/action yang nama object)
    def walk(events, lay_name, path=""):
        for i, e in enumerate(events):
            etype = e.get("type", "")
            path_i = f"{lay_name}#{path}{i}"
            for item in e.get("conditions", []) + e.get("actions", []):
                instr = item.get("type", {}).get("value", "")
                params = item.get("parameters", [])
                # param 0 umumnya object untuk BuiltinObject instructions
                if instr in (
                    "Hide", "Show", "Delete", "Create", "SetAnimationName",
                    "ActivateBehavior", "ChangeAnimation", "SetAnimationSpeed",
                    "SetXY", "AddForce", "SetAngle", "RotateTowardPosition",
                    "SetZOrder", "TextObject::String", "SetLayer", "SetVisible",
                ):
                    if params and params[0] and params[0] not in obj_names:
                        if params[0] != "":  # "" berarti semua objek
                            errors.append(
                                f"[{path_i}] {instr}: param0 '{params[0]}' bukan object dikenal")
            for sub in e.get("events", []):
                walk([sub], lay_name, path=f"{path}{i}.")

    for lay in game["layouts"]:
        walk(lay["events"], lay["name"])

    # 4. resource <-> file on disk
    for r in game["resources"]:
        f = os.path.join(P, r["file"])
        if not os.path.isfile(f):
            errors.append(f"resource '{r['name']}' file tidak ada: {r['file']}")

    # 5. object images <-> resources (structure: animations -> directions -> sprites)
    def collect_images(o, acc):
        for anim in o.get("animations", []):
            for d in anim.get("directions", []):
                for fr in d.get("sprites", []):
                    acc.add(fr.get("image", "").rsplit("/", 1)[-1])
        return acc
    for o in game["objects"]:
        if o.get("type") == "Sprite":
            imgs = collect_images(o, set())
            for img in imgs:
                if img and img not in res_names:
                    errors.append(f"object '{o['name']}' pakai image '{img}' tidak ada di resources")

    # 6. firstLayout valid
    if game["firstLayout"] not in {l["name"] for l in game["layouts"]}:
        errors.append(f"firstLayout '{game['firstLayout']}' tidak ada di layouts")

    # 7. PlaySound param count
    def walk_snd(events, lay_name):
        for e in events:
            for item in e.get("conditions", []) + e.get("actions", []):
                instr = item.get("type", {}).get("value", "")
                if instr in ("PlaySound", "PlaySoundOnChannel"):
                    p = item.get("parameters", [])
                    n = {"PlaySound": 5, "PlaySoundOnChannel": 6}[instr]
                    if len(p) != n:
                        errors.append(f"[{lay_name}] {instr} param count {len(p)} != {n}")
                if instr == "StopSoundChannel" and len(item.get("parameters", [])) != 2:
                    errors.append(f"[{lay_name}] StopSoundChannel param count != 2")
            walk_snd(e.get("events", []), lay_name)
    for lay in game["layouts"]:
        walk_snd(lay["events"], lay["name"])

    # 8. audio resource names referenced in events
    def walk_audio(events, lay_name):
        for e in events:
            for item in e.get("conditions", []) + e.get("actions", []):
                instr = item.get("type", {}).get("value", "")
                if instr in ("PlaySound", "PlaySoundOnChannel"):
                    p = item.get("parameters", [])
                    if len(p) > 1 and p[1] and p[1] not in res_names and not os.path.isfile(
                            os.path.join(P, p[1])):
                        errors.append(f"[{lay_name}] {instr} file '{p[1]}' bukan resource/path valid")
            walk_audio(e.get("events", []), lay_name)
    for lay in game["layouts"]:
        walk_audio(lay["events"], lay["name"])

    return errors, warnings


def main():
    game = build()
    out = os.path.join(_HERE, "..", "project", "game.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(game, f, indent=2, ensure_ascii=False)
    print(f"game.json ditulis: {out} ({os.path.getsize(out)} bytes)")

    errors, warnings = validate(game)
    for w in warnings:
        print("WARN ", w)
    if errors:
        print("\n=== VALIDATION ERRORS ===")
        for e in errors:
            print("ERROR", e)
        sys.exit(1)
    print("VALIDASI OK — game.json siap dibuka di GDevelop.")
    print(f"  layouts: {[l['name'] for l in game['layouts']]}")
    print(f"  objects: {len(game['objects'])}, resources: {len(game['resources'])}")


if __name__ == "__main__":
    main()
