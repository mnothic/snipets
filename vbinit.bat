:: init and shutdown vbox machine in windows 7
:: run headless vm and mount nfs shares
:: copy to desktop and click it 
:: before rpi dns load vm dns now is commented

@echo off
set flag=C:\vmstarted
set prefix=C:\Program Files\Oracle\VirtualBox
if exist %flag% (
	set cmd=VBoxManage
	set action=controlvm
	set subfix=savestate
	del %flag%
) else (
	copy /y NUL %flag% >NUL
	set cmd=VBoxManage
	set action=startvm
	set subfix=--type headless
)

::"%prefix%\%cmd%" %action% named %subfix%
::timeout 10
"%prefix%\%cmd%" %action% puppet %subfix%
"%prefix%\%cmd%" %action% django %subfix%

::if exist  %flag% (
::	timeout 20 
::	ipconfig /flushdns
::	ipconfig /registerdns
::)

mount -o anon,nolock,casesensitive=yes \\django\share z:
