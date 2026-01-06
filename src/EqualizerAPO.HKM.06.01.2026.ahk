#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

FileEncoding, UTF-8 ;Кодировка файла в UTF-8 потому что Eq APO использует данную кодировку при сохранении файла на моей системе, если есть проблема с кодировкой - копать тут
#SingleInstance Force ;Запрет на запуск больше одного истанса, повторный запуск перезапускает скрипт
#NoTrayIcon ; Скрыть значок в трее

;Переменные, которые никуда не сохраняются
global CFG := "EqualizerAPO.HKM.txt"
global TMP := "EqualizerAPO.HKM.tmp"
global LNK := "EqualizerAPO.HKM.lnk"
global OSD_IncludeName :=
global OSD_Device :=
;Переменные по умолчанию
global IncludeName1 := "Название1"
global Include1 := "Include:"
global IncludeName2 := "Название2"
global Include2 := "# Include:"
global IncludeName3 := "Название3"
global Include3 := "# Include:"
global IncludeName4 := "Название4"
global Include4 := "# Include:"
global IncludeName5 := "Название5"
global Include5 := "# Include:"
global Preamp := -30
global VSTPlugin := "# VSTPlugin: Library D:\Programs\VSTPlugins\LoudMax64.dll Thresh 1 Output 1 ""Fader Link"" 0 ""ISP Detection"" 1 ""Large GUI"" 1"
global Device1 := "Out 1-2"
global Device2 := "Наушники"
global Device3 := "# Название3"
global Device4 := "# Название4"
global Device5 := "# Название5"
global PreampStep := 5
global MonitorScale := 200
global Work_mode := 2
global Startup := 1

Firstrun()
ReadCFG()
Autostart()

;Win11 like OSD
SysGet, MonitorWorkArea, MonitorWorkArea, 1
MonitorWidth := MonitorWorkAreaRight - MonitorWorkAreaLeft
MonitorHeight := MonitorWorkAreaBottom - MonitorWorkAreaTop
ControlW := (MonitorWidth // 9.89)										;384px+4px on white bg for 4k
ControlH := (MonitorHeight // 22.04)									;94px+4px on white bg for 4k
ControlWS := ControlW // (MonitorScale // 100)									;194px
ControlHS := ControlH // (MonitorScale // 100)									;49px
global ControlY := MonitorHeight - ControlH - (MonitorHeight // 17.7)	;122px for 4k
Gui +LastFound +AlwaysOnTop -Caption +ToolWindow
Gui, Color, 2C2C2C
Gui, Font, s14, Tahoma
Gui, Margin, 0, 0
Gui, Add, Text, vOSDText c4CC2FF w%ControlWS% h%ControlHS% Center
WinSet, Transparent, 191

;Смена устройства вывода звука, взято отсюда https://www.autohotkey.com/boards/viewtopic.php?f=76&t=49980#p221777
global Devices := {}
IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+3*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 0x1, "UPtrP", IMMDeviceCollection, "UInt")
ObjRelease(IMMDeviceEnumerator)
DllCall(NumGet(NumGet(IMMDeviceCollection+0)+3*A_PtrSize), "UPtr", IMMDeviceCollection, "UIntP", Count, "UInt")
Loop % (Count)
{
	DllCall(NumGet(NumGet(IMMDeviceCollection+0)+4*A_PtrSize), "UPtr", IMMDeviceCollection, "UInt", A_Index-1, "UPtrP", IMMDevice, "UInt")
	DllCall(NumGet(NumGet(IMMDevice+0)+5*A_PtrSize), "UPtr", IMMDevice, "UPtrP", pBuffer, "UInt")
	DeviceID := StrGet(pBuffer, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)
	DllCall(NumGet(NumGet(IMMDevice+0)+4*A_PtrSize), "UPtr", IMMDevice, "UInt", 0x0, "UPtrP", IPropertyStore, "UInt")
	ObjRelease(IMMDevice)
	VarSetCapacity(PROPVARIANT, A_PtrSize == 4 ? 16 : 24)
	VarSetCapacity(PROPERTYKEY, 20)
	DllCall("Ole32.dll\CLSIDFromString", "Str", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "UPtr", &PROPERTYKEY)
	NumPut(14, &PROPERTYKEY + 16, "UInt")
	DllCall(NumGet(NumGet(IPropertyStore+0)+5*A_PtrSize), "UPtr", IPropertyStore, "UPtr", &PROPERTYKEY, "UPtr", &PROPVARIANT, "UInt")
	DeviceName := StrGet(NumGet(&PROPVARIANT + 8), "UTF-16")
	DllCall("Ole32.dll\CoTaskMemFree", "UPtr", NumGet(&PROPVARIANT + 8))
	ObjRelease(IPropertyStore)
	ObjRawSet(Devices, DeviceName, DeviceID)
}
ObjRelease(IMMDeviceCollection)
Return

;$Media_Stop:: ;Fn+F9

$Volume_Mute:: ;Fn+F10 Открыть настройки
	Run, C:\Program Files\EqualizerAPO\Editor.exe, C:\Program Files\EqualizerAPO
	if (Work_mode == 2)
	{
		Run, mmsys.cpl
	}
	return

$<^>!Volume_Mute:: ;Fn+AltGr+F10 Перезапуск скрипта
	msgbox,,, Скрипт перезапущен, 1
	Reload
	return

$Volume_Down:: ;Fn+F11 Уменьшить громкость
	ReadCFG()
	SysVol()
	Preamp -= PreampStep
	VSTPlugin()
	WriteCFG()
	OSD()
	return

$<^>!Volume_Down:: ;Fn+AltGr+F11 Сменить конфиг/устройство
	ReadCFG()
	if (Work_mode == 1)											;Если режим работы через конфиги
	{
		Include_down()
	}
	else if (Work_mode == 2)										;Если режим работы через устройства
	{
		Device2 = # %Device2%
		Device1 := SubStr(Device1, 3)
		OSD_Device = %Device1%
		SetDefaultEndpoint( GetDeviceID(Devices, OSD_Device) )
		
		;Device_down()
	}
	WriteCFG()
	OSD()
	return

$Volume_Up:: ;Fn+F12 Увеличить громкость
	ReadCFG()
	SysVol()
	Preamp += PreampStep
	VSTPlugin()
	WriteCFG()
	OSD()
	return

$<^>!Volume_Up:: ;Fn+AltGr+F12 Сменить конфиг/устройство
	ReadCFG()
	if (Work_mode == 1)											;Если режим работы через конфиги
	{
		Include_up()
	}
	else if (Work_mode == 2)										;Если режим работы через устройства
	{
		Device1 = # %Device1%
		Device2 := SubStr(Device2, 3)
		OSD_Device = %Device2%
		SetDefaultEndpoint( GetDeviceID(Devices, OSD_Device) )
		
		;Device_up()
	}
	WriteCFG()
	OSD()
	return

ReadCFG() ;Чтение конфига
{
	FileReadLine, IncludeName1, %CFG%, 1
	FileReadLine, Include1, %CFG%, 2
	FileReadLine, IncludeName2, %CFG%, 3
	FileReadLine, Include2, %CFG%, 4
	FileReadLine, IncludeName3, %CFG%, 5
	FileReadLine, Include3, %CFG%, 6
	FileReadLine, IncludeName4, %CFG%, 7
	FileReadLine, Include4, %CFG%, 8
	FileReadLine, IncludeName5, %CFG%, 9
	FileReadLine, Include5, %CFG%, 10
	FileReadLine, Preamp, %CFG%, 11
		Preamp := SubStr(Preamp, 9)
	FileReadLine, VSTPlugin, %CFG%, 12
	FileReadLine, Device1, %CFG%, 14
	FileReadLine, Device2, %CFG%, 15
	FileReadLine, Device3, %CFG%, 16
	FileReadLine, Device4, %CFG%, 17
	FileReadLine, Device5, %CFG%, 18
	FileReadLine, PreampStep, %CFG%, 20
	FileReadLine, MonitorScale, %CFG%, 22
	FileReadLine, Work_mode, %CFG%, 24
	FileReadLine, Startup, %CFG%, 26
}

WriteCFG() ;Запись конфига
{
	FileAppend, %IncludeName1%`n, %TMP%
	FileAppend, %Include1%`n, %TMP%
	FileAppend, %IncludeName2%`n, %TMP%
	FileAppend, %Include2%`n, %TMP%
	FileAppend, %IncludeName3%`n, %TMP%
	FileAppend, %Include3%`n, %TMP%
	FileAppend, %IncludeName4%`n, %TMP%
	FileAppend, %Include4%`n, %TMP%
	FileAppend, %IncludeName5%`n, %TMP%
	FileAppend, %Include5%`n, %TMP%
	FileAppend, Preamp: %Preamp%`n, %TMP%
	FileAppend, %VSTPlugin%`n, %TMP%
	FileAppend, # Названия устройств вывода звука в mmsys.cpl`n, %TMP%
	FileAppend, %Device1%`n, %TMP%
	FileAppend, %Device2%`n, %TMP%
	FileAppend, %Device3%`n, %TMP%
	FileAppend, %Device4%`n, %TMP%
	FileAppend, %Device5%`n, %TMP%
	FileAppend, # Шаг регулировки громкости в дБ`n, %TMP%
	FileAppend, %PreampStep%`n, %TMP%
	FileAppend, # Масштабирование монитора в процентах`, применится после перезапуска скрипта`n, %TMP%
	FileAppend, %MonitorScale%`n, %TMP%
	FileAppend, # Режим работы`, 1 - конфиги`, 2 - устройства`n, %TMP%
	FileAppend, %Work_mode%`n, %TMP%
	FileAppend, # Автозагрузка`, 1 - включена`, применится после перезапуска скрипта`n, %TMP%
	FileAppend, %Startup%`n, %TMP%
	FileAppend, # Конец файла, %TMP%
	FileCopy, %TMP%, %CFG%, 1
	FileDelete, %TMP%
}

Firstrun() ;Первоначальная настройка, нужен метод записи конфига
{
	if !FileExist(CFG)
	{
		if !FileExist("C:\Program Files\EqualizerAPO\Editor.exe")
		{
			MsgBox,,, Для начала нужно установить Equalizer APO!, 5
			Run, https://sourceforge.net/projects/equalizerapo/
			exitapp
		}
		WriteCFG()
		MsgBox, 4,, Добавить конфигурационный файл в Equalizer APO?, 5
			IfMsgBox Yes
			{
				EqAPO_CFG := "C:\Program Files\EqualizerAPO\config\config.txt"
				if FileExist(EqAPO_CFG)
				{
					FileAppend, `nDevice: 
					FileAppend, `nInclude: %A_WorkingDir%\%CFG%, %EqAPO_CFG%
				}
				else
				{
					MsgBox,,, %EqAPO_CFG% не найден!, 3
				}
			}
		Run, C:\Program Files\EqualizerAPO\Editor.exe, C:\Program Files\EqualizerAPO
		Run, mmsys.cpl
		MsgBox,,, Первоначальная настройка завершена?`nПоследующее изменение некоторых настроек`nпотребует перезапуска скрипта.
		MsgBox, 4,, Перейти на страницу проекта?, 5
			IfMsgBox Yes
			{
				Run, https://github.com/Croupier42/EqualizerAPO.ahk
			}
	}
}

Autostart() ;Автозагрузка
{
	if (Startup = 1)
	{
		if !FileExist(A_Startup "\" LNK)
		{
			FileCreateShortcut, %A_ScriptFullPath%, %A_Startup%\%LNK%, %A_WorkingDir%
			msgbox,,, Скрипт добавлен в автозагрузку, 1
		}
	}
	else
	{
		if FileExist(A_Startup "\" LNK)
		{
			FileDelete, %A_Startup%\%LNK%
			msgbox,,, Скрипт удален из автозагрузки, 1
		}
	}
}

SysVol() ;Установка системной громкости на 100%
{
	SoundGet, SystemVolume
	if (SystemVolume != 100)
	{
		SoundSet, 100
	}
}

VSTPlugin() ;Переключение VST плагина
{
	if (Preamp <= 0)
	{
		if (SubStr(VSTPlugin, 1, 1) != "#")
		{
			VSTPlugin = # %VSTPlugin%
		}
	}
	else
	{
		if (SubStr(VSTPlugin, 1, 1) == "#")
		{
			VSTPlugin := SubStr(VSTPlugin, 3)
		}
	}
}

Include_up() ;Переключение конфига вверх
{
	if (SubStr(Include1, 1, 1) != "#")
	{
		Include1 = # %Include1%
		Include2 := SubStr(Include2, 3)
	}
	else if (SubStr(Include2, 1, 1) != "#")
	{
		Include2 = # %Include2%
		Include3 := SubStr(Include3, 3)
	}
	else if (SubStr(Include3, 1, 1) != "#")
	{
		Include3 = # %Include3%
		Include4 := SubStr(Include4, 3)
	}
	else if (SubStr(Include4, 1, 1) != "#")
	{
		Include4 = # %Include4%
		Include5 := SubStr(Include5, 3)
	}
	else if  (SubStr(Include5, 1, 1) != "#")
	{
		Include5 = # %Include5%
		Include1 := SubStr(Include1, 3)
	}
}

Include_down() ;Переключение конфига вниз
{
	if (SubStr(Include1, 1, 1) != "#")
	{
		Include1 = # %Include1%
		Include5 := SubStr(Include5, 3)
	}
	else if (SubStr(Include2, 1, 1) != "#")
	{
		Include2 = # %Include2%
		Include1 := SubStr(Include1, 3)
	}
	else if (SubStr(Include3, 1, 1) != "#")
	{
		Include3 = # %Include3%
		Include2 := SubStr(Include2, 3)
	}
	else if (SubStr(Include4, 1, 1) != "#")
	{
		Include4 = # %Include4%
		Include3 := SubStr(Include3, 3)
	}
	else if  (SubStr(Include5, 1, 1) != "#")
	{
		Include5 = # %Include5%
		Include4 := SubStr(Include4, 3)
	}
}

Device_up() ;Переключение устройства вверх
{
	if (SubStr(Device1, 1, 1) != "#")
	{
		Device1 = # %Device1%
		Device2 := SubStr(Device2, 3)
		OSD_Device = %Device2%
	}
	else if (SubStr(Device2, 1, 1) != "#")
	{
		Device2 = # %Device2%
		Device3 := SubStr(Device3, 3)
		OSD_Device = %Device3%
	}
	else if (SubStr(Device3, 1, 1) != "#")
	{
		Device3 = # %Device3%
		Device4 := SubStr(Device4, 3)
		OSD_Device = %Device4%
	}
	else if (SubStr(Device4, 1, 1) != "#")
	{
		Device4 = # %Device4%
		Device5 := SubStr(Device5, 3)
		OSD_Device = %Device5%
	}
	else if  (SubStr(Device5, 1, 1) != "#")
	{
		Device5 = # %Device5%
		Device1 := SubStr(Device1, 3)
		OSD_Device = %Device1%
	}
	SetDefaultEndpoint( GetDeviceID(Devices, OSD_Device) )
}

Device_down() ;Переключение устройства вниз
{
	if (SubStr(Device1, 1, 1) != "#")
	{
		Device1 = # %Device1%
		Device5 := SubStr(Device5, 3)
		OSD_Device = %Device5%
	}
	else if (SubStr(Device2, 1, 1) != "#")
	{
		Device2 = # %Device2%
		Device1 := SubStr(Device1, 3)
		OSD_Device = %Device1%
	}
	else if (SubStr(Device3, 1, 1) != "#")
	{
		Device3 = # %Device3%
		Device2 := SubStr(Device2, 3)
		OSD_Device = %Device2%
	}
	else if (SubStr(Device4, 1, 1) != "#")
	{
		Device4 = # %Device4%
		Device3 := SubStr(Device3, 3)
		OSD_Device = %Device3%
	}
	else if  (SubStr(Device5, 1, 1) != "#")
	{
		Device5 = # %Device5%
		Device4 := SubStr(Device4, 3)
		OSD_Device = %Device4%
	}
	SetDefaultEndpoint( GetDeviceID(Devices, OSD_Device) )
}

OSD() ;Обновление OSD
{
	OSD_Preamp = Громкость: %Preamp% дБ
	if (Work_mode == 1)												;Если режим работы через конфиги
	{
		if (SubStr(Include1, 1, 1) != "#")
		{
			OSD_IncludeName = %IncludeName1%
		}
		else if (SubStr(Include2, 1, 1) != "#")
		{
			OSD_IncludeName = %IncludeName2%
		}
		else if (SubStr(Include3, 1, 1) != "#")
		{
			OSD_IncludeName = %IncludeName3%
		}
		else if (SubStr(Include4, 1, 1) != "#")
		{
			OSD_IncludeName = %IncludeName4%
		}
		else if  (SubStr(Include5, 1, 1) != "#")
		{
			OSD_IncludeName = %IncludeName5%
		}
		GuiControl, Text, OSDText, %OSD_IncludeName%`n%OSD_Preamp%
	}
	else if (Work_mode == 2)										;Если режим работы через устройства
	{
		if (SubStr(Device1, 1, 1) != "#")
		{
			OSD_Device = %Device1%
		}
		else if (SubStr(Device2, 1, 1) != "#")
		{
			OSD_Device = %Device2%
		}
		else if (SubStr(Device3, 1, 1) != "#")
		{
			OSD_Device = %Device3%
		}
		else if (SubStr(Device4, 1, 1) != "#")
		{
			OSD_Device = %Device4%
		}
		else if  (SubStr(Device5, 1, 1) != "#")
		{
			OSD_Device = %Device5%
		}
		GuiControl, Text, OSDText, %OSD_Device%`n%OSD_Preamp%
	}
	Gui, Show, xCenter y%ControlY% NoActivate
	SetTimer, HideOSD, 1500
	return
	HideOSD:
	Gui, Hide
	return
}

SetDefaultEndpoint(DeviceID) ;Смена устройства вывода звука, взято отсюда https://www.autohotkey.com/boards/viewtopic.php?f=76&t=49980#p221777
{
	IPolicyConfig := ComObjCreate("{870af99c-171d-4f9e-af0d-e63df40c2bc9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
	DllCall(NumGet(NumGet(IPolicyConfig+0)+13*A_PtrSize), "UPtr", IPolicyConfig, "UPtr", &DeviceID, "UInt", 0, "UInt")
	ObjRelease(IPolicyConfig)
}

GetDeviceID(Devices, Name) ;Смена устройства вывода звука, взято отсюда https://www.autohotkey.com/boards/viewtopic.php?f=76&t=49980#p221777
{
	For DeviceName, DeviceID in Devices
		If (InStr(DeviceName, Name))
			Return DeviceID
}
