;Author: KuroiLight - klomb - <kuroilight@openmailbox.org>
;Licensed under: Creative Commons Attribution 3.0 Unported (CC-BY) found at http://creativecommons.org/licenses/by/3.0/legalcode
;Settings*******************
ListLines Off
SetBatchLines -1
#NoEnv
#SingleInstance force
#Persistent
;#Warn
CoordMode, Mouse, Screen
SetWorkingDir %A_ScriptDir%
;Global Vars****************
SCRIPTNAME := RegExReplace(A_Scriptname, "(?:(\w+).+)", "$1")
;Tray***********************
Menu, Tray, NoStandard
Menu, Tray, Tip, %SCRIPTNAME%
Menu, Tray, Add, Enabled, ToggleScript
Menu, Tray, Check, Enabled
Menu, Tray, Add, Edit Filter, OpenFilter
Menu, Tray, Add,
Menu, Tray, Add, Restart, _Reload
Menu, Tray, Add, Exit, _ExitApp
;Startup********************
AskStartupShortcut()
SetTimer, NewLoop, 250
return

_ExitApp() {
    ExitApp, 0
}

_Reload() {
    Reload
}

ToggleScript() {
    static StopScript := "Off"
    StopScript := (StopScript = "On" ? "Off" : "On")
    Menu, Tray, % (StopScript = "Off" ? "Check" : "UnCheck"), Enabled
    Suspend, %StopScript%
    Pause, %StopScript%
}

OpenFilter() {
    RunWait, % "ruleset.txt",, UseErrorLevel,
    if(ErrorLevel != "ERROR")
        Reload
}

DisplayError(msg, value := "", textline := "", linenumber := "") {
    if(value)
        msg .= "`nValue: " value
    if(textline)
        msg .= "`nTextLine: " textline
    if(linenumber)
        msg .= "`nCodeLN: " (linenumber-1)
    msg .= "`n`n<if you think this message is a programming error, send it to the author>`n<ctrl+c to copy and ctrl+v to paste this messsage>"
    MsgBox, % msg
}

RulesetFromFile() {
    filename := "ruleset.txt"
    ruleset_array := Object()
    
    SysGet, MonCount, MonitorCount
    if(MonCount <= 1)
        DisplayError("Not enough monitors, script may not work as intended.", MonCount,, A_LineNumber)
    
    hFile := FileOpen(filename, "rw -rwd `n")
    if(!hFile) { ;;return empty array
        DisplayError("Failed to open '" . filename . "'`nERROR " . A_LastError,,, A_LineNumber)
        return ruleset_array
    }
    
    ;;if file is blank/new then write default rules to it and seek back
    if(hFile.Length == 0) {
        hFile.Write("class|Progman|0`nclass|WorkerW|0`nclass|Shell_TrayWnd|0`nclass|Shell_SecondaryTrayWnd|0")
        hFile.Seek(0, 0)
    }
    
    While(!hFile.AtEOF) {
        current_line := StrReplace(hFile.ReadLine(), "`n", "")
        if(RegExMatch(current_line, "S)(^#|^\s*$)")) ;if blank or comment line, skip
            continue
        
        current_sections := StrSplit(current_line, "|")
        
        if(current_sections.Length() <> 3 or current_sections[1] == "" or current_sections[2] == "" or current_sections[3] == "") {
            DisplayError("Too many/few sections, or one or more sections are blank", current_sections.Length(), current_line, A_LineNumber)
            continue
        }
        sType := current_sections[1], sMonitor := current_sections[3]
        if(!RegExMatch(sType, "S)^(exe|title|ititle|class)$")) {
            DisplayError("sType is an invalid value, must be exe, title, ititle or class", sType, current_line, A_LineNumber)
            continue
        }
        ;(sMonitor ? sMonitor : "0")
        if(!RegExMatch(sMonitor, "S)^!?(m|[0-" . MonCount . "])$")) {
            DisplayError("sMonitor is an invalid value, must be a value from 0 to " . MonCount . " or the letter 'm'", sMonitor, current_line, A_LineNumber)
            continue
        }
        
        ruleset_array.InsertAt(ruleset_array.Length()+1, current_sections)
    }
    
    hFile.Close()
    return ruleset_array
}

GetRuleFor(win) {
    static ruleset := RulesetFromFile()
    
    if(!win)
        return

    for k, v in ruleset {
        if(v[1] = "class") {
            if(!wClass)
                WinGetClass, wClass, ahk_id %win%
            if(v[2] == wClass)
                return v[3]
        } else if(v[1] = "exe") {
            if(!pName)
                WinGet, pName, ProcessName, ahk_id %win%
            if(v[2] = pName)
                return v[3]
        } else if(v[1] = "title") {
            if(!wTitle)
                WinGetTitle, wTitle, ahk_id %win%
            if(InStr(wTitle, v[2], true))
                return v[3]
        } else if(v[1] = "ititle") {
            if(!wTitle)
                WinGetTitle, wTitle, ahk_id %win%
            if(InStr(wTitle, v[2], false))
                return v[3]
        }
    }
    
    return "m"
}

CenterWindow(win, mon) {
    if(!win or !mon)
        return
    
    WinGetPos, wX, wY, wW, wH, ahk_id %win%
    wCenterX := wW / 2 + wX, wCenterY := wH / 2 + wY
    
    if(mon[1] != "!" and !IsPointOffscreen(wCenterX, wCenterY, mon))
        return

    WinGet, s, Style, ahk_id %win%
    if(s & 0x01000000) {
        WinRestore, ahk_id %win%
        CenterWindow(win, mon)
        WinMaximize, ahk_id %win%
    } else {
        mon := StrReplace(mon, "!", "")
        SysGet, m, Monitor, %mon%
        
        sCenterX := mLeft + ((mRight - mLeft) / 2), sCenterY := mTop + ((mBottom - mTop) / 2)
        newX := sCenterX - (wW / 2), newY := sCenterY - (wH / 2)
        
        WinMove, ahk_id %win%,, newX, newY, wW, wH
    }

}

IsPointOffscreen(x, y, mon) {
    if(GetMonitorAtPoint(x, y) == mon)
        return false
    else
        return true
}

GetMonitorAtPoint(x, y) {
    SysGet, MonCount, MonitorCount
    Loop %MonCount% {
        SysGet, m, Monitor, %A_Index%
        if(x >= mLeft and x <= mRight and y >= mTop and y <= mBottom) {
            return A_Index
        }
    }
    return 0
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;NEW CODE
NewLoop() {
    static CurrentWindows := GetVisibleWindows()
    PreviousWindows := CurrentWindows
    CurrentWindows := GetVisibleWindows()
    
    MouseGetPos, mX, mY
    mousemonitor := GetMonitorAtPoint(mX, mY)
    
    for i, k in CurrentWindows {
        if(!PreviousWindows[i]) {
            rule := StrReplace(GetRuleFor(i), "m", mousemonitor)
            CenterWindow(i, rule)
        }
    }
}

GetVisibleWindows() {
    aWindows := {}
    
    WinGet, current_windows, List
    Loop, %current_windows% {
        if(IsProperWindow(current_windows%A_Index%))
            aWindows[current_windows%A_Index% + 0] := 1
    }
    
    return aWindows
}

IsProperWindow(window_id) {
    if(!window_id)
        throw, Exception("Null Param Value Exception: window_id")
    WinGet, ws_style, Style, ahk_id %window_id%
    if(!(ws_style & 0x10000000) or !(ws_style & 0x00080000))
        return false
    return true
}

#include startupshortcut.ahk