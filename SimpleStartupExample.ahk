strWindowID = %1%
###_D(strWindowID)
WinGetTitle, strTitle, %strWindowID%
Send, This function is executed when the program [ %strTitle% ] is launched.`n
