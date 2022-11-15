#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=res\icons.ico
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_UseX64=Y
#AutoIt3Wrapper_Res_Comment=Francesco Gerratana 2022
#AutoIt3Wrapper_Res_Description=DxO-Batch-Image
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductVersion=1.0
#AutoIt3Wrapper_Res_CompanyName=Francesco Gerratana 2022
#AutoIt3Wrapper_Res_LegalCopyright=GPL3
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/sci 0
#AutoIt3Wrapper_Tidy_Stop_OnError=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

This program was written for non-commercial purposes, it is intended for educational purposes only.
It is not intended to support piracy, it can be used together with the regularly purchased DxO Photolab program,
all rights belong to the rightful owners. I do not answer any questions that violate copyright.
Use DxO-Batch-Image at your own risk.

The program originated from a question in the official DxO forum
"is there a CLI to use the program to process large amounts of images without going through the GUI?",
it was revealed in the forum that there is a CLI,  but not finding anything usable I decided to write
something for myself, which I decided to share with everyone.

 Program:					DxO-Batch-Image
 AutoIt Version: 			3.3.16.1
 Author:         			Nextechnics
 WebSite:		 			https://www.nextechnics.com
 GitHub:		 			https://github.com/gerfra
 Usage: 		 			This program is used to process images massively, using specific preset profile, without using the user
							interface of the DxO Photolab program
 License DxO-Batch-Image: 	GPL3 https://www.gnu.org/licenses/gpl-3.0.html


#ce ----------------------------------------------------------------------------
#pragma compile(Out, DxO-Batch-Image.exe)
#pragma compile(Icon, res\icons.ico)
#pragma compile(ExecLevel, asInvoker)
#pragma compile(UPX, False)
#pragma compile(FileDescription, batch images processing)
#pragma compile(ProductName, DxO-Batch-Image)
#pragma compile(ProductVersion, 1.0)
#pragma compile(FileVersion, 1.0)
#pragma compile(LegalCopyright, © Francesco Gerratana)
#pragma compile(CompanyName, "Nextechnics")
#pragma compile(Compression, 3)
#pragma compile(OriginalFilename, DxO-Batch-Image.exe)
#include <Array.au3>
#include <File.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Date.au3>


Global $nMsg, $hWnd, $Msg, $wParam, $lParam

;STYLE
Global $formbackground = @ScriptDir & "\res\background.jpg"
Global $fontsize = 8, $fontweight = 200
Global $font = "Century Gothic"
GUISetFont(10, 400, 0, $font)
Global $icon = @ScriptDir & "\res\icons.ico"
DirCreate(@ScriptDir & "\res")
Global $bFileInstall = True
If $bFileInstall Then
	FileInstall("E:\00_Sviluppo\Progetti\DxO_Loop\res\icons.ico", $icon)
EndIf

; Set a HotKey
HotKeySet("k", "_Stop")
; Declare a flag
Global $state = 0

; Backup Folder
Global $folder = ["Backup", "Output", "Log"]
For $f = 0 To UBound($folder) - 1
	If Not FileExists($folder[$f]) Then
		DirCreate(@ScriptDir & "\" & $folder[$f])
	EndIf
Next

; File Camera Type
Global $type = "*.3fr; *.ari; *.arw; *.bay; *.braw; *.crw; *.cr2; *.cr3; *.cap; *.data; *.dcs; *.dcr; *.dng; *.drf; *.eip; *.erf; *.fff; *.gpr; *.iiq; *.k25; *.kdc; *.mdc; *.mef; *.mos; *.mrw; *.nef; *.nrw; *.obm; *.orf; *.pef; *.ptx; *.pxn; *.r3d; *.raf; *.raw; *.rwl; *.rw2; *.rwz; *.sr2; *.srf; *.srw; *.tif; *.x3f"

; DxO init
Global $core = @ProgramFilesDir & "\DxO\DxO PhotoLab 6\DxO.PhotoLab.ProcessingCore.exe"
Global $modules = "C:\Users\" & @UserName & "\AppData\Local\DxO\DxO PhotoLab 6\Modules"
Global $CAFListdb = "C:\Users\" & @UserName & "\AppData\Local\DxO\DxO PhotoLab 6\CAFList6.db"
Global $ocl64cache = "C:\Users\" & @UserName & "\AppData\Local\DxO\DxO PhotoLab 6\ocl64.cache"
Global $preset_path = "C:\Users\" & @UserName & "\AppData\Local\DxO\DxO PhotoLab 6\Presets\"
Global $configxml = _Generate_configxml(@ScriptDir & "\config.xml")
Global $bakup = $folder[0]
Global $output = $folder[1]

; Backups files
Global $database = "C:\Users\" & @UserName & "\AppData\Roaming\DxO\DxO PhotoLab 6\Database\PhotoLab.db"
FileCopy($CAFListdb, $bakup, 1)
FileCopy($database, $bakup, 1)


#Region ### START Koda GUI section ### Form=c:\users\ken\desktop\dxo_loop\form1_1.kxf
Global $DXO_BATCH = GUICreate("DXO CLI | DXO BATCH PROCESSING", 800, 600, -1, -1)
Global $Pic1 = GUICtrlCreatePic($formbackground, 0, 19, 800, 600)
GUICtrlSetState(-1, $GUI_DISABLE)
If Not @Compiled Then GUISetIcon($icon)
GUISetIcon($icon, -1)
;#################################### TAB#########################################################
Global $Tab1 = GUICtrlCreateTab(0, 0, 800, 600)
GUICtrlSetFont(-1, $fontsize, $fontweight, 0, $font)
;#################################### TAB 1 ######################################################
Global $TabSheet1 = GUICtrlCreateTabItem("Process")
GUICtrlSetFont(-1, $fontsize, $fontweight, 0, $font)
Global $PresetCB = GUICtrlCreateCombo("", 16, 26, 769, 25, BitOR($ES_READONLY, $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
Global $ArrPreset = _List_preset($preset_path)
For $ff = 1 To UBound($ArrPreset) - 1
	GUICtrlSetData($PresetCB, $ArrPreset[$ff])
Next
GUICtrlSetTip(-1, "List Preset DxO")
Global $suffix = GUICtrlCreateInput("_dxo", 16, 58, 113, 21)
GUICtrlSetTip(-1, "Suffix")
GUICtrlSetLimit(-1, 10)
Global $threadInp = GUICtrlCreateCombo("1", 137, 58, 75, 25, BitOR($ES_READONLY, $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
GUICtrlSetData($threadInp, "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16")
GUICtrlSetTip(-1, "Number of Threads")
Global $apiCB = GUICtrlCreateCombo(" --opencl", 222, 58, 113, 25, BitOR($ES_READONLY, $CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
GUICtrlSetData($apiCB, " --cl||")
GUICtrlSetTip(-1, "Gpu Api Drivers")
Global $Outputfolder = GUICtrlCreateButton("OUTPUT", 345, 58, 100, 21)
GUICtrlSetTip(-1, "Images OutPut Folder")
Global $DebugCB = GUICtrlCreateCheckbox("Debug", 456, 60, 101, 17)
GUICtrlSetTip(-1, "Show Debug Console")
GUICtrlSetState($DebugCB, $GUI_CHECKED)
GUICtrlSetState($DebugCB, $GUI_DISABLE)
Global $listeningCB = GUICtrlCreateCheckbox("listening", 556, 60, 101, 17)
GUICtrlSetTip(-1, "Listening")
GUICtrlSetState($listeningCB, $GUI_UNCHECKED)
GUICtrlSetState($listeningCB, $GUI_DISABLE)
Global $OutCons = GUICtrlCreateEdit("", 16, 90, 769, 465)
GUICtrlSetData(-1, "")
Global $START_PROCESS = GUICtrlCreateButton("START_PROCESS", 26, 565, 190, 25)
Global $KILL_PROCESS2 = GUICtrlCreateButton("KILL_PROCESS", 306, 565, 190, 25)
Global $Donate = GUICtrlCreateButton("BuY Me A Coffee!", 586, 565, 190, 25)
GUICtrlSetColor(-1, 0x0000FFFF)
GUICtrlSetBkColor(-1, 0x0000000)
;#################################### TAB 2 ######################################################
Global $TabSheet2 = GUICtrlCreateTabItem("DopCor")
Global $dopcor = GUICtrlCreateInput(" -l -p=8000 -d=2000 --debug", 16, 26, 769, 21)
GUICtrlSetTip(-1, "DopCor cmd Option")
Global $OUTPUTC2 = GUICtrlCreateEdit("", 16, 90, 769, 465)
GUICtrlSetData(-1, "")
Global $btDopCore = GUICtrlCreateButton("START_DOPCOR", 88, 565, 270, 25)
Global $KILL_PROCESS = GUICtrlCreateButton("KILL_PROCESS", 470, 565, 270, 25)

Global $aKeys[1][2] = [["{ENTER}", $btDopCore]]
GUISetAccelerators($aKeys)
Global $Intrpt = GUICtrlCreateDummy()
Global $pKeys[1][2] = [["z", $Intrpt]]
GUISetAccelerators($pKeys)
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")

GUISetState(@SW_SHOW)
_GUICtrlEdit_SetLimitText($OutCons, 10 ^ 10)
#EndRegion ### END Koda GUI section ###

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

		Case $Outputfolder

			Local $selfolder = FileSelectFolder("Select Image Folder", @ScriptDir, "", "")
			If @error Then
				MsgBox(0, "Attention", "Images will be saved in the default folder")
			Else
				$output = $selfolder
			EndIf


		Case $START_PROCESS
			Local $Debug
			If BitAND(GUICtrlRead($DebugCB), $GUI_UNCHECKED) Then
				$Debug = ""
			Else
				$Debug = " --debug"
			EndIf
			Local $listening
			If BitAND(GUICtrlRead($listeningCB), $GUI_UNCHECKED) Then
				$listening = ""
			Else
				$listening = " --listening"
			EndIf

			If GUICtrlRead($suffix) = "" Then
				$suffix = ''
			Else
				$suffix = ' -f="' & GUICtrlRead($suffix) & '"'
			EndIf

			Global $api = GUICtrlRead($apiCB)
			Global $Preset = GUICtrlRead($PresetCB)
			Global $thread = ' -t=' & GUICtrlRead($threadInp)

			Local $img_folder = FileSelectFolder("Select Image Folder", @ScriptDir, "", "")
			If @error Then
				MsgBox(0, "Attention", "Please Select a Folder")
			Else
				Local $source_files = _FileListToArrayRec($img_folder, $type, 1, 0, 1, 2)
				GUICtrlSetData($OutCons, "", 1)
				_ProcessStart($source_files)
			EndIf

		Case $btDopCore
			_DopCor()

		Case $KILL_PROCESS

		Case $Donate

			ShellExecute("https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=francescogerratana%40gmail%2ecom&lc=US&item_name=Francesco%20Gerratana&item_number=Buy%20me%20a%20Beer%2c%20Offrimi%20una%20Birra%2e&no_note=0&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest")

	EndSwitch
WEnd

Func _ProcessStart($ArrSource)
	Local $log, $run
	$log = $folder[2] & "\" & _Time_Log() & ".txt"
	FileOpen($log, 1)
	$state = 0

	For $i = 1 To UBound($ArrSource) - 1
		Local $logtxt
		Local $cmd = $core & ' -c="' & $modules & '" -d="' & $CAFListdb & '" -k="' & $ocl64cache & '" -i="' & $ArrSource[$i] & '" -s="' & $Preset & '" -o="' & $configxml & '" -p="' & $output & '"' & $suffix & " " & $thread & $api & $Debug & $listening & '' & @CRLF
		ConsoleWrite($cmd)
		GUICtrlSetData($OutCons, "Start Process file " & $ArrSource[$i] & @CRLF, 1)
		GUICtrlSetData($OutCons, $cmd & @CRLF, 1)
		$run = Run($core & ' -c="' & $modules & '" -d="' & $CAFListdb & '" -k="' & $ocl64cache & '" -i="' & $ArrSource[$i] & '" -s="' & $Preset & '" -o="' & $configxml & '" -p="' & $output & '"' & $suffix & " " & $thread & $api & $Debug & $listening & '', @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD) ;$STDIO_INHERIT_PARENT)
		While ProcessExists($run)
			If $state <> 0 Then
				ProcessClose($run)
			EndIf
			$logtxt = StdoutRead($run)
			If @error Then ExitLoop
			If $logtxt <> "" Then
				FileWriteLine($log, $logtxt)
				GUICtrlSetData($OutCons, $logtxt, 1)
			EndIf
		WEnd

		While ProcessExists($run)
			$logtxt = StderrRead($run)
			If @error Then ExitLoop
			If $logtxt <> "" Then
				FileWriteLine($log, $logtxt)
				GUICtrlSetData($OutCons, $logtxt, 1)
			EndIf
		WEnd
		GUICtrlSetData($OutCons, @CRLF, 1)
	Next

	GUICtrlSetData($OutCons, @CRLF & "Process Terminated" & @CRLF, 1)

	FileClose($log)

	ProcessWaitClose($run)

	FileMove(@ScriptDir & "\user.xml", $bakup, 1)

EndFunc   ;==>_ProcessStart

Func _DopCor()
	$state = 0
	Local $logtxt
	Local $run = Run($core & GUICtrlRead($dopcor), @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	ConsoleWrite($core & GUICtrlRead($dopcor))
	While ProcessExists($run)
		If $state <> 0 Then
			ProcessClose($run)
			GUICtrlSetData($OUTPUTC2, "Process Terminated" & @CRLF, 1)
		EndIf
		$logtxt = StdoutRead($run)
		If @error Then ExitLoop
		If $logtxt <> "" Then
			GUICtrlSetData($OUTPUTC2, $logtxt, 1)
		EndIf
	WEnd

	While ProcessExists($run)
		$logtxt = StderrRead($run)
		If @error Then ExitLoop
		If $logtxt <> "" Then
			GUICtrlSetData($OUTPUTC2, $logtxt, 1)
		EndIf
	WEnd
	GUICtrlSetData($OUTPUTC2, @CRLF, 1)
EndFunc   ;==>_DopCor


Func _Generate_configxml($configxml)
	; Find file user.config
	Local $findcfg = _FileListToArrayRec(@LocalAppDataDir & "\DxO\", "DxO.PhotoLab.exe_StrongName_*", 2, 0, 0, 2)

	If @error Then Exit MsgBox(4096, "Error", "No folders DxO.PhotoLab.exe_StrongName_ found")
	For $f = 1 To $findcfg[0]
		Local $cfg = _FileListToArrayRec($findcfg[$f], "*.config", 1, 1, 0, 2)
		For $x = 1 To UBound($cfg) - 1
			FileCopy($cfg[$x], @ScriptDir, 1)
		Next
	Next

	If FileExists(@ScriptDir & "\user.config") Then
		FileMove(@ScriptDir & "\user.config", @ScriptDir & "\user.xml", 1)
	Else
		MsgBox("3", "Error", "Impossible create config.xml, please check " & @LocalAppDataDir & "\DxO\ Folder")
		Exit
	EndIf

	; Extract OutputSettings
	Local $xml = @ScriptDir & "\user.xml"

	Local $oXML = ObjCreate("Microsoft.XMLDOM")
	$oXML.load($xml)

	Local $oParameters = $oXML.selectNodes("//userSettings/DxO.PhotoLab.Properties.Settings/setting")

	Local $hFile = FileOpen($configxml, 2)

	For $oParameter In $oParameters
		If $oParameter.GetAttribute("name") = "OutputSettings" Then
			FileWrite($hFile, $oParameter.text & @CRLF)
		EndIf
	Next

	FileClose($hFile)

	Return $configxml

EndFunc   ;==>_Generate_configxml

Func _List_preset($path)
	; List of preset file
	Local $listPreset = _FileListToArrayRec($path, "*.preset", 1, 1, 1, 2)
	Return $listPreset
EndFunc   ;==>_List_preset

Func _Time_Log()
	Local $time = "Date_" & StringRegExpReplace(_NowCalcDate(), "(\d\d\d\d)/(\d\d)/(\d\d)", "$3-$2-$1") & "_Time_" & StringReplace(_NowTime(5), ":", ".")
	Return $time
EndFunc   ;==>_Time_Log

; Stop Loop
Func _Stop()
	$state = 2
EndFunc   ;==>_Stop

Func _WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	#forceref $hWnd, $Msg, $wParam, $lParam _WM_COMMAND
	If BitAND($wParam, 0x0000FFFF) = $KILL_PROCESS Then $state = 1
	If BitAND($wParam, 0x0000FFFF) = $KILL_PROCESS2 Then $state = 1
	If BitAND($wParam, 0x0000FFFF) = $Intrpt Then $state = 3
	Return $GUI_RUNDEFMSG
	MsgBox("", "", "")
EndFunc   ;==>_WM_COMMAND



