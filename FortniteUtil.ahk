#Requires AutoHotkey v2.0
#SingleInstance Force

; --- INITIAL PERFORMANCE ---
SetKeyDelay -1, -1
SetMouseDelay -1
ProcessSetPriority "High"
CoordMode "Mouse", "Screen"

; --- VERSION & UPDATER CONFIG ---
global CurrentVersion := "1.0.0" 
global VersionURL    := "https://raw.githubusercontent.com/foxscc/foxutil/main/version.txt"
global DownloadURL   := "https://raw.githubusercontent.com/foxscc/foxutil/main/FortniteUtil.ahk"

; --- MESSAGE HANDLERS ---
OnMessage(0x0201, WM_LBUTTONDOWN) 
OnMessage(0x0200, WM_MOUSEMOVE)   

if !A_IsAdmin {
    try Run('*RunAs "' A_ScriptFullPath '"')
    ExitApp()
}

; --- DATA PERSISTENCE ---
LocalAppData := EnvGet("LocalAppData")
IniDir := LocalAppData "\FoxMacros\Combined"
if !DirExist(IniDir)
    DirCreate(IniDir)
IniFile := IniDir "\settings.ini"

; --- SETTINGS LOADING ---
global SavedDelay := Number(IniRead(IniFile, "Settings", "Delay", "10"))
global SavedRes := IniRead(IniFile, "Settings", "Resolution", "1080p")
global SavedTheme := IniRead(IniFile, "Settings", "Theme", "Electric Cyan")
global CustomColor := IniRead(IniFile, "Settings", "CustomColor", "FFFFFF")
global SavedHotkey := IniRead(IniFile, "Settings", "ActivationKey", "XButton1")
global AirhornHotkey := IniRead(IniFile, "Settings", "AirhornKey", "XButton2")
global SpamRatio := Number(IniRead(IniFile, "Settings", "SpamRatio", "6"))
global RightClickDelay := Number(IniRead(IniFile, "Settings", "RightClickDelay", "1"))
global AlwaysOnTop := (IniRead(IniFile, "Settings", "AlwaysOnTop", "0") = "1")
global HoverEnabled := (IniRead(IniFile, "Settings", "HoverEnabled", "1") = "1")
global ConfigFolder := LocalAppData "\FortniteGame\Saved\Config\WindowsClient"
global GamePath := IniRead(IniFile, "Settings", "GamePath", "")
global AFKEnabled := false, g_TargetX := 0, g_TargetY := 0, g_ActiveName := "IDLE"
global LastHoveredHwnd := 0, HoverMap := Map()

; --- DATA PRESETS ---
Themes := Map(
    "Electric Cyan", "00FFFF", "Emerald Venom", "00FF44", "Crimson Fury", "FF4444", 
    "Gold Rush", "FFCC00", "Purple Haze", "CC00FF", "Frost Bite", "AADDFF", 
    "Hazard Orange", "FF8800", "Ghost White", "FFFFFF", "Midnight Blue", "3366FF", 
    "Hot Pink", "FF007F", "Deep Sea", "008080", "Custom", CustomColor
)

Presets := Map(
    "1080p", [{N:"FRAG",X:1406,Y:238},{N:"IMPULSE",X:1584,Y:242},{N:"BUBBLE",X:1758,Y:238},{N:"RECON",X:1410,Y:375},{N:"PROX",X:1587,Y:370},{N:"FIRE",X:1758,Y:374},{N:"OVERDRIVE",X:1409,Y:506},{N:"HEAL",X:1588,Y:507},{N:"WALL",X:1760,Y:514}],
    "1440p", [{N:"FRAG",X:1875,Y:317},{N:"IMPULSE",X:2112,Y:322},{N:"BUBBLE",X:2344,Y:317},{N:"RECON",X:1880,Y:500},{N:"PROX",X:2116,Y:493},{N:"FIRE",X:2344,Y:498},{N:"OVERDRIVE",X:1878,Y:674},{N:"HEAL",X:2117,Y:676},{N:"WALL",X:2346,Y:680}],
    "4K",    [{N:"FRAG",X:2812,Y:476},{N:"IMPULSE",X:3168,Y:484},{N:"BUBBLE",X:3516,Y:476},{N:"RECON",X:2820,Y:750},{N:"PROX",X:3174,Y:740},{N:"FIRE",X:3516,Y:748},{N:"OVERDRIVE",X:2818,Y:1012},{N:"HEAL",X:3176,Y:1014},{N:"WALL",X:3520,Y:1028}]
)

global CurrentGadgets := Presets[SavedRes]

; --- GUI CONSTRUCTION ---
T_Col := Themes[SavedTheme]
MainGui := Gui("-Caption +Border")
if AlwaysOnTop
    MainGui.Opt("+AlwaysOnTop")
MainGui.BackColor := "0A0A0A"

global ThemeablePrimary := [], GadgetBorders := [], SwatchRings := Map(), ThemeOutlines := [], SubTabGraphics := Map(), SwatchIcons := Map()
global TabBorders := [], TabTextCtrls := [], TabContents := [[], [], [], []]

AddOutline(x, y, w, h) {
    ctrl := MainGui.Add("Text", "x" x " y" y " w" w " h" h " Background" T_Col)
    ThemeOutlines.Push(ctrl)
    return ctrl
}

AddOutline(0, 0, 615, 3), AddOutline(0, 512, 615, 3), AddOutline(0, 0, 3, 515), AddOutline(612, 0, 3, 515), AddOutline(175, 105, 2, 385)

MainGui.Add("Text", "x20 y105 w150 h385 Background121212")
MainGui.SetFont("s22 w800")
Header := MainGui.Add("Text", "x25 y30 w300 c" T_Col, "FORTNITE MACRO"), ThemeablePrimary.Push(Header)

MainGui.SetFont("s11 w400", "Segoe UI Symbol")
MainGui.Add("Text", "x530 y15 w30 h30 Center c888888", "—").OnEvent("Click", (*) => MainGui.Minimize())
MainGui.Add("Text", "x565 y15 w30 h30 Center cFF4444", "✕").OnEvent("Click", (*) => ExitApp())

; --- SIDEBAR ---
MainGui.SetFont("s8 w800")
SideTitle := MainGui.Add("Text", "x25 y125 c" T_Col " Background121212", "GADGET"), ThemeablePrimary.Push(SideTitle)
MainGui.SetFont("s10 w700")
global StatusTxt := MainGui.Add("Text", "x25 y145 w145 cFFFFFF Background121212", "IDLE")

MainGui.SetFont("s8 w800")
AFKTitle := MainGui.Add("Text", "x25 y185 c" T_Col " Background121212", "ANTI-AFK"), ThemeablePrimary.Push(AFKTitle)
MainGui.SetFont("s10 w700")
global AFKStatusTxt := MainGui.Add("Text", "x25 y205 w145 cFFFFFF Background121212", "INACTIVE")

AFKLine := MainGui.Add("Text", "x30 y425 w130 h2 Background" T_Col), ThemeOutlines.Push(AFKLine)

AFKBtnFrame := MainGui.Add("Text", "x25 y440 w140 h42 Background" T_Col), ThemeOutlines.Push(AFKBtnFrame)
global AFKBtnTxt := MainGui.Add("Text", "x27 y442 w136 h38 Center +0x200 cFFFFFF Background121212", "🤖 START AFK")
AFKBtnTxt.OnEvent("Click", (ctrl, *) => ToggleAFK(ctrl))
HoverMap[AFKBtnTxt.Hwnd] := AFKBtnTxt

; --- NAVIGATION ---
MainGui.SetFont("s9 w800")
TabNames := ["GADGETS", "SETTINGS", "THEME", "SYSTEM"]
Loop TabNames.Length {
    Idx := A_Index, tx := 185 + ((Idx-1) * 105)
    MainGui.Add("Text", "x" tx " y" 110 " w100 h38 Background181818")
    b := MainGui.Add("Text", "x" tx " y" 110 " w100 h38 Background" T_Col (Idx=1 ? "" : " +Hidden")), TabBorders.Push(b)
    txt := MainGui.Add("Text", "x" tx+2 " y" 112 " w96 h34 Center +0x200 cFFFFFF Background181818", TabNames[Idx])
    txt.OnEvent("Click", SwitchMainTab.Bind(Idx))
    HoverMap[txt.Hwnd] := txt
    TabTextCtrls.Push(txt)
}
TabDivider := MainGui.Add("Text", "x177 y152 w435 h2 Background" T_Col), ThemeOutlines.Push(TabDivider)

; --- TAB 1: GADGETS ---
MainGui.SetFont("s9 w700")
Loop 9 {
    Idx := A_Index, Info := CurrentGadgets[Idx], row := Floor((Idx-1)/3), col := Mod(Idx-1,3), bx := 208+(col*126), by := 185+(row*85)
    border := MainGui.Add("Text", "x" bx-3 " y" by-3 " w116 h66 +Hidden Background" T_Col), GadgetBorders.Push(border), TabContents[1].Push(border)
    gLabel := MainGui.Add("Text", "x" bx " y" by " w110 h60 Center +0x200 cFFFFFF Background181818", Info.N)
    gLabel.OnEvent("Click", SetActiveGadget.Bind(Idx))
    HoverMap[gLabel.Hwnd] := gLabel
    TabContents[1].Push(gLabel)
}

; --- TAB 2: SETTINGS ---
MainGui.SetFont("s8 w800")
SubTabNames := ["GADGETS", "AIRHORN", "AFK"], SubTabModes := ["Gadget", "Horn", "AFK"]
Loop SubTabNames.Length {
    Idx := A_Index, Mode := SubTabModes[Idx], sx := 200 + ((Idx-1) * 95)
    outl := MainGui.Add("Text", "x" sx " y" 170 " w90 h32 Background" T_Col " Hidden"), TabContents[2].Push(outl)
    stxt := MainGui.Add("Text", "x" sx+2 " y" 172 " w86 h28 Center +0x200 cFFFFFF Background181818", SubTabNames[Idx])
    stxt.OnEvent("Click", SwitchSettings.Bind(Mode))
    HoverMap[stxt.Hwnd] := stxt
    TabContents[2].Push(stxt), SubTabGraphics[Mode] := [outl]
}
sLine := MainGui.Add("Text", "x200 y210 w385 h2 Background" T_Col), ThemeOutlines.Push(sLine), TabContents[2].Push(sLine)

; --- TAB 3: THEME ---
MainGui.SetFont("s8 w400")
t5 := MainGui.Add("Text", "x210 y180 cFFFFFF", "SELECT ACCENT COLOR"), TabContents[3].Push(t5)
ThemeList := ["Electric Cyan", "Emerald Venom", "Crimson Fury", "Gold Rush", "Purple Haze", "Frost Bite", "Hazard Orange", "Ghost White", "Midnight Blue", "Hot Pink", "Deep Sea", "Custom"]
Loop ThemeList.Length {
    name := ThemeList[A_Index], col := (name="Custom" ? "121212" : Themes[name]), row := Floor((A_Index-1)/4), colIdx := Mod(A_Index-1, 4), tx := 210 + (colIdx * 90), ty := 210 + (row * 60)
    ring := MainGui.Add("Text", "x" tx-2 " y" ty-2 " w74 h44 Background" (SavedTheme=name ? T_Col : "333333")), SwatchRings[name] := ring
    swatch := MainGui.Add("Text", "x" tx " y" ty " w70 h40 Center +0x200 Background" col), swatch.OnEvent("Click", SetTheme.Bind(name))
    TabContents[3].Push(ring, swatch)
    if (name="Custom") {
        swatch.SetFont("s16 w400", "Segoe UI Symbol"), swatch.Opt("c" T_Col), swatch.Value := "🎨", SwatchIcons["Custom"] := swatch
    }
}

HoverToggle := MainGui.Add("Checkbox", "x210 y420 cFFFFFF Checked" (HoverEnabled ? "1" : "0"), "Enable UI Hover Effects")
HoverToggle.OnEvent("Click", OnHoverToggle)
TabContents[3].Push(HoverToggle)

; --- TAB 4: SYSTEM ---
MainGui.SetFont("s9 w700")
Sys1Bg := MainGui.Add("Text", "x210 y180 w175 h45 Background" T_Col), ThemeOutlines.Push(Sys1Bg)
Sys1Tx := MainGui.Add("Text", "x212 y182 w171 h41 Center +0x200 cFFFFFF Background181818", "🚀 LAUNCH GAME")
Sys1Tx.OnEvent("Click", (*) => HandleLaunch())
HoverMap[Sys1Tx.Hwnd] := Sys1Tx

Sys2Bg := MainGui.Add("Text", "x400 y180 w175 h45 Background" T_Col), ThemeOutlines.Push(Sys2Bg)
Sys2Tx := MainGui.Add("Text", "x402 y182 w171 h41 Center +0x200 cFFFFFF Background181818", "⛔ FORCE KILL")
Sys2Tx.OnEvent("Click", (*) => HandleKill())
HoverMap[Sys2Tx.Hwnd] := Sys2Tx

Sys3Bg := MainGui.Add("Text", "x210 y235 w365 h45 Background" T_Col), ThemeOutlines.Push(Sys3Bg)
Sys3Tx := MainGui.Add("Text", "x212 y237 w361 h41 Center +0x200 cFFFFFF Background181818", "📂 OPEN CONFIGS")
Sys3Tx.OnEvent("Click", (*) => (DirExist(ConfigFolder) ? Run(ConfigFolder) : 0))
HoverMap[Sys3Tx.Hwnd] := Sys3Tx

Sys4Bg := MainGui.Add("Text", "x210 y290 w175 h45 Background" T_Col), ThemeOutlines.Push(Sys4Bg)
Sys4Tx := MainGui.Add("Text", "x212 y292 w171 h41 Center +0x200 cFFFFFF Background181818", "⚠️ RESET")
Sys4Tx.OnEvent("Click", (*) => FactoryReset())
HoverMap[Sys4Tx.Hwnd] := Sys4Tx

Sys5Bg := MainGui.Add("Text", "x400 y290 w175 h45 Background" T_Col), ThemeOutlines.Push(Sys5Bg)
Sys5Tx := MainGui.Add("Text", "x402 y292 w171 h41 Center +0x200 cFFFFFF Background181818", "🔄 UPDATE")
Sys5Tx.OnEvent("Click", (*) => CheckForUpdates(true))
HoverMap[Sys5Tx.Hwnd] := Sys5Tx

TabContents[4].Push(Sys1Bg, Sys1Tx, Sys2Bg, Sys2Tx, Sys3Bg, Sys3Tx, Sys4Bg, Sys4Tx, Sys5Bg, Sys5Tx)

; --- SETTINGS GROUPS ---
MainGui.SetFont("s8 w400")
global SettingGroups := Map()
SettingGroups["Gadget"] := []
t1 := MainGui.Add("Text", "x210 y225 cFFFFFF", "CLICK SPEED (MS)")
DelaySlider := MainGui.Add("Slider", "x210 y245 w300 h30 Range10-500", SavedDelay)
DelaySlider.OnEvent("Change", OnDelayChange)
global DelayDisp := MainGui.Add("Text", "x520 y250 w40 cFFFFFF", SavedDelay "ms")
t2 := MainGui.Add("Text", "x210 y285 cFFFFFF", "RESOLUTION")
ResChoice := MainGui.Add("DropDownList", "x210 y305 w150 Choose" (SavedRes="1080p"?1:SavedRes="1440p"?2:3), ["1080p", "1440p", "4K"])
ResChoice.OnEvent("Change", OnResChange)
BtnReM_Bg := MainGui.Add("Text", "x210 y355 w180 h40 Background" T_Col), ThemeOutlines.Push(BtnReM_Bg)
BtnReM_Tx := MainGui.Add("Text", "x212 y357 w176 h36 Center +0x200 cFFFFFF Background0A0A0A", "REBIND MACRO")
BtnReM_Tx.OnEvent("Click", (ctrl, *) => RebindKey(ctrl, "ActivationKey"))
HoverMap[BtnReM_Tx.Hwnd] := BtnReM_Tx
SettingGroups["Gadget"].Push(t1, DelaySlider, DelayDisp, t2, ResChoice, BtnReM_Bg, BtnReM_Tx)

SettingGroups["Horn"] := []
t3 := MainGui.Add("Text", "x210 y225 cFFFFFF", "SPAM INTENSITY (1-10)")
SpamSlider := MainGui.Add("Slider", "x210 y245 w300 h30 Range1-10", SpamRatio)
SpamSlider.OnEvent("Change", OnSpamChange)
global SpamDisp := MainGui.Add("Text", "x520 y250 w40 cFFFFFF", SpamRatio)
t4 := MainGui.Add("Text", "x210 y295 cFFFFFF", "RIGHT-CLICK RESET (MS)")
RCSlider := MainGui.Add("Slider", "x210 y315 w300 h30 Range1-50", RightClickDelay)
RCSlider.OnEvent("Change", OnRCChange)
global RCDisp := MainGui.Add("Text", "x520 y320 w40 cFFFFFF", RightClickDelay "ms")
BtnReH_Bg := MainGui.Add("Text", "x210 y365 w180 h40 Background" T_Col), ThemeOutlines.Push(BtnReH_Bg)
BtnReH_Tx := MainGui.Add("Text", "x212 y367 w176 h36 Center +0x200 cFFFFFF Background0A0A0A", "REBIND HORN")
BtnReH_Tx.OnEvent("Click", (ctrl, *) => RebindKey(ctrl, "AirhornKey"))
HoverMap[BtnReH_Tx.Hwnd] := BtnReH_Tx
SettingGroups["Horn"].Push(t3, SpamSlider, SpamDisp, t4, RCSlider, RCDisp, BtnReH_Bg, BtnReH_Tx)

SettingGroups["AFK"] := []
MainGui.SetFont("s12 w800")
AFKFutureTitle := MainGui.Add("Text", "x210 y245 w360 Center c" T_Col, "AUTOMATION HUB"), ThemeablePrimary.Push(AFKFutureTitle)
MainGui.SetFont("s8 w400")
AFKFutureText := MainGui.Add("Text", "x210 y275 w360 Center c888888", "Custom timers coming soon.")
SettingGroups["AFK"].Push(AFKFutureTitle, AFKFutureText)

for group, ctrls in SettingGroups {
    for c in ctrls {
        c.Visible := false
        TabContents[2].Push(c)
    }
}

for tab_idx, tab_items in TabContents {
    for ctrl in tab_items
        ctrl.Visible := false
}

SwitchMainTab(1)
CheckForUpdates(false)
MainGui.Show("w615 h515")

; --- DYNAMIC HOTKEY INIT ---
global MacroHK := Hotkey("~" . SavedHotkey, SpamLogic, "On")
global HornHK  := Hotkey("$" . AirhornHotkey, StartAirhorn, "On")

; --- LOGIC ---

To fix the loop once and for all, we’ll apply the "Cache Bypass" to both the version check and the actual download. This ensures that when you click "Yes," you are getting the absolute latest code you just uploaded, not the ghost of the version you uploaded ten minutes ago.

Here is the updated logic. Replace the CheckForUpdates and PerformUpdate functions in your script with these:

Updated Functions
AutoHotkey
CheckForUpdates(Manual := false) {
    try {
        ; Bypass GitHub cache by adding a unique timestamp to the URL
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", VersionURL . "?t=" . A_TickCount, true)
        whr.Send()
        whr.WaitForResponse()
        RemoteVersion := Trim(whr.ResponseText)

        if (VerCompare(RemoteVersion, CurrentVersion) > 0) {
            if MsgBox("New version v" . RemoteVersion . " available. Download now?", "Update Found", "YesNo IconI") = "Yes"
                PerformUpdate()
        } else if (Manual) {
            MsgBox("Your script is up to date.`n`nVersion: v" . CurrentVersion, "Update Check", "IconI")
        }
    } catch Error as e {
        if (Manual)
            MsgBox("Update check failed.`n`nError: " . e.Message, "Connection Error", "IconX")
    }
}

PerformUpdate() {
    tempFile := A_ScriptDir . "\temp_update.ahk"
    try {
        ; Also bypass cache for the download itself
        Download(DownloadURL . "?t=" . A_TickCount, tempFile)
        
        batchPath := A_ScriptDir . "\updater.bat"
        batchScript := "@echo off`ntimeout /t 1 /nobreak > nul`nmove /y `"" . tempFile . "`" `"" . A_ScriptFullPath . "`"`nstart `"" . A_ScriptFullPath . "`"`ndel `"%~f0`""
        
        if FileExist(batchPath)
            FileDelete(batchPath)
        FileAppend(batchScript, batchPath)
        
        Run(batchPath, , "Hide")
        ExitApp()
    } catch Error as e {
        MsgBox("Download failed: " . e.Message)
    }
}

OnHoverToggle(ctrl, *) {
    global HoverEnabled := ctrl.Value
    IniWrite(HoverEnabled, IniFile, "Settings", "HoverEnabled")
    if !HoverEnabled {
        for hwnd, obj in HoverMap
            HoverEffect(obj, false)
    }
}

WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
    global LastHoveredHwnd, HoverEnabled
    if !HoverEnabled
        return
    try {
        MouseGetPos(,,, &currHwnd, 2)
        if (currHwnd != LastHoveredHwnd) {
            if HoverMap.Has(LastHoveredHwnd)
                HoverEffect(HoverMap[LastHoveredHwnd], false)
            if HoverMap.Has(currHwnd)
                HoverEffect(HoverMap[currHwnd], true)
            LastHoveredHwnd := currHwnd
        }
    }
}

HoverEffect(Ctrl, isEntering) {
    if isEntering {
         Ctrl.Opt("Background252525") 
        Ctrl.Opt("c" T_Col)           
    } else {
        if (Ctrl.Hwnd = Sys1Tx.Hwnd || Ctrl.Hwnd = Sys2Tx.Hwnd || Ctrl.Hwnd = Sys3Tx.Hwnd || Ctrl.Hwnd = Sys4Tx.Hwnd || (IsSet(Sys5Tx) && Ctrl.Hwnd = Sys5Tx.Hwnd))
             Ctrl.Opt("Background181818")
        else if (Ctrl.Hwnd = AFKBtnTxt.Hwnd)
             Ctrl.Opt("Background121212")
        else if (Ctrl.Hwnd = BtnReM_Tx.Hwnd || Ctrl.Hwnd = BtnReH_Tx.Hwnd)
             Ctrl.Opt("Background0A0A0A")
        else
             Ctrl.Opt("Background181818")
        Ctrl.Opt("cFFFFFF")
    }
}

SwitchMainTab(Idx, *) {
    global g_ActiveName, CurrentGadgets
    Loop 4 {
        Active := (A_Index = Idx)
        TabBorders[A_Index].Visible := Active
        TabTextCtrls[A_Index].Visible := true 
        for ctrl in TabContents[A_Index]
            ctrl.Visible := Active
    }
    if (Idx = 1) {
        for i, info in CurrentGadgets
            GadgetBorders[i].Visible := (info.N == g_ActiveName)
    }
    if (Idx = 2)
        SwitchSettings("Gadget")
}

SwitchSettings(Mode, *) {
    for key, controls in SettingGroups {
         isVisible := (key = Mode)
        for ctrl in controls
            ctrl.Visible := isVisible
        for g in SubTabGraphics[key]
            g.Visible := isVisible
    }
}

SetTheme(name, *) {
    global SavedTheme, CustomColor, T_Col
    if (name = "Custom" && (Picked := ChooseColor())) {
        CustomColor := Picked, Themes["Custom"] := Picked
         IniWrite(Picked, IniFile, "Settings", "CustomColor")
    }
    SavedTheme := name, IniWrite(name, IniFile, "Settings", "Theme"), T_Col := Themes[name]
    
    for ctrl in ThemeablePrimary
        ctrl.Opt("c" T_Col)
    for b in GadgetBorders
         b.Opt("Background" T_Col)
    for k, r in SwatchRings
        r.Opt("Background" (k=name ? T_Col : "333333"))
    for line in ThemeOutlines
        line.Opt("Background" T_Col)
    for b in TabBorders
        b.Opt("Background" T_Col)
    
    for mode, items in SubTabGraphics {
        for graphic in items
            graphic.Opt("Background" T_Col)
    }

    if SwatchIcons.Has("Custom")
        SwatchIcons["Custom"].Opt("c" T_Col)
        
     WinRedraw(MainGui.Hwnd)
}

SetActiveGadget(idx, *) {
    global g_TargetX, g_TargetY, g_ActiveName
    g_TargetX := CurrentGadgets[idx].X, g_TargetY := CurrentGadgets[idx].Y, g_ActiveName := CurrentGadgets[idx].N
    for b in GadgetBorders
        b.Visible := false
    GadgetBorders[idx].Visible := true
    StatusTxt.Value := g_ActiveName
}

ToggleAFK(ctrl) {
    global AFKEnabled := !AFKEnabled
    ctrl.Value := AFKEnabled ? "🛑 STOP AFK" : "🤖 START AFK"
    AFKStatusTxt.Value := AFKEnabled ? "RUNNING" : "INACTIVE"
    AFKStatusTxt.Opt("c" (AFKEnabled ? T_Col : "FFFFFF"))
    SetTimer(DoAFKAction, AFKEnabled ? 45000 : 0)
}

DoAFKAction() {
    if WinActive("ahk_exe FortniteClient-Win64-Shipping.exe")
        Send("{w down}"), Sleep(50), Send("{w up}")
}

HandleLaunch() {
    global GamePath
    if (GamePath != "" && FileExist(GamePath))
        Goto RunGame
    Drives := DriveGetList()
    Loop Parse, Drives {
        Root := A_LoopField ":\"
        for p in [Root "Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe", Root "Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe"] {
            if FileExist(p) {
                GamePath := p
                IniWrite(GamePath, IniFile, "Settings", "GamePath")
                Goto RunGame
            }
        }
    }
    Sel := FileSelect(3, , "Locate Fortnite (FortniteClient-Win64-Shipping.exe)")
    if !Sel
        return
    GamePath := Sel, IniWrite(GamePath, IniFile, "Settings", "GamePath")
RunGame:
    try Run("com.epicgames.launcher://apps/Fortnite?action=launch&silent=true")
    catch {
        SplitPath(GamePath, , &WorkingDir)
        try Run(GamePath, WorkingDir)
    }
}

HandleKill() {
    for p in ["FortniteClient-Win64-Shipping.exe", "FortniteLauncher.exe", "EpicGamesLauncher.exe"]
        try RunWait("taskkill /F /T /IM " p, , "Hide")
}

FactoryReset() {
    if MsgBox("This will wipe all settings and the game path. Continue?", "Factory Reset", "YesNo Icon!") = "Yes" {
        if FileExist(IniFile)
            FileDelete(IniFile)
        if DirExist(IniDir)
            DirDelete(IniDir, 1)
        Reload()
    }
}

OnDelayChange(s, *) {
    global SavedDelay := s.Value
    IniWrite(SavedDelay, IniFile, "Settings", "Delay")
    DelayDisp.Value := SavedDelay "ms"
}

OnSpamChange(s, *) {
    global SpamRatio := s.Value
     IniWrite(SpamRatio, IniFile, "Settings", "SpamRatio")
    SpamDisp.Value := SpamRatio
}

OnRCChange(s, *) {
    global RightClickDelay := s.Value
    IniWrite(RightClickDelay, IniFile, "Settings", "RightClickDelay")
    RCDisp.Value := RightClickDelay "ms"
}

OnResChange(ctrl, *) => (IniWrite(ctrl.Text, IniFile, "Settings", "Resolution"), Reload())

SpamLogic(*) {
    if (g_TargetX = 0)
        return
    while GetKeyState(SavedHotkey, "P") {
        MouseGetPos(&ox, &oy)
        MouseMove(g_TargetX, g_TargetY, 0), Click(), MouseMove(ox, oy, 0)
        Sleep(SavedDelay)
    }
}

StartAirhorn(*) {
    if !WinActive("ahk_exe FortniteClient-Win64-Shipping.exe")
        return
    HoldTime := Max(35, 120 - (SpamRatio * 10))
    while GetKeyState(AirhornHotkey, "P") {
        Send("{e down}"), Sleep(HoldTime), Send("{e up}"), Click("Right"), Sleep(Max(RightClickDelay, 2))
    }
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd = MainGui.Hwnd) {
        PostMessage(0xA1, 2,,, "ahk_id " hwnd)
        return 0
    }
}

RebindKey(ctrl, key) {
    while GetKeyState("LButton", "P")
        Sleep 10
    
    ctrl.Value := "PRESS ANY KEY..."
    ctrl.Opt("c" T_Col)
    
    ih := InputHook("L1 T5")
    ih.VisibleNonText := false
    ih.Start()
    
    startTime := A_TickCount
    capturedKey := ""

    while (ih.InProgress) {
        for mBtn in ["RButton", "MButton", "XButton1", "XButton2"] {
            if GetKeyState(mBtn, "P") {
                 ih.Stop()
                capturedKey := mBtn
                break
            }
        }
        if (capturedKey != "")
            break
        if (A_TickCount - startTime > 5000) {
            ih.Stop()
            break
        }
        Sleep 10
    }
    
    if (capturedKey == "" && ih.Input != "")
        capturedKey := ih.Input

    if (capturedKey != "") {
        UpdateKeyDynamic(capturedKey, key)
        ctrl.Value := "BOUND: " . StrUpper(capturedKey)
        SetTimer(() => (ctrl.Value := (key="ActivationKey" ? "REBIND MACRO" : "REBIND HORN"), ctrl.Opt("cFFFFFF")), -2000)
    } else {
        ctrl.Value := (key = "ActivationKey" ? "REBIND MACRO" : "REBIND HORN")
        ctrl.Opt("cFFFFFF")
    }
}

UpdateKeyDynamic(newName, iniKey) {
    global SavedHotkey, AirhornHotkey, MacroHK, HornHK
    cleanName := (StrLen(newName) = 1) ? StrUpper(newName) : newName
    IniWrite(cleanName, IniFile, "Settings", iniKey)
    
    try {
        if (iniKey == "ActivationKey") {
            try MacroHK.Opt("Off")
            SavedHotkey := cleanName
            MacroHK := Hotkey("~" . SavedHotkey, SpamLogic, "On")
        } else {
            try HornHK.Opt("Off")
             AirhornHotkey := cleanName
            HornHK := Hotkey("$" . AirhornHotkey, StartAirhorn, "On")
        }
    } catch Error as e {
        MsgBox("Failed to bind: " . cleanName . "`n`nReason: " . e.Message, "Binding Error", "IconX")
    }
}

ChooseColor() {
    CH := Buffer(A_PtrSize = 8 ? 72 : 36, 0), CC := Buffer(64, 0)
    NumPut("UInt", CH.Size, CH, 0), NumPut("Ptr", CC.Ptr, CH, A_PtrSize = 8 ? 32 : 16), NumPut("UInt", 0x00000103, CH, A_PtrSize = 8 ? 40 : 20)
    return DllCall("comdlg32\ChooseColor", "Ptr", CH) ? Format("{:02X}{:02X}{:02X}", (RGB := NumGet(CH, A_PtrSize = 8 ? 24 : 12, "UInt")) & 0xFF, (RGB >> 8) & 0xFF, (RGB >> 16) & 0xFF) : ""
}

F2::Reload()
~Del:: {
    global g_TargetX := 0
    StatusTxt.Value := "IDLE"
    for b in GadgetBorders
        b.Visible := false
}


