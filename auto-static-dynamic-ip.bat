@echo off
::Check for admin rights
net session >nul 2>&1
::If the above command fails the errorlevel will be non-zero.
::If non-zero the PowerShell (min version supported is 2.0) Will re-run the script and ask for admin rights.
if not %errorlevel% == 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

::Configure those variables to match your Wireless adapter name, home ssid, static local ip, subnet mask and router ip.
set "adapterName=WLAN"
set "home_ssid=Tele2_b9e316"
set "static_ip=192.168.0.210"
set "subnet_mask=255.255.255.0"
set "router_ip=192.168.0.1"
set /a timer=5
set "script_path=%UserProfile%"
::Set install=0 if you don't want installation in the task scheduler
set /a install=0
::Set uninstall=1 if you want to remove the task from the task scheduler
set /a uninstall=0

::==============DON"T CHANGE THINGS BELOW THIS LINE===================
for %%f in ("%0") do (
    set task_name=%%~nf
    set file_name=%%~nxf
)

if %install% equ 0 (
    goto :START
)
if %uninstall% equ 1 (
    goto :UNINSTALL
)

:INSTALL
::This will search for the task in the scheduler. If the errorlevel is not equal
::0 the search failed and the clause will be activated to install the task.
%SystemRoot%\system32\schtasks /query /tn %task_name% >nul 2>&1
if %errorlevel% neq 0 (
    echo Task %task_name% does not exist. Creating...
    if not exist "%script_path%\%0" (
        copy %0 %script_path% >nul 2>&1
        echo Copied %0 to %script_path%
    )
    %SystemRoot%\system32\schtasks /create /tn %task_name% /tr "%script_path%\%file_name%" /sc onlogon /rl highest /f >nul 2>&1
    echo The task %task_name% was added to the scheduler.
    pause && exit
)

:START
::Leave untouched
set "dhcpEnabled=ZERO"
::Run the netsh command and split the result in tokens using ':' as a delimeter. ::Then assign the 3rd token to the variable. The result can be either "Yes" or "No".
for /f "tokens=3 delims=: " %%i in ('netsh interface ipv4 show config name^="%adapterName%" ^| findstr /i /c:"DHCP enabled"') do (
    set "dhcpEnabled=%%i"
)

::Huston we have a problem! If everything goes well you should never see this.
if /i "%dhcpEnabled%" == "ZERO" (
	echo ERROR: Could not get DHCP information.
    pause && exit
)

::Run the netsh command and split the result in tokens using ':' as a delimeter.
::Then echo the 2nd token in and repeat the process.
for /f "tokens=2 delims=: " %%f in ('netsh wlan show interfaces ^| findstr /i /c:"Profile"') do (
    echo You are connected to %%f network.
    ::Using '-' as a delimeter split in tokens and check if the 1st token matches you home ssid. 
    for /f "tokens=1 delims=-" %%i in ('echo %%f') do (
        if %%i == %home_ssid% (
		    goto :HOME
        )
    )
    goto :!HOME
)

:HOME
::If the IP is already static do nothing, else goto :STATIC
echo You are at home
if /i "%dhcpEnabled%"=="No" (
    echo Your IP is static.
    goto :END
) else (
    goto :STATIC
)

:!HOME
::If the IP is already dynamic do nothing, else goto dhcp
echo You are not at home!
if /i "%dhcpEnabled%"=="Yes" (
    echo Your IP is assigned by DHCP.
    goto :END
) else (
    goto :DHCP
)

:STATIC
::Set static IP
echo Setting static ip...
netsh interface ip set address "%adapterName%" static %static_ip% %subnet_mask% %router_ip%
goto :END

:DHCP
::Set dynamic IP
echo Setting dynamic ip... 
netsh int ip set address name = "%adapterName%" source = dhcp
goto :END

:END
ping 127.0.0.1 -n %timer%% >nul
goto :EOF

:UNINSTALL
%SystemRoot%\system32\schtasks /query /tn %task_name% >nul 2>&1
if %errorlevel% equ 0 (
    echo Task exists, deleting...
    schtasks /delete /tn %task_name% /f >nul 2>&1
    del "%script_path%\%file_name%"
    echo %file_name% was removed from the scheduler and from %UserProfile%.
    pause && exit
)

echo If you see this, the script is already unistalled and you tried to unistall it again. Set uninstall to 0
pause