;===============================================
/*
POPUP HOTKEYS v1.8
Written using AutoHotkey_L v1.1.09.03+ (http://www.AHKScript.org)
By JnLlnd on AHK forum
*/ 
;===============================================


; ================================================
; Auto-execute commands
; ================================================

; --- COMPILER DIRECTIVES ---

; Doc: http://fincs.ahk4.net/Ahk2ExeDirectives.htm
; Note: prefix comma with `

;@Ahk2Exe-SetName PopupHotkeys 2
;@Ahk2Exe-SetDescription PopupHotkeys2
;@Ahk2Exe-SetVersion 1.8 BETA
;@Ahk2Exe-SetCopyright Jean Lalonde
;@Ahk2Exe-SetOrigFilename PopupHotkeys.exe

; --- SCRIPT DIRECTIVES ---

#Persistent ; Keeps a script permanently running
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases
#SingleInstance force ; Skips the dialog box and replaces the old instance automatically
#Include %A_ScriptDir%\PopupHotkeys_LANG.ahk

; --- OBJECTS AND ARRAYS VARIABLES ---

arrPopupHotkeysRequests := Array()
arrObjPopupHotkeys := Object()

; --- INIT FUNCTIONS ---

Gosub, CreateMenu
Gosub, LoadIni
Gosub, Gui1Build
Gosub, Gui1Load

Hotkey, %strPopupHotkeysSettingsHotkey%, Gui1Show
Hotkey, IfWinActive, PopupHotkeys ahk_class AutoHotkeyGUI ; Check the class name when compiled?
Hotkey, Esc, GuiClose
Hotkey, F1, Gui1Help
Hotkey, ^Up, Gui1MoveUp
Hotkey, ^Down, Gui1MoveDown
Hotkey, IfWinActive

; The following commands will create the requested hotkeys display a result report
; if the CreatePopupHotkeys parameter is "true".
Gosub, CreatePopupHotkeys

if blnDisplayReport
	MsgBox, 16, Popup Hotkeys, %strReport%

OnExit, ShowAllAndExit

return

; ================================================
; End of auto-execute commands
; ================================================



; ================================================
; POPUP HOTKEYS LOAD COMMANDS
; ================================================

; ------------------------------------------------
CreateMenu:
; ------------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\ico\Visualpharm-Icons8-Metro-Style-Computer-Hardware-Keyboard.ico, 1
Menu, Tray, Add ; Add a menu separator
Menu, Tray, Add, &PopupHotkeys Settings, Gui1Show ; Add a menu to the AHK tray icon to show settings windows
Menu, Tray, Add, &List Popup programs, Gui1List ; Add a menu to the AHK tray icon to list show all windows
Menu, Tray, Add, &Show all Popup programs, Gui1ShowAll ; Add a menu to the AHK tray icon to show all windows
Menu, Tray, Add, &Hide all Popup programs, Gui1HideAll ; Add a menu to the AHK tray icon to hide all windows
Menu, Tray, Add, &Terminate all Popup programs, Gui1TerminateAll ; Add a menu to the AHK tray icon to hide all windows
return
; ------------------------------------------------



; ------------------------------------------------
LoadIni:
; ------------------------------------------------
;@Ahk2Exe-IgnoreBegin
	; Piece of code for developement phase only
	if (A_ComputerName = "JEAN-PC") ; my personal hotkeys
		strIniFileName := "PopupHotkeys-MAISON.ini"
	else if InStr(A_ComputerName, "STIC") ; my work hotkeys
		strIniFileName := "PopupHotkeys-STIC.ini"
	else ; for other users
	; / Piece of code for developement phase only
;@Ahk2Exe-IgnoreEnd

strIniFileName := "PopupHotkeys.ini"
if !InStr(strIniFileName, "\") and !InStr(strIniFileName, "/")
	strIniFileName := A_ScriptDir . "\" . strIniFileName

if !FileExist(strIniFileName)
	FileAppend,
	(LTrim
		; Sample PopupHotkeys2 .ini file
		; ------------------------------

		[Global]
		; Hotkey to open PopupHotkeys settings window (by default Shift-Ctrl-K)
		PopupHotkeysSettingsHotkey=+^K
		; 1 to display a hotkeys loading report or 0 for a quiet loading of hotkeys
		DisplayLoadReport=1
		
		[Keys]
		; Key0=name | hotkey | exec_pathfile | working_directory | preload | window_identifier | startup_script | launch_delay | remark

		; Calc will be launched and hidden, with the root of C: drive as initial working
		; directory; hit Windows-C to show or hide Calc.
		Key1=Calc | #c | C:\Windows\system32\calc.exe | C:\ | | | | 5 | Windows-C

		; Notepad will be launched and the "SimpleStartupExample" function (at the
		; bottom of this script) will be executed. Then, the window will be hidden.
		; Hit the Zero key on the numeric keypad to show or hide Notepad.
		Key2=Notepad Startup | Numpad0 | C:\Windows\system32\notepad.exe | | | | SimpleStartupExample.ahk | | Numpad Zero

		; At the firt hit of the Right Control key (at the right of the Space bar),
		; iTunes will be launched and hidden; because of iTunes process behaviour, it is
		; safer to identify the program with its class name "iTunes"; hit the Right
		; Control key again to show or hide iTunes.
		Key3=iTunes | RControl | C:\Program Files (x86)\iTunes\iTunes.exe | | 1 | ahk_class iTunes | | 30 | Right Control
	
	), %strIniFileName%

; blnDisplayReport: 1 to display a hotkeys loading report or 0 for a quiet loading of hotkeys
IniRead, blnDisplayReport, %strIniFileName%, Global, DisplayLoadReport, 0
IniRead, strPopupHotkeysSettingsHotkey, %strIniFileName%, Global, PopupHotkeysSettingsHotkey, +^K

Loop
{
	IniRead, strKeyLine, %strIniFileName%, Keys, Key%A_Index%
	if (strKeyLine = "ERROR")
		Break
	arrPopupHotkeysRequests.Insert(strKeyLine)
}
return
; ------------------------------------------------



; ------------------------------------------------
Gui1Build:
; ------------------------------------------------
Gui, -MaximizeBox +Theme -ToolWindow
Gui, 1:Font, s12 w700, Verdana
Gui, 1:Add, Text, x10 y10 w490 h30, Popup Hotkeys v2
Gui, 1:Font, s8 w400, Verdana
Gui, 1:Add, Text, x10 y30 w490 h30, Popup Hotkeys v2
Gui, 1:Add, Picture, x4 y75 w16 h-1 gGui1Help, %A_ScriptDir%\ico\Visualpharm-Icons8-Metro-Style-System-Help.ico
Gui, 1:Add, Picture, x4 y100 w16 h-1 vpicMoveUp gGui1MoveUp, %A_ScriptDir%\ico\Arrows-Up-icon-16.png
Gui, 1:Add, Picture, x4  y120 w16 h-1 vpicMoveDown gGui1MoveDown, %A_ScriptDir%\ico\Arrows-Down-icon-16.png
Gui, 1:Add, ListView, x25 y70 w460 h340 AltSubmit vlvHotkeys gLvHokeysEvents, Name|Hotkey|Remark|Load
Gui, 1:Add, Button, x500 y70 w100 h20 gGui1Add, &Add...
Gui, 1:Add, Button, x500 y100 w100 h20 gGui1Edit, &Edit...
Gui, 1:Add, Button, x500 y130 w100 h20 gGui1Delete, &Delete...
Gui, 1:Add, Button, x500 y170 w100 h20 gGui1List, &List Hotkeys...
Gui, 1:Add, Button, x500 y200 w100 h20 gGui1ShowAll, &Show All
Gui, 1:Add, Button, x500 y230 w100 h20 gGui1HideAll, &Hide All
Gui, 1:Add, Button, x500 y260 w100 h20 gGui1TerminateAll, &Terminate All
Gui, 1:Font, s9 w700, Verdana
Gui, 1:Add, Text, x500 y290 w100 h20, Options
Gui, 1:Font, s8 w400, Arial
Gui, 1:Add, Text, x500 y310 w100 h20, Settings Hot&key
Gui, 1:Add, Hotkey, x500 y325 w100 h30 limit131 vstrPopupHotkeysSettingsHotkey, %strPopupHotkeysSettingsHotkey%
; limit131 = 1: Prevent unmodified keys + 2: Prevent Shift-only keys + 128: Prevent Shift-Control-Alt keys
Gui, 1:Add, Checkbox, x500 y350 w110 h30 +0x10 vblnDisplayReport, &Display load report
Gui, 1:Font, s9 w700, Arial
Gui, 1:Add, Button, x500 y390 w100 h20 gGuiClose, &Close
Gui, 1:Font, s9 w400, Arial
; Generated using SmartGuiXP Creator mod 4.3.29.0
return
; ------------------------------------------------



; ------------------------------------------------
Gui1Load:
; ------------------------------------------------
for intIndex, strRequest in arrPopupHotkeysRequests
{
	StringSplit arrRequest, strRequest, |
	LV_Add(""
		, Trim(arrRequest1) ; Name
		, Trim(arrRequest2) ; Hotkey
		, Trim(arrRequest9) ; Remark
		, Trim(arrRequest5) <> "1" ? "No" : "Yes") ; Preload
}

GuiControl, , blnDisplayReport, %blnDisplayReport%
GuiControl, , strPopupHotkeysSettingsHotkey, %strPopupHotkeysSettingsHotkey%
Loop, 4
	LV_ModifyCol(A_Index, "AutoHdr")
return
; ------------------------------------------------



; ------------------------------------------------
CreatePopupHotkeys:
; ------------------------------------------------
; For each request in the array arrPopupHotkeysRequests, run the executable (except if no_preload is present),
; call the startup script (if present), hide the window and create the hotkey. For each request, add an
; entry in the array of hotkeys objects arrObjPopupHotkeys with the info about a request (hotkey as array index,
; hotkey name, executable path, and the optional working directory, window ID and startup routine). When one of
; the hotkeys will be invoked, the info associated with this hotkey will be retrieved from the arrObjPopupHotkeys
; array by the subroutine PopupHotkey (below) in order to show/hide or re-run the executable.

Gosub, InitHotkeyErrors

strReport := "POPUP HOTKEYS REPORT`n"
for intIndexNotUsed, strRequest in arrPopupHotkeysRequests
{
	StringSplit arrRequest, strRequest, |
	strName := Trim(arrRequest1)
	strKey := Trim(arrRequest2)
	strExecPath := Trim(arrRequest3)
	strWorkDir := Trim(arrRequest4)
	blnPreload := Trim(arrRequest5) = "1"
	strIniWinId := Trim(arrRequest6)
	strStartupScript := Trim(arrRequest7)
	intLaunchDelay := Trim(arrRequest8)
	if intLaunchDelay is not integer ; no ( ) for this if, it is not an expression
		intLaunchDelay := 10
	else if (intLaunchDelay < 0)
		intLaunchDelay := 10
	strRemark := Trim(arrRequest9)

	strThisKeyReport := ""

	if (blnPreload)
		Gosub, RunExecPathOnLoad
	else
		if (strIniWinId)
			strWindowID := strIniWinId ; we use the user defined window identifier
		else
			strWindowID := "ahk_pid 9999999"
			; the program was not preloaded, so we don't have a pid - create a dummy pid that will be replaced when
			; hotkey is pressed (no process should have id 9999999)
	strPopKeyLabel := GetPopHotkeyLabel(strKey)
	arrObjPopupHotkeys[strPopKeyLabel] := Object("KeyLabel", strPopKeyLabel			; 0
												, "KeyName", strName				; 1
												, "KeyHotkey", strKey				; 2
												, "KeyExecPath", strExecPath		; 3
												, "KeyWorkDir", strWorkDir			; 4
												, "Preload", blnPreload				; 5
												, "KeyIniWinID", strIniWinId		; 6
												, "KeyStartup", strStartupScript	; 7
												, "LaunchDelay", intLaunchDelay		; 8
												, "KeyRemark", strRemark			; 9
												, "KeyWindowID", strWindowID)		; 10
	Hotkey, %strKey%, PopupHotkey, UseErrorLevel ; http://www.autohotkey.com/docs/commands/Hotkey.htm
	if (errorLevel)
		strThisKeyReport := strThisKeyReport . "ERROR: " . arrHotkeyErrors[errorLevel] "`n"

	; void the array to make sure old values could not be used in the next loop
	strRequest := "||||||||"
	StringSplit arrRequest, strRequest, |

	strReport := strReport . "`nCreation of " . strName . " (" . strKey . ") -> "
	if StrLen(strThisKeyReport)
		strReport := strReport . strThisKeyReport
	else
		strReport := strReport . "OK`n"
}
return
; ------------------------------------------------



; ------------------------------------------------
InitHotkeyErrors:
; ------------------------------------------------
arrHotkeyErrors[1] := "The Label parameter specifies a nonexistent label name."
arrHotkeyErrors[2] := "The KeyName parameter specifies one or more keys that are either not recognized or not supported by the current keyboard layout/language."
arrHotkeyErrors[3] := "Unsupported prefix key. For example, using the mouse wheel as a prefix in a hotkey such as WheelDown & Enter is not supported."
arrHotkeyErrors[4] := "The KeyName parameter is not suitable for use with the AltTab or ShiftAltTab actions. A combination of two keys is required. For example: RControl & RShift::AltTab"
arrHotkeyErrors[5] := "The command attempted to modify a nonexistent hotkey."
arrHotkeyErrors[6] := "The command attempted to modify a nonexistent variant of an existing hotkey. To solve this, use ""Hotkey IfWin"" to set the criteria to match those of the hotkey to be modified."
arrHotkeyErrors[50] := "Windows 95/98/Me: The command completed successfully but the operating system refused to activate the hotkey. This is usually caused by the hotkey being ""in use"" by some other script or application (or the OS itself). This occurs only on Windows 95/98/Me because on other operating systems, the program will resort to the keyboard hook to override the refusal."
arrHotkeyErrors[51] := "Windows 95/98/Me: The command completed successfully but the hotkey is not supported on Windows 95/98/Me. For example, mouse hotkeys and prefix hotkeys such as ""a & b"" are not supported."
arrHotkeyErrors[98] := "Creating this hotkey would exceed the 1000-hotkey-per-script limit (however, each hotkey can have an unlimited number of variants, and there is no limit to the number of hotstrings)."
arrHotkeyErrors[99] := "Out of memory. This is very rare and usually happens only when the operating system has become unstable."
return
; ------------------------------------------------



; ------------------------------------------------
RunExecPathOnLoad:
; ------------------------------------------------
Run, %strExecPath%, %strWorkDir%, UseErrorLevel, intExecPID
if (ErrorLevel = "ERROR")
	strThisKeyReport := strThisKeyReport . "ERROR: Could not launch """ . strExecPath . """ (error #" 
		. A_LastError . ")`n"
else
{
	if (strIniWinId)
		strWindowID := strIniWinId ; we use the user defined window identifier
	else
		strWindowID := "ahk_pid " . intExecPID ;  we use the pid
	DetectHiddenWindows, On
	WinWait, %strWindowID%, , %intLaunchDelay%
	if errorlevel
		strThisKeyReport := strThisKeyReport . "ERROR: Delay while launching """ . strExecPath 
			. """ (augment LaunchDelay in settings?)`n"
	Sleep, 200
	if StrLen(strStartupScript)
	{
		if !InStr(strStartupScript, "\") and !InStr(strStartupScript, "/")
			strStartupScript := A_ScriptDir . "\" . strStartupScript
		if FileExist(strStartupScript)
		{
			RunWait, %strStartupScript% "%strWindowID%", UseErrorLevel
			if (ErrorLevel)
				strThisKeyReport := strThisKeyReport . "ERROR: Error #" . ErrorLevel 
					. " after running startup macro """ . strStartupScript . """`n"
		}
		else
			strThisKeyReport := strThisKeyReport . "ERROR: Startup macro """ . strStartupScript . """ not found`n"
	}
	WinHide, %strWindowID%
}
return
; ------------------------------------------------



; ================================================
; POPUP HOTKEYS PERSISTENT COMMANDS
; ================================================

; ------------------------------------------------
PopupHotkey:
; ------------------------------------------------
; This subroutine is invoked when one of the hotkeys is pressed. The info associated with this
; hotkey is retrieved from the arrObjPopupHotkeys array. Then, one of these four scenario will
; be executed:
; 1) If the executable associated with this hotkey is visible and active, its window is hidden
;    ??? and the window that was active previously is re-activated /???.
; 2) If the executable associated with this hotkey is inactive, it is activated.
; 3) If the executable associated with this hotkey is hidden, it is shown and activated.
; 4) Finaly, if the executable associated with this hotkey does not exist, it is loaded and
;    the startup script (if present) is executed.
Critical ; Prevents the current thread from being interrupted by other threads.
strPopKeyLabel := GetPopHotkeyLabel(A_ThisHotkey)
strWindowID := arrObjPopupHotkeys[strPopKeyLabel].KeyWindowID

; Identification of the window associated with this hotkey (for example: "akh_pid 123" or "akh_class iTunes")
DetectHiddenWindows, Off
IfWinActive, %strWindowID%
	; hotkey program window is active and is visible, so hide it, reset previous window (if known) and exit
	Gosub, HideWindow
else
{
	DetectHiddenWindows, On
	IfWinActive, %strWindowID% ; hotkey program window is active but not visible, so show it and exit
		WinShow, %strWindowID%
	else
	{
		; hotkey program is not active, remember the window that was active before we reactivate it
		strWindowBeforeHotkeyID := WinExist("A")
		IfWinExist, %strWindowID%
		{
			; hotkey program window exists, visible or not (we don't care here), but is not active,
			; so show it, activate it and exit
			WinShow, %strWindowID% ; in case it was not visible
			WinActivate, %strWindowID%
		}
		else ; hotkey program window does not exist, so start it
			Gosub, RunExecPathAfterLoad
	}
}
return
; ------------------------------------------------



; ------------------------------------------------
HideWindow:
; ------------------------------------------------
WinHide, %strWindowID%
MouseGetPos, , , strWinMouseId
if (strWindowBeforeHotkeyID = strWinMouseId)
{
	; If mouse over previous window, reactivate it. If not leave it as is.
	; Reactivate the previous window, leaving the hotkey program window as is (hidden or not).
	WinActivate, ahk_id %strWindowBeforeHotkeyID%
	strWindowBeforeHotkeyID := ; kill previous window variable
}
return
; ------------------------------------------------



; ------------------------------------------------
RunExecPathAfterLoad:
; ------------------------------------------------
strExecPath := arrObjPopupHotkeys[strPopKeyLabel].KeyExecPath
strWorkDir := arrObjPopupHotkeys[strPopKeyLabel].KeyWorkDir
strStartupScript := arrObjPopupHotkeys[strPopKeyLabel].KeyStartup
intLaunchDelay := arrObjPopupHotkeys[strPopKeyLabel].LaunchDelay
Run, %strExecPath%, %strWorkDir%, UseErrorLevel, intExecPID
if (ErrorLevel = "ERROR")
	MsgBox, 16, Popup Hotkeys, ERROR: Could not launch %strExecPath%
else
{
	if (arrObjPopupHotkeys[strPopKeyLabel].KeyWindowID = "")
		or (InStr(arrObjPopupHotkeys[strPopKeyLabel].KeyWindowID, "ahk_pid"))
		; save or update the new pid in the array associated to this hotkey
		arrObjPopupHotkeys[strPopKeyLabel].KeyWindowID := "ahk_pid " . intExecPID
	strWindowID := arrObjPopupHotkeys[strPopKeyLabel].KeyWindowID
	DetectHiddenWindows, On
	WinWait, %strWindowID%, , %intLaunchDelay%
	if errorlevel
		MsgBox, 16, Popup Hotkeys
			, ERROR: Delay while launching %strExecPath% (%strWindowID%). Augment the WinWait delay?
	Sleep, 200
	if StrLen(strStartupScript)
	{
		if !InStr(strStartupScript, "\") and !InStr(strStartupScript, "/")
			strStartupScript := A_ScriptDir . "\" . strStartupScript
		if FileExist(strStartupScript)
		{
			RunWait, %strStartupScript% "%strWindowID%", UseErrorLevel
			if (ErrorLevel)
				MsgBox, 16, Popup Hotkeys, ERROR: Error #%ErrorLevel% after running startup macro "%strStartupScript%"
		}
		else
			MsgBox, 16, Popup Hotkeys, ERROR: Script "%strStartupScript%" not found
	}
}
return
; ------------------------------------------------



; ------------------------------------------------
ShowAllAndExit:
; ------------------------------------------------
Gosub, Gui1ShowAll
ExitApp ; Remove all hotkeys and terminates this persistent script
; ------------------------------------------------



; ================================================
; POPUP HOTKEYS GUI1 COMMANDS
; ================================================

; ------------------------------------------------
Gui1Show:
; ------------------------------------------------
Gui, 1:Show, Center w610 h420, PopupHotkeys v2
GuiControl, Focus, lvHotkeys
LV_Modify(1, "Focus")
LV_Modify(0, "-Select")
LV_Modify(1, "Select")
Gosub, Gui1UpdateButtons
blnSomethingToSave := False
return
; ------------------------------------------------



; ------------------------------------------------
Gui1UpdateButtons:
; ------------------------------------------------
intNbOfRows := LV_GetCount()
intSelectedRow := LV_GetNext(0, "Focused")
; if !(intSelectedRow)
;	intSelectedRow := 1
LV_Modify(intSelectedRow, "Select")
GuiControl % (intNbOfRows = 0) ? "Disable" : "Enable", &Remove
GuiControl, , picMoveUp, % A_ScriptDir . "\ico\Arrows-Up-icon-16" . (intSelectedRow <= 1 ? "-grey.png" : ".png")
GuiControl, , picMoveDown, % A_ScriptDir . "\ico\Arrows-Down-icon-16" . (intSelectedRow = intNbOfRows ? "-grey.png" : ".png")
return
; ------------------------------------------------


; ------------------------------------------------
Gui1Help:
; ------------------------------------------------
Help("Help`n`nArrow (^Up/^Down) to change load order`n`nAdd, Edit, Delete`n`nList Hotkeys, Show All, Hide All, Terminate All`n`nOptions Setting Hotkey, Display load report`n`nClose (Esc)")
return
; ------------------------------------------------



; ------------------------------------------------
Gui1MoveUp:
; ------------------------------------------------
intSelectedRow := LV_GetNext()
if (intSelectedRow <= 1)
	return
LV_Modify(0, "-Select")

LV_GetText(strThisName, intSelectedRow, 1)
LV_GetText(strThisHotkey, intSelectedRow, 2)
LV_GetText(strThisRemark, intSelectedRow, 3)
LV_GetText(strThisPreload, intSelectedRow, 4)

LV_GetText(strPrevName, intSelectedRow - 1, 1)
LV_GetText(strPrevHotkey, intSelectedRow - 1, 2)
LV_GetText(strPrevRemark, intSelectedRow - 1, 3)
LV_GetText(strPrevPreload, intSelectedRow - 1, 4)

LV_Modify(intSelectedRow, "", strPrevName, strPrevHotkey, strPrevRemark, strPrevPreload)
LV_Modify(intSelectedRow - 1, "Focus Select", strThisName, strThisHotkey, strThisRemark, strThisPreload)
blnSomethingToSave := True
return
; ------------------------------------------------


; ------------------------------------------------
Gui1MoveDown:
; ------------------------------------------------
intNbOfRows := LV_GetCount()
intSelectedRow := LV_GetNext()
if (intSelectedRow = intNbOfRows)
	return
LV_Modify(0, "-Select")

LV_GetText(strThisName, intSelectedRow, 1)
LV_GetText(strThisHotkey, intSelectedRow, 2)
LV_GetText(strThisRemark, intSelectedRow, 2)
LV_GetText(strThisPreload, intSelectedRow, 2)

LV_GetText(strNextName, intSelectedRow + 1, 1)
LV_GetText(strNextHotkey, intSelectedRow + 1, 2)
LV_GetText(strNextRemark, intSelectedRow + 1, 2)
LV_GetText(strNextPreload, intSelectedRow + 1, 2)

LV_Modify(intSelectedRow, "", strNextName, strNextHotkey, strNextRemark, strNextPreload)
LV_Modify(intSelectedRow + 1, "Focus Select", strThisName, strThisHotkey, strThisRemark, strThisPreload)
blnSomethingToSave := True
return
; ------------------------------------------------


; ------------------------------------------------
Gui1Add:
; ------------------------------------------------
return
; ------------------------------------------------


; ------------------------------------------------
Gui1Edit:
; ------------------------------------------------
return
; ------------------------------------------------



; ------------------------------------------------
Gui1Delete:
; ------------------------------------------------
return
; ------------------------------------------------



; ------------------------------------------------
Gui1List:
; ------------------------------------------------
strList := ""
for intIndexNotUsed, objPopupHotkey in arrObjPopupHotkeys
{
	for strKey, strVal in objPopupHotkey
		strList := strList . strKey . ": " . strVal . "`n"
	strList := strList . "`n"
}
MsgBox, 64, Popup Hotkeys, %strList%
return
; ------------------------------------------------



; ------------------------------------------------
Gui1ShowAll:
; ------------------------------------------------
for intIndexNotUsed, objPopupHotkey in arrObjPopupHotkeys
{
	strWindowID := objPopupHotkey.KeyWindowID
	WinShow, %strWindowID% ; No error and no action if window is not found
	WinActivate, %strWindowID% ; No error and no action if window is not found
}
return
; ------------------------------------------------



; ------------------------------------------------
Gui1HideAll:
; ------------------------------------------------
for intIndexNotUsed, objPopupHotkey in arrObjPopupHotkeys
{
	strWindowID := objPopupHotkey.KeyWindowID
	WinHide, %strWindowID% ; No error and no action if window is not found
}
return
; ------------------------------------------------



; ------------------------------------------------
Gui1TerminateAll:
; ------------------------------------------------
for intIndexNotUsed, objPopupHotkey in arrObjPopupHotkeys
{
	strWindowID := objPopupHotkey.KeyWindowID
	; In case the window is hidden, make sure Save data dialog box could be seen.
	; No error and no action if window is not found.
	WinShow, %strWindowID%
	; Closes the specified window. Unlike WinKill, this command will give the user a chance to save its unsaved data.
	WinClose, %strWindowID%
}
return
; ------------------------------------------------



; ------------------------------------------------
GuiClose:
; ------------------------------------------------
if (blnSomethingToSave)
	Gosub, Gui1Save
Gui, Cancel
return
; ------------------------------------------------


; ------------------------------------------------
Gui1Save:
; ------------------------------------------------
MsgBox, 8195, PopupHotkeys v2 - Close, Saves changes to settings file?
IfMsgBox, Cancel
	return
IfMsgBox, No
{
	Gui, Cancel
	return
}
strPrevSettingsHotkey := strPopupHotkeysSettingsHotkey
Gui, 1:Submit, NoHide
Loop, % LV_GetCount("")
{
	LV_GetText(strKey, A_Index , 2)
	strPopKeyLabel := GetPopHotkeyLabel(strKey)
	strKeyIni := arrObjPopupHotkeys[strPopKeyLabel].KeyName			; 1
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].KeyHotkey		; 2
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].KeyExecPath	; 3
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].KeyWorkDir		; 4
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].Preload		; 5
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].KeyIniWinID	; 6
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].KeyStartup		; 7
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].LaunchDelay	; 9
		. " | " . arrObjPopupHotkeys[strPopKeyLabel].KeyRemark		; 9
	IniWrite, %strKeyIni%, %strIniFileName%, Keys, Key%A_Index%
}
if (strPopupHotkeysSettingsHotkey <> strPrevSettingsHotkey)
{
	Hotkey, %strPopupHotkeysSettingsHotkey%, Gui1Show, UseErrorLevel
	; http://www.autohotkey.com/docs/commands/Hotkey.htm
	if (errorLevel)
	{
		strPopupHotkeysSettingsHotkey := strPrevSettingsHotkey
		Hotkey, %strPopupHotkeysSettingsHotkey%, Gui1Show
		MsgBox, 48, "ERROR: " . arrHotkeyErrors[errorLevel]
	}
	else
	{
		IniWrite, %strPopupHotkeysSettingsHotkey%, %strIniFileName%, Global, PopupHotkeysSettingsHotkey
		Hotkey, %strPrevSettingsHotkey%, Off
	}
}
IniWrite, %blnDisplayReport%, %strIniFileName%, Global, DisplayLoadReport
return
; ------------------------------------------------




; ================================================
; LISTVIEW HOTKEYS EVENTS
; ================================================


; ------------------------------------------------
LvHokeysEvents:
; ------------------------------------------------
Gosub, Gui1UpdateButtons
; ###
/*
if (A_GuiEvent = "DoubleClick")
{
	intRowNumber := A_EventInfo
	Gosub, MenuEditRow
}
SB_SetText(L(lLvEventsrecordsselected, LV_GetCount("Selected")), 2)
*/
return
; ------------------------------------------------



; ------------------------------------------------
GuiContextMenu: ; Launched in response to a right-click or press of the Apps key.
; ------------------------------------------------
; ###
/*
if A_GuiControl <> lvData  ; Display the menu only for clicks inside the ListView.
    return
if !LV_GetCount("")
	return
intRowNumber := A_EventInfo
Menu, SelectMenu, Add, % L(lLvEventsSelectAll), MenuSelectAll
Menu, SelectMenu, Add, % L(lLvEventsDeselectAll), MenuSelectNone
Menu, SelectMenu, Add, % L(lLvEventsReverseSelection), MenuSelectReverse
Menu, SelectMenu, Add, % L(lLvEventsEditrowMenu), MenuEditRow
Menu, SelectMenu, Add, % L(lLvEventsDeleteRowMenu), MenuDeleteRow
; Show the menu at the provided coordinates, A_GuiX and A_GuiY.  These should be used
; because they provide correct coordinates even if the user pressed the Apps key:
Menu, SelectMenu, Show, %A_GuiX%, %A_GuiY%
*/
return
; ------------------------------------------------



; ================================================
; POPUP HOTKEYS FUNCTIONS
; ================================================


; ------------------------------------------------
GetPopHotkeyLabel(strKey)
; ------------------------------------------------
; Create a Popup specific label from a key or key combination. This label will be used
; as array index to store/retreive info like hotkey, path, etc. in the array
; arrObjPopupHotkeys. This label start with "pop" followed by the key name. To make sure
; this label complies with AutoHotkey conventions, chars not included in A..Z or 0..1
; are replaced by # and the ASCII value of the char.
{
	strResult := "pop"
	Loop, Parse, strKey
	{
		if Instr("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", A_LoopField)
			strAdd := A_LoopField
		else
			strAdd := "#" . Asc(A_LoopField)
		strResult := strResult . strAdd
	}
	return strResult
}
; ------------------------------------------------



; ------------------------------------------------
Help(strMessage, objVariables*)
; ------------------------------------------------
{
	Gui, 1:+OwnDialogs 
	StringLeft, strTitle, strMessage, % InStr(strMessage, "$") - 1
	StringReplace, strMessage, strMessage, %strTitle%$
	MsgBox, 0, % L(lFuncHelpTitle, lAppName, lAppVersionLong, strTitle), % L(strMessage, objVariables*)
}
; ------------------------------------------------



; ------------------------------------------------
Oops(strMessage, objVariables*)
; ------------------------------------------------
{
	Gui, 1:+OwnDialogs
	MsgBox, 48, % L(lFuncOopsTitle, lAppName, lAppVersionLong), % L(strMessage, objVariables*)
}
; ------------------------------------------------



; ------------------------------------------------
L(strMessage, objVariables*)
; ------------------------------------------------
{
	Loop
	{
		if InStr(strMessage, "~" . A_Index . "~")
			StringReplace, strMessage, strMessage, ~%A_Index%~, % objVariables[A_Index]
 		else
			break
	}
	return strMessage
}
; ------------------------------------------------

