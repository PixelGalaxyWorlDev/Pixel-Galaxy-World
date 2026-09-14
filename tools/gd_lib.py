"""GDevelop JSON builder helpers — format terverifikasi dari contoh resmi GDevelop 5."""

def cond(type_, parameters, inverted=False):
    c = {"type": {"value": type_}, "parameters": parameters}
    if inverted:
        c["type"]["inverted"] = True
    return c

def act(type_, parameters):
    return {"type": {"value": type_}, "parameters": parameters}

def ev(conditions=None, actions=None, events=None):
    e = {"type": "BuiltinCommonInstructions::Standard",
         "conditions": conditions or [], "actions": actions or []}
    if events:
        e["events"] = events
    return e

def comment(text):
    return {"type": "BuiltinCommonInstructions::Comment",
            "color": {"b": 109, "g": 230, "r": 255, "textB": 0, "textG": 0, "textR": 0},
            "comment": text}

def group(name, events):
    return {"colorB": 228, "colorG": 176, "colorR": 74, "creationTime": 0,
            "name": name, "source": "",
            "type": "BuiltinCommonInstructions::Group", "events": events}

def once():
    return cond("BuiltinCommonInstructions::Once", [])

def uuid4():
    import uuid
    return str(uuid.uuid4())

def instance(name, x, y, z=0, layer="", angle=0, w=0, h=0, custom=False):
    return {"name": name, "x": x, "y": y, "zOrder": z, "layer": layer, "angle": angle,
            "customSize": custom, "width": w, "height": h,
            "persistentUuid": uuid4(),
            "numberProperties": [], "stringProperties": [], "initialVariables": []}

def sprite_frame(image, w, h, origin_x=0, origin_y=0):
    return {"hasCustomCollisionMask": True, "image": image, "points": [],
            "originPoint": {"name": "origine", "x": origin_x, "y": origin_y},
            "centerPoint": {"automatic": True, "name": "centre", "x": 0, "y": 0},
            "customCollisionMask": [[{"x": 0, "y": 0}, {"x": w, "y": 0},
                                     {"x": w, "y": h}, {"x": 0, "y": h}]]}

def animation(frames, name="", looping=False, time_between=0.08, multi_dir=False):
    return {"name": name, "useMultipleDirections": multi_dir,
            "directions": [{"looping": looping, "timeBetweenFrames": time_between,
                            "sprites": frames}]}

def text_object(name, string, size=18, color=(255,255,255), x_align="center"):
    return {"assetStoreId": "", "bold": False, "italic": False, "name": name,
            "smoothed": True, "type": "TextObject::Text", "underlined": False,
            "variables": [], "effects": [], "behaviors": [],
            "string": string, "font": "", "textAlignment": x_align, "characterSize": size,
            "color": {"b": color[2], "g": color[1], "r": color[0]},
            "content": {"bold": False, "isOutlineEnabled": False, "isShadowEnabled": False,
                        "italic": False, "outlineColor": "255;255;255", "outlineThickness": 2,
                        "shadowAngle": 90, "shadowBlurRadius": 2, "shadowColor": "0;0;0",
                        "shadowDistance": 4, "shadowOpacity": 127, "smoothed": True,
                        "underlined": False, "text": string, "font": "",
                        "textAlignment": x_align, "verticalTextAlignment": "center",
                        "characterSize": size, "lineHeight": 0,
                        "color": f"{color[0]};{color[1]};{color[2]}"}}

def sprite_object(name, animations, behaviors=None, variables=None, collision_auto=True):
    return {"adaptCollisionMaskAutomatically": collision_auto, "assetStoreId": "",
            "name": name, "type": "Sprite", "updateIfNotVisible": False,
            "variables": variables or [], "effects": [],
            "behaviors": behaviors or [], "animations": animations}

def obj_var(name, value, vtype=None):
    """Object variable definition (di object 'variables' array)."""
    v = {"name": name, "value": value}
    if vtype is None:
        vtype = "string" if isinstance(value, str) else "number"
    v["type"] = vtype
    return v

def behavior(name, type_, **props):
    b = {"name": name, "type": type_}
    if props:
        b.update(props)
    return b

def layer(name="", visible=True, base=False):
    lay = {"ambientLightColorB": 200, "ambientLightColorG": 200, "ambientLightColorR": 200,
           "camera3DFarPlaneDistance": 10000, "camera3DFieldOfView": 45,
           "camera3DNearPlaneDistance": 0.1, "cameraType": "perspective",
           "followBaseLayerCamera": not base and bool(name),
           "isLightingLayer": False, "isLocked": False, "name": name,
           "renderingType": "", "visibility": visible,
           "cameras": [{"defaultSize": True, "defaultViewport": True, "height": 0,
                        "viewportBottom": 1, "viewportLeft": 0, "viewportRight": 1,
                        "viewportTop": 0, "width": 0}],
           "effects": []}
    return lay
