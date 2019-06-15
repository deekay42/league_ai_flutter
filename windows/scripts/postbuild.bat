set OUT_DIR=%~1
rmdir /s /q %OUT_DIR%\data\flutter_assets\assets
mklink /d %OUT_DIR%\data\flutter_assets\assets %OUT_DIR%\assets
del /Q /S %OUT_DIR%\*.pdb
del /Q /S %OUT_DIR%\*.exp
del /Q /S %OUT_DIR%\*.lib
del /Q /S %OUT_DIR%\*.iobj
del /Q /S %OUT_DIR%\*.ipdb
del /Q /S %OUT_DIR%\*ai_loaded*
del /Q /S %OUT_DIR%\uid
del /Q /S %OUT_DIR%\secret
del /Q /S %OUT_DIR%\db_key