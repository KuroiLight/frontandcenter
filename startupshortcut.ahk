
CreateStartupShortcut(lnkName) {
	FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\%lnkName%.lnk, %A_ScriptDir%
}

AskStartupShortcut() {
	static scriptName := RegExReplace(A_Scriptname, "(?:(\w+).+)", "$1"), iniFile := scriptName . ".ini"
	
	IniRead, dontAsk, %iniFile%, % "Startup", % "DontAskAboutShortcut"
	
	if(dontAsk = 1 or dontAsk = "true")
		return
	
	FileGetShortcut, %A_Startup%\%scriptName%.lnk, oldTarget
	if(ErrorLevel) {
		MsgBox, 4, % scriptName . " startup shortcut", % "No startup shortcut for " . scriptName . " would you like to create one?"
		IfMsgBox, Yes
		{
			CreateStartupShortcut(scriptName)
		}
		else
		{
			IniWrite, % "true", %iniFile%, % "Startup", % "DontAskAboutShortcut"
		}
	} else {
		if(oldTarget != A_ScriptFullPath) {
			MsgBox,, % scriptName . " startup shortcut", % "An old startup shortcut for this script was detected and will be updated."
			CreateStartupShortcut(scriptName)
		}
	}
}