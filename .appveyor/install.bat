@echo off

cd %APPVEYOR_BUILD_FOLDER%

:: =========================================================
:: Set some defaults. Infer some variables.
::
:: These are set globally
if "%LUA_VER%" NEQ "" (
	set LUA=lua
	set LUA_SHORTV=%LUA_VER:~0,3%
) else (
	set LUA=luajit
	set LJ_SHORTV=%LJ_VER:~0,3%
	set LUA_SHORTV=5.1
)

:: defines LUA_DIR so Cmake can find this Lua install
if "%LUA%"=="luajit" (
	set LUA_DIR=c:\lua\%platform%\lj%LJ_SHORTV%
) else (
	set LUA_DIR=c:\lua\%platform%\%LUA_VER%
)

:: Now we declare a scope
Setlocal EnableDelayedExpansion EnableExtensions

if "%LUAROCKS_VER%" NEQ "HEAD" (
	set LUAROCKS_SHORTV=%LUAROCKS_VER:~0,3%
) else (
	:: Assume 2.2 for the time being. TODO: fix this
	set LUAROCKS_SHORTV=2.2
)

if not defined LUAROCKS_URL set LUAROCKS_URL=http://keplerproject.github.io/luarocks/releases
if not defined LUAROCKS_REPO set LUAROCKS_REPO=https://luarocks.org
if not defined LUA_URL set LUA_URL=http://www.lua.org/ftp
if defined NOCOMPAT (
	set COMPATFLAG=--nocompat
) else (
	set COMPATFLAG=
)
if not defined LUAJIT_GIT_REPO set LUAJIT_GIT_REPO=http://luajit.org/git/luajit-2.0.git
if not defined LUAJIT_URL set LUAJIT_URL=http://luajit.org/download

if not defined LR_EXTERNAL set LR_EXTERNAL=c:\external
if not defined LUAROCKS_INSTALL set LUAROCKS_INSTALL=%LUA_DIR%\LuaRocks
if not defined LR_ROOT set LR_ROOT=%LUAROCKS_INSTALL%\%LUAROCKS_SHORTV%
if not defined LR_SYSTREE set LR_SYSTREE=%LUAROCKS_INSTALL%\systree

if not defined SEVENZIP set SEVENZIP=7z
::
:: =========================================================

:: first create some necessary directories:
mkdir downloads 2>NUL

:: Download and compile Lua (or LuaJIT)
if "%LUA%"=="luajit" (
	if not exist %LUA_DIR% (
		if "%LJ_SHORTV%"=="2.1" (
			:: Clone repository and checkout 2.1 branch
			set lj_source_folder=%APPVEYOR_BUILD_FOLDER%\downloads\luajit-%LJ_VER%
			if not exist !lj_source_folder! (
				echo Cloning git repo %LUAJIT_GIT_REPO% !lj_source_folder!
				git clone %LUAJIT_GIT_REPO% !lj_source_folder! || call :die "Failed to clone repository"
			) else (
				cd !lj_source_folder!
				git pull || call :die "Failed to update repository"
			)
			cd !lj_source_folder!\src
			git checkout v2.1 || call :die
		) else (
			set lj_source_folder=%APPVEYOR_BUILD_FOLDER%\downloads\luajit-%LJ_VER%
			if not exist !lj_source_folder! (
				echo Downloading... %LUAJIT_URL%/LuaJIT-%LJ_VER%.tar.gz
				curl --silent --fail --max-time 120 --connect-timeout 30 %LUAJIT_URL%/LuaJIT-%LJ_VER%.tar.gz | %SEVENZIP% x -si -so -tgzip | %SEVENZIP% x -si -ttar -aoa -odownloads
			)
			cd !lj_source_folder!\src
		)
		:: Compiles LuaJIT
		call msvcbuild.bat

		mkdir %LUA_DIR% 2> NUL
		for %%a in (bin bin\lua bin\lua\jit include lib) do ( mkdir "%LUA_DIR%\%%a" )

		for %%a in (luajit.exe lua51.dll) do ( move "!lj_source_folder!\src\%%a" "%LUA_DIR%\bin" )
		copy "%LUA_DIR%\bin\luajit.exe" "%LUA_DIR%\bin\lua.exe"

		move "!lj_source_folder!\src\lua51.lib" "%LUA_DIR%\lib"
		for %%a in (lauxlib.h lua.h lua.hpp luaconf.h lualib.h luajit.h) do (
			copy "!lj_source_folder!\src\%%a" "%LUA_DIR%\include"
		)

		copy "!lj_source_folder!\src\jit\*.lua" "%LUA_DIR%\bin\lua\jit"

	) else (
		echo LuaJIT %LJ_VER% already installed at %LUA_DIR%
	)
) else (
	if not exist %LUA_DIR% (
		:: Download and compile Lua
		if not exist downloads\lua-%LUA_VER% (
			curl --silent --fail --max-time 120 --connect-timeout 30 %LUA_URL%/lua-%LUA_VER%.tar.gz | %SEVENZIP% x -si -so -tgzip | %SEVENZIP% x -si -ttar -aoa -odownloads
		)

		mkdir downloads\lua-%LUA_VER%\etc 2> NUL
		if not exist downloads\lua-%LUA_VER%\etc\winmake.bat (
			curl --silent --location --insecure --fail --max-time 120 --connect-timeout 30 https://github.com/Tieske/luawinmake/archive/master.tar.gz | %SEVENZIP% x -si -so -tgzip | %SEVENZIP% e -si -ttar -aoa -odownloads\lua-%LUA_VER%\etc luawinmake-master\etc\winmake.bat
		)

		cd downloads\lua-%LUA_VER%
		call etc\winmake %COMPATFLAG%
		call etc\winmake install %LUA_DIR%
	) else (
		echo Lua %LUA_VER% already installed at %LUA_DIR%
	)
)

if not exist %LUA_DIR%\bin\%LUA%.exe call :die "Missing Lua interpreter at %LUA_DIR%\bin\%LUA%.exe"

set PATH=%LUA_DIR%\bin;%PATH%
call !LUA! -v



:: =========================================================
:: LuaRocks
:: =========================================================

if not exist "%LR_ROOT%" (
	:: Downloads and installs LuaRocks
	cd %APPVEYOR_BUILD_FOLDER%

	if %LUAROCKS_VER%==HEAD (
		set lr_source_folder=%APPVEYOR_BUILD_FOLDER%\downloads\luarocks-%LUAROCKS_VER%-win32
		if not exist !lr_source_folder! (
			git clone https://github.com/keplerproject/luarocks.git --single-branch --depth 1 !lr_source_folder! || call :die "Failed to clone LuaRocks repository"
		) else (
			cd !lr_source_folder!
			git pull || call :die "Failed to update LuaRocks repository"
		)
	) else (
		if not exist downloads\luarocks-%LUAROCKS_VER%-win32.zip (
			echo Downloading LuaRocks...
			curl --silent --fail --max-time 120 --connect-timeout 30 --output downloads\luarocks-%LUAROCKS_VER%-win32.zip %LUAROCKS_URL%/luarocks-%LUAROCKS_VER%-win32.zip
			%SEVENZIP% x -aoa -odownloads downloads\luarocks-%LUAROCKS_VER%-win32.zip
		)
	)

	cd downloads\luarocks-%LUAROCKS_VER%-win32
	call install.bat /LUA %LUA_DIR% /Q /LV %LUA_SHORTV% /P "%LUAROCKS_INSTALL%" /TREE "%LR_SYSTREE%"
)

if not exist "%LR_ROOT%" call :die "LuaRocks not found at %LR_ROOT%"

set PATH=%LR_ROOT%;%LR_SYSTREE%\bin;%PATH%

:: Lua will use just the system rocks
set LUA_PATH=%LR_ROOT%\lua\?.lua;%LR_ROOT%\lua\?\init.lua
set LUA_PATH=%LUA_PATH%;%LR_SYSTREE%\share\lua\%LUA_SHORTV%\?.lua
set LUA_PATH=%LUA_PATH%;%LR_SYSTREE%\share\lua\%LUA_SHORTV%\?\init.lua
set LUA_PATH=%LUA_PATH%;.\?.lua;.\?\init.lua
set LUA_CPATH=%LR_SYSTREE%\lib\lua\%LUA_SHORTV%\?.dll;.\?.dll

call luarocks --version || call :die "Error with LuaRocks installation"
call luarocks list


if not exist "%LR_EXTERNAL%" (
	mkdir "%LR_EXTERNAL%"
	mkdir "%LR_EXTERNAL%\lib"
	mkdir "%LR_EXTERNAL%\include"
)

set PATH=%LR_EXTERNAL%;%PATH%

:: Exports the following variables:
:: (beware of whitespace between & and ^ below)
endlocal & set PATH=%PATH%&^
set LR_SYSTREE=%LR_SYSTREE%&^
set LUA_PATH=%LUA_PATH%&^
set LUA_CPATH=%LUA_CPATH%&^
set LR_EXTERNAL=%LR_EXTERNAL%

echo.
echo ======================================================
if "%LUA%"=="luajit" (
	echo Installation of LuaJIT %LJ_VER% and LuaRocks %LUAROCKS_VER% done.
) else (
	echo Installation of Lua %LUA_VER% and LuaRocks %LUAROCKS_VER% done.
	if defined NOCOMPAT echo Lua was built with compatibility flags disabled.
)
echo Platform         - %platform%
echo LUA              - %LUA%
echo LUA_SHORTV       - %LUA_SHORTV%
echo LJ_SHORTV        - %LJ_SHORTV%
echo LUA_PATH         - %LUA_PATH%
echo LUA_CPATH        - %LUA_CPATH%
echo.
echo LR_EXTERNAL      - %LR_EXTERNAL%
echo ======================================================
echo.

goto :eof


















:: This blank space is intentional. If you see errors like "The system cannot find the batch label specified 'foo'"
:: then try adding or removing blank lines lines above.
:: Yes, really.
:: http://stackoverflow.com/questions/232651/why-the-system-cannot-find-the-batch-label-specified-is-thrown-even-if-label-e

:: helper functions:

:: for bailing out when an error occurred
:die %1
echo %1
exit /B 1
goto :eof

