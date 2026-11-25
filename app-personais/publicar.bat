@echo off
chcp 65001 >nul
title Publicar PT example
cd /d "%~dp0"
echo ============================================
echo   Publicar o PT example na Vercel
echo ============================================
echo.
where node >nul 2>nul
if errorlevel 1 (
  echo [ERRO] O Node.js nao esta instalado. Instala em https://nodejs.org
  pause
  exit /b 1
)
echo (Se pedir login, segue as instrucoes que aparecem no ecra.)
call npx vercel --prod --yes
if errorlevel 1 goto erro
echo.
echo Pronto! O site foi publicado. O endereco aparece acima.
pause
exit /b 0
:erro
echo.
echo [ERRO] Algo correu mal. Copia o texto acima e envia a quem gere o site.
pause
exit /b 1
