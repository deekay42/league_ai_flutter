set INIT_DIR=%cd%
set OUT_DIR=%~1
cd %OUT_DIR%
REM cd data\flutter_assets
REM rmdir /s /q assets
REM mklink /d assets ..\..\assets
REM cd ..\..
del /Q /S *.pdb
del /Q /S *.exp
del /Q /S *.lib
del /Q /S *.iobj
del /Q /S *.ipdb
del /Q /S *ai_loaded*
del /Q /S uid
del /Q /S secret
del /Q /S db_key
cd %INIT_DIR%