#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#Region ### START Koda GUI section ### Form=d:\documents\_dokumenty\devel\autoit\ddsa\ddsa.kxf
$DDSA = GUICreate("DCS Dedicated Server Automation", 580, 394, -1, -1)
$SettingsMenu = GUICtrlCreateMenu("&Settings")
$DCSPathMenu = GUICtrlCreateMenuItem("DCS Path", $SettingsMenu)
$IntervalMenu = GUICtrlCreateMenuItem("Restart Interval", $SettingsMenu)
$AutostartMenu = GUICtrlCreateMenuItem("Autostart", $SettingsMenu)
$WebhooksMenu = GUICtrlCreateMenuItem("Add Webhook", $SettingsMenu)
$HelpMenu = GUICtrlCreateMenu("&Help")
$AboutMenu = GUICtrlCreateMenuItem("About", $HelpMenu)
GUISetIcon("D:\Documents\_Dokumenty\Devel\AutoIT\DCSDSA\ddsa_icon.ico", -1)
GUISetFont(8, 800, 0, "Noto Sans")
$StartDCSButton = GUICtrlCreateButton("Update and start DCS", 24, 16, 200, 25)
$KillDCSButton = GUICtrlCreateButton("Kill DCS", 248, 16, 200, 25)
$ExitButton = GUICtrlCreateButton("Exit", 472, 16, 80, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
$DCSStatusLabel = GUICtrlCreateLabel("DCS Server Status:", 48, 56, 481, 28)
GUICtrlSetFont(-1, 16, 800, 0, "Noto Sans")
$RestartGroup = GUICtrlCreateGroup("Restart Information", 24, 88, 529, 97, BitOR($GUI_SS_DEFAULT_GROUP,$BS_CENTER,$BS_FLAT))
$LastRestartTimeLabel = GUICtrlCreateLabel("", 40, 104, 135, 35, $SS_CENTER)
$TimeToRestartLabel = GUICtrlCreateLabel("", 216, 104, 135, 35, $SS_CENTER)
$NextRestartTimeLabel = GUICtrlCreateLabel("", 408, 104, 135, 35, $SS_CENTER)
$RestartProgress = GUICtrlCreateProgress(72, 152, 422, 20, $PBS_SMOOTH)
GUICtrlSetColor(-1, 0x008080)
GUICtrlSetBkColor(-1, 0xE3E3E3)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$DCSLoggingGroup = GUICtrlCreateGroup("DDSA Logging", 24, 216, 529, 145, BitOR($GUI_SS_DEFAULT_GROUP,$BS_CENTER,$BS_FLAT,$WS_CLIPSIBLINGS))
$DCSLogText = GUICtrlCreateEdit("", 32, 232, 513, 119, BitOR($ES_AUTOVSCROLL,$ES_READONLY,$ES_WANTRETURN,$WS_VSCROLL))
GUICtrlSetFont(-1, 8, 400, 0, "Courier New")
GUICtrlCreateGroup("", -99, -99, 1, 1)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=".\ddsa_icon.ico"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <WinAPI.au3>
#include <GuiEdit.au3>
#include <Date.au3>
Global $DCSStatus = "Stopped"
Global $DCSStartTime = ""
Global $RestartIntervalMin = 4*60 ;~ 4h
Global $DCSPath = "C:\Games\SteamLibrary\steamapps\common\DCSWorld"
Global $CurrentTime = _NowCalc()
Global $Autostart = 0
Global $IniFileNamePath = StringFormat("%s\dcsdsa.ini",@MyDocumentsDir) 
Global $APPTTIMERCHECK = 10000 ;~ msec
Global $Version = "1.1"
Global $GithubLink = ""
Global $WebhookLink = 0

If FileExists($IniFileNamePath) Then
    $RestartIntervalMin = Number(IniRead($IniFileNamePath,"general","RestartInterval","240"))
    $DCSPath = IniRead($IniFileNamePath,"general","DCSPath","C:\Games\SteamLibrary\steamapps\common\DCSWorld")
    $Autostart = IniRead($IniFileNamePath,"general","Autostart","0")
    $WebhookLink = IniRead($IniFileNamePath,"network","webhooklink","0")
EndIf

If $Autostart = 1 Then
    GUICtrlSetState($AutostartMenu,$GUI_CHECKED)
EndIf

DCSLog(StringFormat("DCS Path: %s",$DCSPath))
DCSLog(StringFormat("Restart Interval: %d [h]",$RestartIntervalMin/60))
DCSLog(StringFormat("Autostart: %d",$Autostart))
DCSLog(StringFormat("Webhook: %s",$WebhookLink))

$AppTimer = TimerInit()
$TimeTimer = TimerInit()

If $Autostart = 1 Then
    DCSLog("Starting DCS")
    StartDCSUpdater($DCSPath)
    DCSLog("Web Control : https://digitalcombatsimulator.com/en/personal/server/")
EndIf

AppUpdate()
While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit

        Case $DCSPathMenu
            $DCSPath = FileSelectFolder("Choose DCS Base Folder","C:/")
            IniWrite($IniFileNamePath,"general","DCSPath",$DCSPath)
            DCSLog(StringFormat("New DCS Path: %s",$DCSPath))

        Case $IntervalMenu
            $IntervalHours = InputBox("DCS Restart Interval","Set new interval [hours]:", 4)
            $RestartIntervalMin = $IntervalHours*60
            IniWrite($IniFileNamePath,"general","RestartInterval",$RestartIntervalMin)
            DCSLog(StringFormat("New Restart Interval: %d [h]",$IntervalHours))

        Case $AutostartMenu
            If BitAnd(GUICtrlRead($AutostartMenu),$GUI_CHECKED) = $GUI_CHECKED Then
                GUICtrlSetState($AutostartMenu,$GUI_UNCHECKED)
                $Autostart = 0
            Else
                GUICtrlSetState($AutostartMenu,$GUI_CHECKED)
                $Autostart = 1
            EndIf
            IniWrite($IniFileNamePath,"general","Autostart",$Autostart)
            DCSLog(StringFormat("New Autostart value: %s",$Autostart))

        Case $WebhooksMenu
            $WebhookLink = InputBox("Webhooks","Webhook link:")
            IniWrite($IniFileNamePath,"network","webhooklink",$WebhookLink)
            DCSLog(StringFormat("New Webhook: %s",$WebhookLink))

        Case $AboutMenu
            MsgBox(0,"About", StringFormat("Thanks for using"&@CRLF&"Version: %s"&@CRLF&"Github: %s",$Version,$GithubLink))

        Case $StartDCSButton
            DCSLog("Starting DCS", 1)
            StartDCSUpdater($DCSPath)
            DCSLog("Web Control : https://digitalcombatsimulator.com/en/personal/server/")

        Case $KillDCSButton
            DCSLog("Killing DCS", 1)
            KillDCS()
        
        Case $ExitButton
            DCSLog("Killing DCS and Exiting DDSA", 1)
            KillDCS()
			Exit

	EndSwitch

    If TimerDiff($TimeTimer) > 1000 Then
        $TimeTimer = TimerInit()
        TimeUpdate()
    EndIf
    
    If TimerDiff($AppTimer) > $APPTTIMERCHECK Then
        $AppTimer = TimerInit()
        AppUpdate()
    EndIf

WEnd

Func TimeUpdate()
    $CurrentTime = _NowCalc()
    $TimePercentage = 0
    If $DCSStartTime Then
        $NextRestartTime = _DateAdd("n",$RestartIntervalMin,$DCSStartTime)
        $TimeToRestartMinutes = _DateDiff("n",$CurrentTime,$NextRestartTime)
        $TimeToRestartHours = _DateDiff("h",$CurrentTime,$NextRestartTime)
        GUICtrlSetData($LastRestartTimeLabel,StringFormat("Last Restart:\r\n%s",$DCSStartTime))
        GUICtrlSetData($NextRestartTimeLabel,StringFormat("Next Restart:\r\n%s",$NextRestartTime))
        $TimeToRestartMinutesMod = $TimeToRestartMinutes
        If $TimeToRestartHours > 0 Then
            $TimeToRestartMinutesMod = Mod($TimeToRestartMinutes,$TimeToRestartHours*60)
        EndIf
        GUICtrlSetData($TimeToRestartLabel,StringFormat("Time to restart:\r\n%02d:%02d",$TimeToRestartHours,$TimeToRestartMinutesMod))
        $TimePercentage = ($RestartIntervalMin-$TimeToRestartMinutes)/$RestartIntervalMin*100
    Else
        GUICtrlSetData($LastRestartTimeLabel,StringFormat("N/A"))
        GUICtrlSetData($NextRestartTimeLabel,StringFormat("N/A"))
        GUICtrlSetData($TimeToRestartLabel,StringFormat("N/A"))
        $TimePercentage = 0
    EndIf
    GUICtrlSetData($RestartProgress,$TimePercentage)

EndFunc

Func AppUpdate()
    $CurrentTime = _NowCalc()
    
    If $DCSStatus = "Crashed" Then
        StartDCSUpdater($DCSPath)
    EndIf
    If ProcessExists("DCS_updater.exe") Then ;~ Check if Updater is running
        $DCSStatus = "Checking updates and updating ..."
        DCSLog("Updating DCS", 1)
    ElseIf ProcessExists("DCS.exe") Then ;~ Check if DCS is running
        $DCSStatus = "Running"
        If _DateDiff("n",$DCSStartTime,$CurrentTime) > $RestartIntervalMin Then ;~ check interval
            $DCSStatus = "Restarting"
            KillDCS()
            StartDCSUpdater($DCSPath)
            DCSLog("Restarting DCS", 1)
        EndIf
    ElseIf (Not $DCSStatus = "Stopped") Then
        $DCSStatus = "Crashed"
        DCSLog("DCS Crashed", 1)
    EndIf
    GUICtrlSetData($DCSStatusLabel,StringFormat("DCS Server Status: %s",$DCSStatus))
EndFunc

Func KillDCS()
    WinKill("DCS.exe")
    If(@error) Then
        DCSLog(StringFormat("ERROR: %s",_WinAPI_GetLastErrorMessage()) )
        Return 1
    EndIf
    $DCSStartTime = 0
    $DCSStatus = "Stopped"
EndFunc

Func ConfirmDCSAppUpdate()
    
EndFunc

Func StartDCSUpdater($DCSPath)
    Run($DCSPath & "\bin\DCS_updater.exe")
    If(@error) Then
        DCSLog(StringFormat("ERROR: %s",_WinAPI_GetLastErrorMessage()) )
        Return 1
    EndIf
    $DCSStartTime = $CurrentTime
EndFunc

Func DCSLog($Text, $SendWebhook = 0)
    $Message = StringFormat("%s > %s\r\n", $CurrentTime,$Text)
    _GUICtrlEdit_InsertText($DCSLogText,$Message)
    If $WebhookLink And $SendWebhook Then
        Webhook($Text)
    EndIf
EndFunc

Func Webhook($Message)
    Local $Url = $WebhookLink
    ConsoleWrite("in webhook")
    Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
    Local $Packet = '{"content": "```' & $Message & '```"}'
    ConsoleWrite($Packet)
    $oHTTP.Open("POST",$Url)
    $oHTTP.SetRequestHeader("Content-Type","application/json")
    $oHTTP.Send($Packet)
    ConsoleWrite("webhook sent")
EndFunc
