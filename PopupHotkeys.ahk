; ================================================
; POPUP HOTKEYS v1.8
; Written using AutoHotkey (http://www.AHKScript.org)
; By jlalonde on AHK forum

; ================================================
; FUNCTION
; ================================================
; Bind hotkeys to a list of programs ready to be
; launched or hidden/shown by these hotkeys. For
; the nostalgics, act a bit like TSR (terminate
; and stay redident) programs of old MS-DOS time.
; ================================================

; ================================================
; INSTRUCTIONS
; ================================================
; Edit the POPUP HOTKEYS REQUESTS array below to
; enter the programs you wish to load as popup
; windows. Run this script and hit hotkeys to
; show/hide the associated programs.
; ================================================


; ================================================
; Auto-execute commands
; ================================================

#Persistent ; Keeps a script permanently running
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases
#SingleInstance force ; Skips the dialog box and replaces the old instance automatically

global arrPopupHotkeysRequests := Array()
global arrObjPopupHotkeys := Object()
global intLaunchDelay := 30 ; WinWait delay - increase or decrease according to the time your largest program takes to load


Menu, Tray, Icon, C:\Windows\System32\imageres.dll, 195, 1 ; ### replace with compile icon
Menu, Tray, Add ; Add a menu separator
Menu, Tray, Add, &List Popup programs, ListAllWindow ; Add a menu to the AHK tray icon to list show all windows
Menu, Tray, Add, &Show all Popup programs, ShowAllWindow ; Add a menu to the AHK tray icon to show all windows
Menu, Tray, Add, &Hide all Popup programs, HideAllWindow ; Add a menu to the AHK tray icon to hide all windows
Menu, Tray, Add, &Terminate all Popup programs, TerminateAllWindow ; Add a menu to the AHK tray icon to hide all windows
OnExit, ShowAllWindowAndExit ; Show all popup programs whenever this script is terminated

; Piece of code for developement phase only
if (A_ComputerName = "JEAN-PC") ; my personal hotkeys
	strIniFileName := "PopupHotkeys-MAISON.ini"
else if (A_ComputerName = "STIC") ; my work hotkeys
	strIniFileName := "PopupHotkeys-STIC.ini"
else ; for other users
	strIniFileName := "PopupHotkeys.ini"
; / Piece of code for developement phase only

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

		[Keys]
		; Calc will be launched and hidden, with the root of C: drive as initial working
		; directory; hit Windows-C to show or hide Calc.
		key1=Calc | #c | C:\Windows\system32\calc.exe | C:\

		; Notepad will be launched and the "SimpleStartupExample" function (at the
		; bottom of this script) will be executed. Then, the window will be hidden.
		; Hit the Zero key on the numeric keypad to show or hide Notepad.
		key2=Notepad Startup | Numpad0 | C:\Windows\system32\notepad.exe | | | | SimpleStartupExample.ahk

		; At the firt hit of the Right Control key (at the right of the Space bar),
		; iTunes will be launched and hidden; because of iTunes process behaviour, it is
		; safer to identify the program with its class name "iTunes"; hit the Right
		; Control key again to show or hide iTunes.
		key3=iTunes | RControl | C:\Program Files (x86)\iTunes\iTunes.exe | | 1 | ahk_class iTunes
	
	), %strIniFileName%
IniRead, blnWithReport, %strIniFileName%, Global, DisplayLoadReport, 0

; ================================================
; POPUP HOTKEYS REQUESTS
; ================================================
; For each program you wish to load, indicate two mandatory parameters and four optional parameters in a string using the | delimiter:
;
; arrPopupHotkeysRequests.Insert("name | hotkey | executable_path | working_directory | no_preload | window_identifier | startup_function")
;
; 1. name: name of the hotkey, for UI usage only
; 2. hotkey: the hotkey defined using the AutoHotkey syntax (see http://www.autohotkey.com/docs/Hotkeys.htm), for example "#z"
;   (Windows-Z) or "Numpad0" (zero on the numeric pad)
; 3. excutable_path: the path to the executable file of the program to load, for example "C:\Windows\system32\notepad.exe"
; 4. working_directory (optional): the full path to the initial working directory, for example "C:\MyData"
; 5. no_preload (optional): if "1" the program is launched only at the fisrt activation of the hotkey
; 6. window_identifier (required only for some program, see note below): window title, class name or other identifier of the
;    program's window, following the rules in http://l.autohotkey.net/docs/misc/WinTitle.htm, for example "ahk_class iTunes"
; 7. startup_script (optional): AHK script to run at program startup (for example, to enter a password of initialize the
;    program - see PasswordAppStartup example)
;
; Note about window identifiers (about #6 above):
; By default, this script identify programs by their process ID. Some program (like iTunes for Windows) do not respond consistently
; to this ID when managed by AutoHotkey. If you experience problems with a program that does not respond normally to its hotkey, try
; using one of these options: the program's title ("iTunes"), class name ("ahk_class iTunes"), unique ID ("ahk_id 0x40574") or
; process name ("ahk_exe iTunes.exe".) To find a program's title, class, etc., run the Window Spy utility included with AutoHotkey.
;

Loop
{
	IniRead, strKeyLine, %strIniFileName%, Keys, Key%A_Index%
	if (strKeyLine = "ERROR")
		Break
	arrPopupHotkeysRequests.Insert(strKeyLine)
}

; The following commands will create the requested hotkeys display a result report if the CreatePopupHotkeys parameter is "true".
strResult :=  CreatePopupHotkeys(blnWithReport)
if (strResult <> "")
	MsgBox, 16, Popup Hotkeys, %strResult%

return
; ================================================
; End of auto-execute commands
; ================================================



; ================================================
; POPUP HOTKEYS FUNCTIONS AND ROUTINES
; ================================================

; ------------------------------------------------
CreatePopupHotkeys(blnDisplayReport := true)
; ------------------------------------------------
; For each request in the array arrPopupHotkeysRequests, run the executable (except if no_preload is present),
; call the startup function (if present), hide the window and create the hotkey. For each request, add an
; entry in the array of hotkeys objects arrObjPopupHotkeys with the info about a request (hotkey as array index,
; hotkey name, executable path, and the optional working directory, window ID and startup routine). When one of
; the hotkeys will be invoked, the info associated with this hotkey will be retrieved from the arrObjPopupHotkeys
; array by the subroutine PopupHotkey (below) in order to show/hide or re-run the executable.
{
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
		strThisKeyReport := ""
		if (blnPreload)
		{
			Run, %strExecPath%, %strWorkDir%, UseErrorLevel, intExecPID
			if (ErrorLevel = "ERROR")
				strThisKeyReport := strThisKeyReport . "ERROR: Could not launch """ . strExecPath . """ (error #" . A_LastError . ")`n"
			else
			{
				if (strAhkIdentifier)
					strWindowID := strAhkIdentifier ; we use the user defined window identifier
				else
					strWindowID := "ahk_pid " . intExecPID ;  we use the pid
				DetectHiddenWindows, On
				WinWait, %strWindowID%, , intLaunchDelay
				if errorlevel
					strThisKeyReport := strThisKeyReport . "ERROR: Delay while launching """ . strExecPath . """ (augment the WinWait delay?)`n"
				Sleep, 200
				if StrLen(strStartupScript)
				{
					if !InStr(strStartupScript, "\") and !InStr(strStartupScript, "/")
						strStartupScript := A_ScriptDir . "\" . strStartupScript
					if FileExist(strStartupScript)
					{
						RunWait, %strStartupScript% %strWindowID%, UseErrorLevel
						if (ErrorLevel)
							strThisKeyReport := strThisKeyReport . "ERROR: Error #" . ErrorLevel . " after running startup macro """ . strStartupScript . """`n"
					}
					else
						strThisKeyReport := strThisKeyReport . "ERROR: Startup macro """ . strStartupScript . """ not found`n"
				}
				WinHide, %strWindowID%
			}
		}
		else
			if (strAhkIdentifier)
				strWindowID := strAhkIdentifier ; we use the user defined window identifier
			else
				strWindowID := "ahk_pid 9999999" ; the program was not preloaded, so we don't have a pid - create a dummy pid that will be replaced when hotkey is pressed (no process should have id 9999999)
		strPopKeyLabel := GetPopHotkeyLabel(strKey)
		arrObjPopupHotkeys[strPopKeyLabel] := Object("KeyName", strName, "KeyLabel", strPopKeyLabel, "KeyHotkey", strKey, "KeyExecPath", strExecPath, "KeyWorkDir", strWorkDir, "KeyWindowID", strWindowID, "KeyStartup", strStartupScript)
		Hotkey, %strKey%, PopupHotkey, UseErrorLevel ; http://www.autohotkey.com/docs/commands/Hotkey.htm
		if (errorLevel)
			strThisKeyReport := strThisKeyReport . "ERROR: " . arrHotkeyErrors[errorLevel] "`n"
		; void the array to make sure old values could not be used in the next loop
		strRequest := "|||||"
		StringSplit arrRequest, strRequest, |
		strReport := strReport . "`nCreation of " . strName . " (" . strKey . ") -> "
		if StrLen(strThisKeyReport)
			strReport := strReport . strThisKeyReport
		else
			strReport := strReport . "OK`n"
	}
	if blnDisplayReport
		return strReport
	else
		return
}
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
;    the startup function (if present) is executed.
Critical ; Prevents the current thread from being interrupted by other threads.
strKeyName := GetPopHotkeyLabel(A_ThisHotkey)
strWindowID := arrObjPopupHotkeys[strKeyName].KeyWindowID ; Identification of the window associated with this hotkey (for example: "akh_pid 123" or "akh_class iTunes")
DetectHiddenWindows, Off
IfWinActive, %strWindowID% ; hotkey program window is active and is visible, so hide it, reset previous window (if known) and exit
{
	WinHide, %strWindowID%
	if (strWindowBeforeHotkeyID) and (1 = 0) ; ### TEST - si mouse au dessus rappeler sinon?
	{
		WinActivate, ahk_id %strWindowBeforeHotkeyID% ; reactivate the previous window, leaving the hotkey program window as is (hidden or not).
		strWindowBeforeHotkeyID := ; kill previous window variable
	}
}
else
{
	DetectHiddenWindows, On
	IfWinActive, %strWindowID% ; hotkey program window is active but not visible, so show it and exit
		WinShow, %strWindowID%
	else
	{
		strWindowBeforeHotkeyID := WinExist("A") ; hotkey program is not active, remember the window that was active before we reactivate it
		IfWinExist, %strWindowID% ; hotkey program window exists, visible or not (we don't care here), but is not active, so show it, activate it and exit
		{
			WinShow, %strWindowID% ; in case it was not visible
			WinActivate, %strWindowID%
		}
		else ; hotkey program window does not exist, so start it
		{
			strExecPath := arrObjPopupHotkeys[strKeyName].KeyExecPath
			strWorkDir := arrObjPopupHotkeys[strKeyName].KeyWorkDir
			strStartupScript := arrObjPopupHotkeys[strKeyName].KeyStartup
			Run, %strExecPath%, %strWorkDir%, UseErrorLevel, intExecPID
			if (ErrorLevel = "ERROR")
				MsgBox, 16, Popup Hotkeys, ERROR: Could not launch %strExecPath%
			else
			{
				if (arrObjPopupHotkeys[strKeyName].KeyWindowID = "") or (InStr(arrObjPopupHotkeys[strKeyName].KeyWindowID, "ahk_pid"))
					arrObjPopupHotkeys[strKeyName].KeyWindowID := "ahk_pid " . intExecPID ; save or update the new pid in the array associated to this hotkey
				strWindowID := arrObjPopupHotkeys[strKeyName].KeyWindowID
				DetectHiddenWindows, On
				WinWait, %strWindowID%, , %intLaunchDelay%
				if errorlevel
					MsgBox, 16, Popup Hotkeys, ERROR: Delay while launching %strExecPath% (%strWindowID%). Augment the WinWait delay?
				Sleep, 200
				if (strStartupScript)
					if IsFunc(strStartupScript)
						%strStartupScript%(strWindowID)
					else
						MsgBox, 16, Popup Hotkeys, ERROR: Function %strStartupScript% not found in %A_ScriptName%
			}
		}
	}
}
return
; ------------------------------------------------



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
	WinShow, %strWindowID% ; In case the window is hidden, make sure Save data dialog box could be seen. No error and no action if window is not found.
	WinClose, %strWindowID% ; Closes the specified window. Unlike WinKill, this command will give the user a chance to save its unsaved data.
}
return
; ------------------------------------------------


; ================================================
; CUSTOM STARTUP FUNCTIONS
; ================================================

SimpleStartupExample(strWindowID)
{
	WinGetTitle, strTitle, %strWindowID%
	Send, This function is executed when the program [ %strTitle% ] is launched.`n
}



PasswordAppStartup(strWindowID)
{
	strUsername := "yourusername"
	strPassword := "yourpassword"
	ControlSetText, Edit1, %strUsername%, %strWindowID%
	ControlSetText, Edit2, %strPassword%, %strWindowID%
	ControlClick, LoginButton, %strWindowID%
	SetTitleMatchMode, 1
	WinWait, Application Window
	return
}

