!include "MUI2.nsh"
!define MUI_ICON "..\assets\icons\logo_new.ico"
!define MUI_PRODUCT "LeagueAI"
!define MUI_COMPONENTSPAGE_NODESC
SetCompressor /SOLID bzip2
 
caption "Install League AI"
;---------------------------------
;General
 
  OutFile "Install League AI.exe"
  ShowInstDetails "nevershow"
  ShowUninstDetails "nevershow"
  ;SetCompressor "bzip2"
 



!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "..\assets\icons\logo.bmp"
!define MUI_HEADERIMAGE_RIGHT


InstallDir "$PROGRAMFILES\${MUI_PRODUCT}"
 
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
 
 
;--------------------------------
;Language
 
  !insertmacro MUI_LANGUAGE "English"
 

;-------------------------------- 
;Modern UI System
 

Section

  SetOutPath "$INSTDIR"
  File /nonfatal /a /r "..\build\windows\runner\Release\"
  ;CreateShortCut "$INSTDIR\data\flutter_assets\assets.lnk" "$INSTDIR\assets"


 
SectionEnd

Section "Desktop Shortcuts" desktops

;create desktop shortcut
  CreateShortCut "$DESKTOP\${MUI_PRODUCT}.lnk" "$INSTDIR\${MUI_PRODUCT}.exe" ""
 

SectionEnd

Section "Start Menu Items" starts
;create start-menu items
  CreateShortCut "$SMPROGRAMS\${MUI_PRODUCT}.lnk" "$INSTDIR\${MUI_PRODUCT}.exe" "" "$INSTDIR\${MUI_PRODUCT}.exe" 0
 

SectionEnd
 


 
;--------------------------------    
;MessageBox Section
 
 
;Function that calls a messagebox when installation finished correctly
Function .onInstSuccess
  MessageBox MB_OK "You have successfully installed ${MUI_PRODUCT}. Use the desktop icon to start the program."
FunctionEnd

