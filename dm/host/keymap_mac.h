// The Mac keyboard and mouse layout: which key or mouse button holds which Switch control. One table for the host (front_mac.m) and the Mac app's settings window
// (dm/mac/Launcher.swift, through swiftc -import-objc-header), so the window shows what the host does. Header only (static inline): the Swift side compiles it with no object file.
// The default is a PC game's: WASD moves, the mouse turns the camera (front_mac.m, mouse look), left click Y, right click ZR, Space X, F A, Shift B, Tab L, Q ZL, E R, Esc +, M −.
// DM_KEYMAP changes it: "<target>=<input> <input>;..." (',' also separates entries), each entry replacing that target's inputs, up to KM_SLOTS, and taking them from any other target
// ("r=" unbinds R). The settings window writes only the targets that differ from the default, so a later default reaches every target the player left alone
#pragma once
#include <stdint.h>
#include <string.h>

enum { KM_KEYS = 128, KM_MOUSE = 8, KM_INPUTS = KM_KEYS + KM_MOUSE, KM_SLOTS = 2 };   // an input: a key code (kVK_*, by position), or KM_KEYS + an NSEvent buttonNumber
typedef enum {
    KM_A, KM_B, KM_X, KM_Y, KM_L, KM_R, KM_ZL, KM_ZR, KM_PLUS, KM_MINUS, KM_LS, KM_RS,
    KM_LUP, KM_LDOWN, KM_LLEFT, KM_LRIGHT, KM_RUP, KM_RDOWN, KM_RLEFT, KM_RRIGHT,
    KM_DUP, KM_DDOWN, KM_DLEFT, KM_DRIGHT, KM_WALK, KM_SHAKE, KM_TARGETS
} km_target;

static const struct { const char *id, *label, *group, *def; } km_targets[KM_TARGETS] = {
    [KM_A] = {"a", "A", "Buttons", "f"},                 [KM_B] = {"b", "B", "Buttons", "lshift"},
    [KM_X] = {"x", "X", "Buttons", "space"},             [KM_Y] = {"y", "Y", "Buttons", "mouse1"},
    [KM_L] = {"l", "L", "Buttons", "tab"},               [KM_R] = {"r", "R", "Buttons", "e"},
    [KM_ZL] = {"zl", "ZL", "Buttons", "q mouse3"},       [KM_ZR] = {"zr", "ZR", "Buttons", "mouse2"},
    [KM_PLUS] = {"plus", "+", "Buttons", "escape return"}, [KM_MINUS] = {"minus", "−", "Buttons", "m backspace"},
    [KM_LS] = {"lstick", "Left stick press (L3)", "Buttons", "c lctrl"}, [KM_RS] = {"rstick", "Right stick press (R3)", "Buttons", "v"},
    [KM_LUP] = {"lup", "Up", "Left stick", "w"},         [KM_LDOWN] = {"ldown", "Down", "Left stick", "s"},
    [KM_LLEFT] = {"lleft", "Left", "Left stick", "a"},   [KM_LRIGHT] = {"lright", "Right", "Left stick", "d"},
    [KM_RUP] = {"rup", "Up", "Right stick", "i"},        [KM_RDOWN] = {"rdown", "Down", "Right stick", "k"},
    [KM_RLEFT] = {"rleft", "Left", "Right stick", "j"},  [KM_RRIGHT] = {"rright", "Right", "Right stick", "l"},
    [KM_DUP] = {"dup", "Up", "D-pad", "up 1"},           [KM_DDOWN] = {"ddown", "Down", "D-pad", "down 3"},
    [KM_DLEFT] = {"dleft", "Left", "D-pad", "left 4"},   [KM_DRIGHT] = {"dright", "Right", "D-pad", "right 2"},
    [KM_WALK] = {"walk", "Walk (left stick at half)", "Other", "lopt"}, [KM_SHAKE] = {"shake", "Shake the controller", "Other", "g"},
};

// The keys a layout can name. ⌘ is the system's (shortcuts, and it gives the pointer back from mouse look), Caps Lock only toggles and Fn is the keyboard's own: none can be bound
static const struct { uint8_t code; const char *name, *label; } km_keys[] = {
    {0, "a", "A"}, {11, "b", "B"}, {8, "c", "C"}, {2, "d", "D"}, {14, "e", "E"}, {3, "f", "F"}, {5, "g", "G"}, {4, "h", "H"}, {34, "i", "I"}, {38, "j", "J"}, {40, "k", "K"},
    {37, "l", "L"}, {46, "m", "M"}, {45, "n", "N"}, {31, "o", "O"}, {35, "p", "P"}, {12, "q", "Q"}, {15, "r", "R"}, {1, "s", "S"}, {17, "t", "T"}, {32, "u", "U"}, {9, "v", "V"},
    {13, "w", "W"}, {7, "x", "X"}, {16, "y", "Y"}, {6, "z", "Z"},
    {29, "0", "0"}, {18, "1", "1"}, {19, "2", "2"}, {20, "3", "3"}, {21, "4", "4"}, {23, "5", "5"}, {22, "6", "6"}, {26, "7", "7"}, {28, "8", "8"}, {25, "9", "9"},
    {49, "space", "Space"}, {36, "return", "Return"}, {48, "tab", "Tab"}, {53, "escape", "Esc"}, {51, "backspace", "Delete"}, {117, "fwddelete", "Forward Delete"},
    {56, "lshift", "Left Shift"}, {60, "rshift", "Right Shift"}, {59, "lctrl", "Left Control"}, {62, "rctrl", "Right Control"}, {58, "lopt", "Left Option"}, {61, "ropt", "Right Option"},
    {126, "up", "↑"}, {125, "down", "↓"}, {123, "left", "←"}, {124, "right", "→"}, {115, "home", "Home"}, {119, "end", "End"}, {116, "pageup", "Page Up"}, {121, "pagedown", "Page Down"},
    {50, "grave", "`"}, {27, "hyphen", "-"}, {24, "equal", "="}, {33, "lbracket", "["}, {30, "rbracket", "]"}, {42, "backslash", "\\"}, {41, "semicolon", ";"}, {39, "quote", "'"},
    {43, "comma", ","}, {47, "period", "."}, {44, "slash", "/"}, {10, "section", "§"},
    {122, "f1", "F1"}, {120, "f2", "F2"}, {99, "f3", "F3"}, {118, "f4", "F4"}, {96, "f5", "F5"}, {97, "f6", "F6"}, {98, "f7", "F7"}, {100, "f8", "F8"}, {101, "f9", "F9"},
    {109, "f10", "F10"}, {103, "f11", "F11"}, {111, "f12", "F12"},
    {82, "kp0", "Keypad 0"}, {83, "kp1", "Keypad 1"}, {84, "kp2", "Keypad 2"}, {85, "kp3", "Keypad 3"}, {86, "kp4", "Keypad 4"}, {87, "kp5", "Keypad 5"}, {88, "kp6", "Keypad 6"},
    {89, "kp7", "Keypad 7"}, {91, "kp8", "Keypad 8"}, {92, "kp9", "Keypad 9"}, {65, "kpdecimal", "Keypad ."}, {76, "kpenter", "Keypad Enter"}, {69, "kpplus", "Keypad +"},
    {78, "kpminus", "Keypad -"}, {67, "kpmultiply", "Keypad *"}, {75, "kpdivide", "Keypad /"},
};
static const char *const km_mouse_names[KM_MOUSE] = {"mouse1", "mouse2", "mouse3", "mouse4", "mouse5", "mouse6", "mouse7", "mouse8"};
static const char *const km_mouse_labels[KM_MOUSE] = {"Left Click", "Right Click", "Middle Click", "Mouse 4", "Mouse 5", "Mouse 6", "Mouse 7", "Mouse 8"};

static inline int km_target_count(void) { return KM_TARGETS; }
static inline const char *km_target_id(int t) { return t >= 0 && t < KM_TARGETS ? km_targets[t].id : ""; }
static inline const char *km_target_label(int t) { return t >= 0 && t < KM_TARGETS ? km_targets[t].label : ""; }
static inline const char *km_target_group(int t) { return t >= 0 && t < KM_TARGETS ? km_targets[t].group : ""; }

static inline int km_input_from_key(unsigned short code) {   // a key event's input, -1 for a key no layout can name
    for (unsigned i = 0; i < sizeof km_keys / sizeof *km_keys; i++) if (km_keys[i].code == code) return code;
    return -1;
}
static inline int km_input_from_mouse(long button) { return button >= 0 && button < KM_MOUSE ? KM_KEYS + (int)button : -1; }
// Shift, Control and Option come as modifier changes, not key-downs: each side has its own bit in the event's flags (IOLLEvent.h NX_DEVICE*KEYMASK). 0 for any other key
static inline unsigned long km_modifier_bit(unsigned short code) {
    return code == 56 ? 0x2 : code == 60 ? 0x4 : code == 59 ? 0x1 : code == 62 ? 0x2000 : code == 58 ? 0x20 : code == 61 ? 0x40 : 0;
}
static inline const char *km_input_name(int in) {   // "f", "lshift", "mouse1"; NULL for no input
    if (in >= KM_KEYS && in < KM_INPUTS) return km_mouse_names[in - KM_KEYS];
    for (unsigned i = 0; i < sizeof km_keys / sizeof *km_keys; i++) if (km_keys[i].code == in) return km_keys[i].name;
    return NULL;
}
static inline const char *km_input_label(int in) {   // "F", "Left Shift", "Left Click"; "" for no input
    if (in >= KM_KEYS && in < KM_INPUTS) return km_mouse_labels[in - KM_KEYS];
    for (unsigned i = 0; i < sizeof km_keys / sizeof *km_keys; i++) if (km_keys[i].code == in) return km_keys[i].label;
    return "";
}
static inline int km_input_named(const char *s, size_t n) {   // the input a name of n bytes names, -1 when none
    for (int b = 0; b < KM_MOUSE; b++) if (strlen(km_mouse_names[b]) == n && !strncmp(km_mouse_names[b], s, n)) return KM_KEYS + b;
    for (unsigned i = 0; i < sizeof km_keys / sizeof *km_keys; i++) if (strlen(km_keys[i].name) == n && !strncmp(km_keys[i].name, s, n)) return km_keys[i].code;
    return -1;
}

typedef struct { int16_t in[KM_TARGETS][KM_SLOTS]; } km_layout;   // each target's inputs in slot order, -1 = none

static inline void km_bind(km_layout *L, int t, const char *names, size_t n, int *bad) {   // target t takes the inputs named in names (space separated), each leaving any other target
    int16_t got[KM_SLOTS] = {-1, -1}; int k = 0;
    for (size_t i = 0; i < n;) {
        while (i < n && names[i] == ' ') i++;
        size_t j = i; while (j < n && names[j] != ' ') j++;
        if (j > i) { int in = km_input_named(names + i, j - i); if (in < 0 || k == KM_SLOTS) (*bad)++; else got[k++] = (int16_t)in; }
        i = j;
    }
    for (int u = 0; u < KM_TARGETS; u++) for (int s = 0; s < KM_SLOTS; s++) for (int g = 0; g < k; g++) if (L->in[u][s] == got[g]) L->in[u][s] = -1;
    for (int s = 0; s < KM_SLOTS; s++) L->in[t][s] = got[s];
}
// The default layout, then spec's changes (NULL or "" = the default). Returns how many names spec had that no target or input has (they are left out)
static inline int km_layout_load(km_layout *L, const char *spec) {
    int bad = 0;
    for (int t = 0; t < KM_TARGETS; t++) { for (int s = 0; s < KM_SLOTS; s++) L->in[t][s] = -1; km_bind(L, t, km_targets[t].def, strlen(km_targets[t].def), &bad); }
    for (const char *p = spec ? spec : ""; *p;) {
        size_t n = strcspn(p, ";,"), eq = strcspn(p, "=");
        if (eq < n) {
            const char *id = p; size_t idn = eq; while (idn && id[idn - 1] == ' ') idn--; while (idn && *id == ' ') { id++; idn--; }
            int t = -1; for (int u = 0; u < KM_TARGETS; u++) if (strlen(km_targets[u].id) == idn && !strncmp(km_targets[u].id, id, idn)) t = u;
            if (t < 0) bad++; else km_bind(L, t, p + eq + 1, n - eq - 1, &bad);
        } else if (strspn(p, " ") < n) bad++;
        p += n; if (*p) p++;
    }
    return bad;
}
static inline int km_slot(const char *spec, int t, int s) {   // the settings window: slot s of target t under spec, -1 = none
    km_layout L; km_layout_load(&L, spec);
    return t >= 0 && t < KM_TARGETS && s >= 0 && s < KM_SLOTS ? L.in[t][s] : -1;
}
