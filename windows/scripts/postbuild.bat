set INIT_DIR=%cd%
set OUT_DIR=%~1
cd %OUT_DIR%
cd data\flutter_assets
rmdir /s /q assets
mklink /d assets ..\..\assets
cd ..\..
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