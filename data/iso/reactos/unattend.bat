@echo off

:: Install srvany-ng
copy "D:\reactos\3rdParty\srvany-ng.exe" "%SystemRoot%\bin\srvany-ng.exe"

:: Install ncat
copy "D:\reactos\3rdParty\ncat.exe" "%SystemRoot%\bin\ncat.exe"

:: Install Samba
copy "D:\reactos\3rdParty\samba.exe" "%SystemRoot%\bin\samba.exe"
"%SystemRoot%\bin\samba.exe" -s

:: Install BusyBox
copy "D:\reactos\3rdParty\busybox.exe" "%SystemRoot%\bin\busybox.exe"

:: Enable BindShell
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell"
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v DisplayName /t REG_SZ /d "BindShell" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v Description /t REG_SZ /d "Allows remote access" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v ErrorControl /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v ImagePath /t REG_EXPAND_SZ /d "srvany-ng.exe" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v ObjectName /t REG_SZ /d "LocalSystem" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v Start /t REG_DWORD /d 2 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell" /v Type /t REG_DWORD /d 16 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell\Parameters"
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell\Parameters" /v Application /t REG_SZ /d "%SystemRoot%\bin\ncat.exe" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell\Parameters" /v AppParameters /t REG_SZ /d "-l -k -n -e \"cmd.exe /c (cmd.exe 2^>^&1)\" 51" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BindShell\Parameters" /v AppDirectory /t REG_SZ /d "%SystemDrive%\\" /f

:: Set UTF-8 encoding in CMD
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_EXPAND_SZ /d "CHCP 65001" /f

"%SystemRoot%\system32\shutdown.exe" /s /t 5
