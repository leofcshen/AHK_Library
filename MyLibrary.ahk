﻿#Requires AutoHotkey v2.0

;IniWrite "Content/IconRun.png", "", "Basic", "IconRun"
;IniWrite "Content/IconStop.png", "", "Basic", "IconStop"
;IniWrite "1", "", "Basic", "ReloadDelaySecond"
;IniWrite "SciTE", "", "Basic", "Editor"

;{	自訂錯誤
;		檔案不存在
class FileNotExistError extends Error {
	__New(pFile){
		message := "檔案不存在" pFile
		super.__New(message, -1)
	}
}
;}

;{	自訂物件
class Common {

}

class MyClass extends Common {
	;{	回傳今天日期_yyyyMMdd
	GetToday_yyyyMMdd() => FormatTime(A_Now, "yyyyMMdd")
	;}
	;{	呼叫外部檔案並回傳結果(會閃 cmd 視窗)
	static RunCommand(pLanguage, pFile, pParameters) {
		if not FileExist(pFile){
			throw FileNotExistError(pFile)
		}

		return	ComObject("WScript.Shell").Exec(pLanguage " " pFile " " pParameters).StdOut.ReadAll()
	}
	;}
	;{	呼叫外部檔案並回傳結果(會閃 cmd 視窗)
	static RunWaitOne(pLanguage, pFile, pParameters) {
		if not FileExist(pFile){
			throw FileNotExistError(pFile)
		}

		return ComObject("WScript.Shell").Exec(A_ComSpec " /C " pLanguage " " pFile " " pParameters).StdOut.ReadAll()
	}
	;}
	;{	呼叫外部檔案並回傳結果(不會閃 cmd 視窗，結果先存檔再取值)
	static RunResult(pLanguage, pFile, pParameters?) {
	if not FileExist(pFile){
		throw FileNotExistError(pFile)
	}

	;指定執行結果暫存位置
	tempFile := A_ScriptDir "\" DllCall("GetCurrentProcessId") ".txt"
	;執行並輸出結果到暫存位置
	if IsSet(pParameters)
		RunWait A_ComSpec " /c " pLanguage ((pLanguage = "python") ? " " : " -ExecutionPolicy Bypass ") pFile " " pParameters " >>" tempFile,,"Hide"
	else
		RunWait A_ComSpec " /c " pLanguage ((pLanguage = "python") ? " " : " -ExecutionPolicy Bypass ") pFile " >>" tempFile,,"Hide"

	;開啟暫存檔
	;Run tempFile
	;取結果值
	result := FileRead(tempFile)
	;刪除暫存檔
	FileDelete(tempFile)

	return result
	}
	;}
	;{	顯示錯誤
	static ShowError(e) {
		stackList := StrSplit(e.Stack, "`n")
		stackString := ""
		for stack in stackList {
			stackString .= stack "`n`n"
		}

		MsgBox Format("
		(
			發生錯誤：`n
			Type:`t{1}`n
			Message:`t{2}`n
			File:`t{3}`n
			Line:`t{4}`n
			What:`t{5}`n
			Stack:
			{6}
		)",
		type(e), e.Message, e.File, e.Line, e.What, stackString)
	}
	;}
}

class Config {
	static ConfigName := "config.ini"
	static SectionBasic := "Basic"

	static ReloadDelaySecond := IniRead(this.ConfigName, this.SectionBasic, "ReloadDelaySecond")
	static Editor := IniRead(this.ConfigName, this.SectionBasic, "Editor")
	static IconRun := IniRead(this.ConfigName, this.SectionBasic, "IconRun")
	static IconStop := IniRead(this.ConfigName, this.SectionBasic, "IconStop")
}
;}

;{	自訂方法
;{	取得螢幕資訊
GetMonitorInfo() {
	MonitorCount := MonitorGetCount()
	MonitorPrimary := MonitorGetPrimary()
	MsgBox "Monitor Count:`t" MonitorCount "`nPrimary Monitor:`t" MonitorPrimary
	Loop MonitorCount	{
		MonitorGet A_Index, &L, &T, &R, &B
		MonitorGetWorkArea A_Index, &WL, &WT, &WR, &WB
		MsgBox
		(
			"Monitor:`t#" A_Index "
			Name:`t" MonitorGetName(A_Index) "
			Left:`t" L " (" WL " work)
			Top:`t" T " (" WT " work)
			Right:`t" R " (" WR " work)
			Bottom:`t" B " (" WB " work)"
		)
	}
}
;}

;{	使用自訂 ToolTip
;			pQuadrant： ToolTip 顯示的象限，0 為置中
MyTooltip(pText, pQuadrant := 1, pTime := 3000) {
	ToolTipOptions.Init()
	ToolTipOptions.SetFont("s48 underline italic", "Consolas")
	ToolTipOptions.SetMargins(12, 12, 12, 12)
	ToolTipOptions.SetTitle("test title" , 4)
	ToolTipOptions.SetColors("Green", "White")
	SetWinDelay -1
	; 取得工作列高度
	WinGetPos , , , &taskBarHeight, "ahk_class Shell_TrayWnd"
	; 設定 ToolTip
	ToolTip pText
	; 設定持續時間
	SetTimer () => ToolTip(), -pTime
	; 取得 ToolTip handler:
	toolTipHandler := WinExist("ahk_class tooltips_class32 ahk_pid " ProcessExist())
	; 取得 ToolTip dimensions:
	WinGetPos ,, &toolTipWidth, &toolTipHeight, toolTipHandler
	; 移動 ToolTip 到該象限
	switch pQuadrant {
		case 0:
			WinMove (A_ScreenWidth - toolTipWidth) / 2, (A_ScreenHeight - toolTipHeight) / 2, , , toolTipHandler
		case 1:
			WinMove (A_ScreenWidth - toolTipWidth), taskBarHeight, , , toolTipHandler
		case 2:
			WinMove 0, taskBarHeight, , , toolTipHandler
		case 3:
			WinMove 0, (A_ScreenHeight - toolTipHeight - taskBarHeight), , , toolTipHandler
		case 4:
			WinMove (A_ScreenWidth - toolTipWidth), (A_ScreenHeight - toolTipHeight - taskBarHeight), , , toolTipHandler
	}
	;ToolTipOptions.Reset()
}
;}

;		打開資源回收桶
OpenRecycleBin() {
	Run "::{645ff040-5081-101b-9f08-00aa002f954e}"
}

;{	編輯腳本
EditScript(pEditor := "Notepad") {
	switch pEditor {
		case "Notepad":
			Run "Notepad .\" A_ScriptName
		case "SciTE":
			editorPath := "C:\Program Files\AutoHotkey\SciTE\SciTE.exe"
			if FileExist(editorPath)
				Run editorPath " .\" A_ScriptName
			else
				Run "Notepad .\" A_ScriptName
		default:
			MsgBox "不支援的編輯器：" pEditor
	}
}
;}

;		檢查字串是否以關鍵字開始
IsStartWith(pString, pKeyword) => SubStr(pString, 1, StrLen(pKeyword)) = pKeyword

;		顯示熱鍵清單
ShowHotkeyList(*) {
	ListHotkeys
}

;{	取得腳本所在的根資料夾名稱
GetScriptRootFolder() => SubStr(A_ScriptDir, InStr(A_ScriptDir, "\", , -1) + 1)

GetScriptRootFolder_2() {
	SplitPath A_ScriptFullPath, , &dir
	SplitPath dir, &dir
	return dir
}
;}

;{	存檔時要自動 reload 的檔案清單
GetReloadFileList() {
	myConfig := "config.ini"
	scriptFolder := GetScriptRootFolder()
	folderArray := []
	fileArray := []

	Loop Files, "*.", "D" {
		folderArray.Push(A_LoopFileName)
	}

	for id, dir in folderArray {
		Loop Files, A_ScriptDir "\" dir "\*.*", "R" {
			fileArray.Push(A_LoopFileName)
		}
	}

	fileArray.Push(A_ScriptName)
	fileArray.Push(myConfig)

	return fileArray
}
;}
;}

;{	自訂熱鍵
;{	加存檔自動 reload 熱鍵，編輯器新增熱鍵把存檔觸發到重新載入腳本
if !A_IsCompiled {
	reloadDelaySecond := Config.ReloadDelaySecond
	saveHotkey := "~^S"
	reloadFileList := GetReloadFileList()

	editorList := [
		" - SciTE4AutoHotkey",
		" - Notepad++",
		" - 記事本",
		" - AutoHotkeyExample - Visual Studio Code"
	]

	for index, editor in editorList {
		for index, f in reloadFileList {
			HotIfWinActive f editor
			Hotkey saveHotkey, ReloadOnSave.Bind(reloadDelaySecond)
		}
	}

	; 重新載入腳本
	ReloadOnSave(reloadDelaySecond, ThisHotkey) {
		MyTooltip reloadDelaySecond " 秒後重新載入腳本", 1
		Sleep reloadDelaySecond * 1000
		Reload
	}
}
;}

;{	Alt + P ;禁用或啟用腳本
#SuspendExempt
!P::{
	Suspend
	TraySetIcon A_IsSuspended ? Config.IconStop : Config.IconRun
	TrayTip A_ScriptName, (A_IsSuspended ? "停用" : "啟用") " AutoHotKey 腳本", "Iconi"
}
#SuspendExempt false
;}

;		Win + Shift + E ;編輯腳本
#+E::EditScript(Config.Editor)

;{	Win + F2 ;自訂選單
!RButton::{
	MyMenu := Menu()
	MyMenu.Add("使用說明", ShowHotkeyList)
	MyMenu.Add("顯示熱鍵清單", ShowHotkeyList)
	MyMenu.Add ;新增分隔線
	MyMenu.Add ;新增分隔線
	MyMenu.AddStandard() ;新增標準選單

	MyMenu.Show
}
;}
;}

;{	工作列圖示右鍵選單
tray := A_TrayMenu ; 为了方便.
;tray.delete ; 删除标准项目.
tray.add ; 分隔线
tray.add "TestToggleCheck", TestToggleCheck
tray.add "TestToggleEnable", TestToggleEnable
tray.add "TestDefault", TestDefault
tray.add "TestAddStandard", TestAddStandard
tray.add "TestDelete", TestDelete
tray.add "TestDeleteAll", TestDeleteAll
tray.add "TestRename", TestRename
tray.add "Test", Test

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TestToggleCheck(*) {
	tray.ToggleCheck TestToggleCheck
	tray.Enable "TestToggleEnable" ; 由于自己无法撤销禁用, 所以还能进行下一次测试.
	tray.add "TestDelete", TestDelete ; 类似于上面.
}

TestToggleEnable(*) {
	tray.ToggleEnable "TestToggleEnable"
}

TestDefault(*) {
	if tray.default = "TestDefault"
		tray.default := ""
	else
		tray.default := "TestDefault"
}

TestAddStandard(*) {
	tray.addStandard
}

TestDelete(*) {
	tray.delete "TestDelete"
}

TestDeleteAll(*) {
	tray.delete
}

TestRename(*) {
	static OldName := "", NewName := ""
	if NewName != "renamed"	{
		OldName := "TestRename"
		NewName := "renamed"
	}
	else {
		OldName := "renamed"
		NewName := "TestRename"
	}
	tray.rename OldName, NewName
}

Test(Item, *) {
	MsgBox 'You selected "' Item '"'
}
;}