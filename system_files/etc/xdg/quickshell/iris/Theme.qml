pragma Singleton

import Quickshell
import QtQuick

// Shared look and helpers for every Iris piece.
Singleton {
    // Palette: monochrome, taken from the default wallpaper (near-black with white line art)
    readonly property color bg: "#1F1F1F"
    readonly property color glass: "#E60A0A0A"
    readonly property color edge: "#33FFFFFF"
    readonly property color accent: "#F2F2F2"
    readonly property color fg: "#F2F2F2"
    readonly property color muted: "#8A8A8A"
    readonly property color dim: "#5A5A5A"

    readonly property string serif: "Instrument Serif"
    readonly property string sans: "Hanken Grotesk"
    readonly property string mono: "JetBrains Mono"

    readonly property string wallpaper: "file:///usr/share/backgrounds/matte-os/default.jpg"

    // Quickshell.screens is a QML list, so copy it into a plain array before using array methods.
    function screenList() {
        const r = [];
        for (let i = 0; i < Quickshell.screens.length; i++)
            r.push(Quickshell.screens[i]);
        return r;
    }

    // The main monitor is the rightmost one (that is where the island lives).
    function mainScreens() {
        const s = screenList();
        let best = null;
        for (const m of s)
            if (best === null || m.x > best.x) best = m;
        return best === null ? [] : [best];
    }

    // Rectangle covering all monitors together (used to stretch the wallpaper across them).
    function bounds() {
        const s = screenList();
        let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
        for (const m of s) {
            x0 = Math.min(x0, m.x); y0 = Math.min(y0, m.y);
            x1 = Math.max(x1, m.x + m.width); y1 = Math.max(y1, m.y + m.height);
        }
        return { x: x0, y: y0, w: x1 - x0, h: y1 - y0, count: s.length };
    }
}
