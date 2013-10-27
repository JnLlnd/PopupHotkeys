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

; --- OBJECTS AND ARRAYS VARIABLES ---

arrPopupHotkeysRequests := Array()
arrObjPopupHotkeys := Object()

; --- INIT FUNCTIONS ---

Gosub, CreateMenu
Gosub, LoadIni

; The following commands will create the requested hotkeys display a result report
; if the CreatePopupHotkeys parameter is "true".
Gosub, CreatePopupHotkeys

if blnDisplayReport
	MsgBox, 16, Popup Hotkeys, %strReport%

return

; ================================================
; End of auto-execute commands
; ================================================



; ================================================
; POPUP HOTKEYS ROUTINES
; ================================================


; ------------------------------------------------
CreateMenu:
; ------------------------------------------------
Menu, Tray, Icon, %A_ScriptDir%\ico\Visualpharm-Icons8-Metro-Style-Computer-Hardware-Keyboard.ico, 1
Menu, Tray, Add ; Add a menu separator
Menu, Tray, Add, &List Popup programs, ListAllWindow ; Add a menu to the AHK tray icon to list show all windows
Menu, Tray, Add, &Show all Popup programs, ShowAllWindow ; Add a menu to the AHK tray icon to show all windows
Menu, Tray, Add, &Hide all Popup programs, HideAllWindow ; Add a menu to the AHK tray icon to hide all windows
Menu, Tray, Add, &Terminate all Popup programs, TerminateAllWindow ; Add a menu to the AHK tray icon to hide all windows
return
; ------------------------------------------------



; ------------------------------------------------
LoadIni:
; ------------------------------------------------
;@Ahk2Exe-IgnoreBegin
	; Piece of code for developement phase only
	if (A_ComputerName = "JEAN-PC") ; my personal hotkeys
		strIniFileName := "PopupHotkeys-MAISON.ini"
	else if (A_ComputerName = "STIC") ; my work hotkeys
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
		; 1 to display a hotkeys loading report or 0 for a quiet loading of hotkeys
		DisplayLoadReport=1
		; WinWait delay - increase or decrease according to the time your largest program takes to load
		LaunchDelay := 10 
		
		[Keys]
		; Key0=name | hotkey | excutable_path | working_directory | no_preload | window_identifier | startup_script | remark

		; Calc will be launched and hidden, with the root of C: drive as initial working
		; directory; hit Windows-C to show or hide Calc.
		Key1=Calc | #c | C:\Windows\system32\calc.exe | C:\ | | | | Windows-C

		; Notepad will be launched and the "SimpleStartupExample" function (at the
		; bottom of this script) will be executed. Then, the window will be hidden.
		; Hit the Zero key on the numeric keypad to show or hide Notepad.
		Key2=Notepad Startup | Numpad0 | C:\Windows\system32\notepad.exe | | | | SimpleStartupExample.ahk | Numpad Zero

		; At the firt hit of the Right Control key (at the right of the Space bar),
		; iTunes will be launched and hidden; because of iTunes process behaviour, it is
		; safer to identify the program with its class name "iTunes"; hit the Right
		; Control key again to show or hide iTunes.
		Key3=iTunes | RControl | C:\Program Files (x86)\iTunes\iTunes.exe | | 1 | ahk_class iTunes | | Right Control
	
	), %strIniFileName%

; blnDisplayReport: 1 to display a hotkeys loading report or 0 for a quiet loading of hotkeys
IniRead, blnDisplayReport, %strIniFileName%, Global, DisplayLoadReport, 0
; WinWait delay - increase or decrease according to the time your largest program takes to load
IniRead, intLaunchDelay, %strIniFileName%, Global, LaunchDelay, 10

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
	blnPreload := Trim(arrRequest5) <> "1"
	strAhkIdentifier := Trim(arrRequest6)
	strStartupScript := Trim(arrRequest7)
	strRemark := Trim(arrRequest8)

	strThisKeyReport := ""

	if (blnPreload)
		Gosub, RunExecPathOnLoad
	else
		if (strAhkIdentifier)
			strWindowID := strAhkIdentifier ; we use the user defined window identifier
		else
			strWindowID := "ahk_pid 9999999"
			; the program was not preloaded, so we don't have a pid - create a dummy pid that will be replaced when
			; hotkey is pressed (no process should have id 9999999)

	strPopKeyLabel := GetPopHotkeyLabel(strKey)
	arrObjPopupHotkeys[strPopKeyLabel] := Object("KeyName", strName
												, "KeyLabel", strPopKeyLabel
												, "KeyHotkey", strKey
												, "KeyExecPath", strExecPath
												, "KeyWorkDir", strWorkDir
												, "KeyWindowID", strWindowID
												, "KeyStartup", strStartupScript
												, "KeyRemark", strRemark)
	Hotkey, %strKey%, PopupHotkey, UseErrorLevel ; http://www.autohotkey.com/docs/commands/Hotkey.htm
	if (errorLevel)
		strThisKeyReport := strThisKeyReport . "ERROR: " . arrHotkeyErrors[errorLevel] "`n"

	; void the array to make sure old values could not be used in the next loop
	strRequest := "|||||||"
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
	if (strAhkIdentifier)
		strWindowID := strAhkIdentifier ; we use the user defined window identifier
	else
		strWindowID := "ahk_pid " . intExecPID ;  we use the pid
	DetectHiddenWindows, On
	WinWait, %strWindowID%, , %intLaunchDelay%
	if errorlevel
		strThisKeyReport := strThisKeyReport . "ERROR: Delay while launching """ . strExecPath 
			. """ (augment LaunchDelay in .ini file?)`n"
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
strKeyName := GetPopHotkeyLabel(A_ThisHotkey)
; Identification of the window associated with this hotkey (for example: "akh_pid 123" or "akh_class iTunes")
strWindowID := arrObjPopupHotkeys[strKeyName].KeyWindowID
DetectHiddenWindows, Off
IfWinActive, %strWindowID%
	; hotkey program window is active and is visible, so hide it, reset previous window (if known) and exit
	Gosub, HideWindowID
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
HideWindowID:
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
strExecPath := arrObjPopupHotkeys[strKeyName].KeyExecPath
strWorkDir := arrObjPopupHotkeys[strKeyName].KeyWorkDir
strStartupScript := arrObjPopupHotkeys[strKeyName].KeyStartup
Run, %strExecPath%, %strWorkDir%, UseErrorLevel, intExecPID
if (ErrorLevel = "ERROR")
	MsgBox, 16, Popup Hotkeys, ERROR: Could not launch %strExecPath%
else
{
	if (arrObjPopupHotkeys[strKeyName].KeyWindowID = "")
		or (InStr(arrObjPopupHotkeys[strKeyName].KeyWindowID, "ahk_pid"))
		; save or update the new pid in the array associated to this hotkey
		arrObjPopupHotkeys[strKeyName].KeyWindowID := "ahk_pid " . intExecPID
	strWindowID := arrObjPopupHotkeys[strKeyName].KeyWindowID
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
ListAllWindow:
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
ShowAllWindowAndExit:
; ------------------------------------------------
gosub, ShowAllWindow
ExitApp ; Terminates this persistent script unconditionally
; ------------------------------------------------



; ------------------------------------------------
ShowAllWindow:
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
HideAllWindow:
; ------------------------------------------------
for intIndexNotUsed, objPopupHotkey in arrObjPopupHotkeys
{
	strWindowID := objPopupHotkey.KeyWindowID
	WinHide, %strWindowID% ; No error and no action if window is not found
}
return
; ------------------------------------------------



; ------------------------------------------------
TerminateAllWindow:
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
