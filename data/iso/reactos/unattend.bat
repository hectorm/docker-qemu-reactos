@echo off

:: Install Samba
copy "D:\reactos\3rdParty\samba.exe" "%SystemRoot%\bin\samba.exe"
"%SystemRoot%\bin\samba.exe" -s

:: Install BusyBox
copy "D:\reactos\3rdParty\busybox.exe" "%SystemRoot%\bin\busybox.exe"

:: Install bind shell service
copy "D:\reactos\3rdParty\ncat.exe" "%SystemRoot%\bin\ncat.exe"
sc create "BindShell" ^
	DisplayName= "Bind shell" ^
	BinPath= "ncat.exe -l -k -n -e \"cmd.exe /c (cmd.exe 2^>^&1)\" 51" ^
	Error= "ignore" ^
	Start= "auto"

:: Set UTF-8 encoding in CMD
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_EXPAND_SZ /d "CHCP 65001" /f

"%SystemRoot%\system32\shutdown.exe" /s /t 5
