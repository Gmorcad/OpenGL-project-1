@echo off
echo Building...

nasm -f win64 main.asm -o main.obj
if errorlevel 1 goto error

gcc main.obj -o game.exe -mconsole "C:\glfw-3.5.1.bin.WIN64\lib-mingw-w64\libglfw3.a" -lopengl32 -lgdi32
if errorlevel 1 goto error

echo.
echo Build successful
echo Running...
echo.

game.exe
goto end

:error
echo.
echo Build failed

:end
echo.
pause
