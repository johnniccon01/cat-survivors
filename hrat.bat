@echo off
rem Spusti Cat Survivors na akomkolvek PC.
rem Hlada Godot 4.6 (win64): premenna GODOT, priecinok godot\ vedla hry,
rem Stiahnute subory (Downloads) a Program Files. Pri prvom spusteni
rem naimportuje obrazky a zvuky (chvilu to trva), neskor len zmeny.
rem   hrat.bat         spusti hru
rem   hrat.bat check   len vypise, ktory Godot nasiel
setlocal
cd /d "%~dp0"
set "G=%GODOT%"
if not defined G for /r "%~dp0godot" %%f in (Godot_v4.6*_win64.exe) do if not defined G set "G=%%f"
if not defined G for /r "%USERPROFILE%\Downloads" %%f in (Godot_v4.6*_win64.exe) do if not defined G set "G=%%f"
if not defined G for /r "%ProgramFiles%\Godot" %%f in (Godot_v4.6*_win64.exe) do if not defined G set "G=%%f"
if not defined G for /r "%USERPROFILE%\Desktop" %%f in (Godot_v4.6*_win64.exe) do if not defined G set "G=%%f"
if not defined G (
  echo Godot 4.6 sa nenasiel.
  echo Stiahni Godot 4.6.2 ^(Windows, 64-bit^) z https://godotengine.org/download/archive/
  echo a rozbal ho do priecinka Downloads alebo do priecinka "godot" vedla tejto hry,
  echo alebo nastav premennu GODOT na cestu k Godot_v4.6.2-stable_win64.exe.
  pause
  exit /b 1
)
if /i "%~1"=="check" (
  echo Godot: %G%
  exit /b 0
)
rem Import vzdy (po git pull mozu pribudnut skripty, obrazky, preklady);
rem ked sa nic nezmenilo, trva to par sekund.
if not exist ".godot\imported" echo Prvy start na tomto PC: importujem obrazky a zvuky...
"%G%" --headless --path "%~dp0." --import
start "" "%G%" --path "%~dp0."
