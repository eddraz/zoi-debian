.pragma library

function parse(raw) {
    const s = String(raw || "").trim();
    if (!s)
        return null;
    if (s.split(/\s+/).length > 1)
        return null;
    let logo = false;
    let ctrl = false;
    let alt = false;
    let shift = false;
    let key = "";
    const parts = s.split("+");
    for (let i = 0; i < parts.length; i++) {
        const p = parts[i].trim();
        if (!p)
            continue;
        const low = p.toLowerCase();
        if (low === "super" || low === "mod4" || low === "logo" || low === "meta" || low === "win")
            logo = true;
        else if (low === "ctrl" || low === "control")
            ctrl = true;
        else if (low === "alt" || low === "mod1")
            alt = true;
        else if (low === "shift")
            shift = true;
        else if (low === "/" || low === "slash")
            key = "slash";
        else if (low === "." || low === "period")
            key = "period";
        else if (low === "-" || low === "minus")
            key = "minus";
        else if (low === "space")
            key = "space";
        else if (low === "return" || low === "enter" || low === "kp_enter")
            key = "Return";
        else if (low === "esc" || low === "escape")
            key = "Escape";
        else if (low === "tab")
            key = "Tab";
        else if (low === "print" || low === "printscreen")
            key = "Print";
        else if (low === "up" || low === "uparrow")
            key = "Up";
        else if (low === "down" || low === "downarrow")
            key = "Down";
        else if (low === "left" || low === "leftarrow")
            key = "Left";
        else if (low === "right" || low === "rightarrow")
            key = "Right";
        else if (p.length === 1)
            key = p.toLowerCase();
        else
            key = p.charAt(0).toUpperCase() + p.slice(1);
    }
    if (!key)
        return null;
    return { "logo": logo, "ctrl": ctrl, "alt": alt, "shift": shift, "key": key };
}

function comboId(c) {
    if (!c)
        return "";
    return [c.logo ? 1 : 0, c.ctrl ? 1 : 0, c.alt ? 1 : 0, c.shift ? 1 : 0, c.key].join("|");
}

function display(c) {
    if (!c)
        return "—";
    const parts = [];
    if (c.logo)
        parts.push("Super");
    if (c.ctrl)
        parts.push("Ctrl");
    if (c.alt)
        parts.push("Alt");
    if (c.shift)
        parts.push("Shift");
    let key = c.key;
    if (key === "slash")
        key = "/";
    else if (key === "period")
        key = ".";
    else if (key === "minus")
        key = "-";
    else if (key === "space")
        key = "Space";
    else if (key.length === 1)
        key = key.toUpperCase();
    parts.push(key);
    return parts.join("+");
}

function sway(c) {
    if (!c)
        return "";
    const parts = [];
    if (c.logo)
        parts.push("Mod4");
    if (c.ctrl)
        parts.push("Ctrl");
    if (c.alt)
        parts.push("Mod1");
    if (c.shift)
        parts.push("Shift");
    let key = c.key;
    if (key === "slash" || key === "period" || key === "minus" || key === "space")
        parts.push(key);
    else if (key === "Return" || key === "Escape" || key === "Tab" || key === "Print")
        parts.push(key);
    else
        parts.push(key);
    return parts.join("+");
}

function equal(a, b) {
    return comboId(a) === comboId(b);
}
