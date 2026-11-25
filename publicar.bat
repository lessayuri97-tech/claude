@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Publicar o site da Growky

rem ============ Configuração (pode alterar) ============
set "REPO_URL=https://github.com/lessayuri97-tech/claude.git"
set "BRANCH=gh-pages"
set "SITE_URL=https://lessayuri97-tech.github.io/claude/"
rem =====================================================

cd /d "%~dp0"

echo.
echo  ==============================================
echo     GROWKY  -  Publicar o site
echo  ==============================================
echo.

if not exist "index.html" goto :sem_index

where git >nul 2>nul
if errorlevel 1 goto :sem_git

rem Aviso se o WhatsApp ainda for o número de exemplo
findstr /c:"PLACEHOLDER" config.js >nul 2>nul
if errorlevel 1 goto :preparar
echo  [AVISO] O config.js ainda tem o número de WhatsApp de exemplo.
choice /c SN /m "  Quer publicar mesmo assim"
if errorlevel 2 goto :cancelado
echo.

:preparar
if exist ".git" goto :remoto
echo  A preparar a pasta para a primeira publicação...
git init -q
git symbolic-ref HEAD refs/heads/%BRANCH%

:remoto
git remote get-url origin >nul 2>nul
if errorlevel 1 git remote add origin "%REPO_URL%"

git config user.name >nul 2>nul || git config user.name "Growky"
git config user.email >nul 2>nul || git config user.email "312058176+lessayuri97-tech@users.noreply.github.com"

if not exist ".nojekyll" type nul > ".nojekyll"

echo  [1/2] A guardar as alterações...
git add -A
git diff --cached --quiet
if not errorlevel 1 goto :nada_novo
git commit -q -m "Atualizar site - %date% %time%"
if errorlevel 1 goto :erro_commit
goto :enviar

:nada_novo
echo        Não há alterações novas desde a última vez.

:enviar
echo  [2/2] A enviar para o GitHub...
echo        Se aparecer uma janela do GitHub, inicie sessão e autorize.
echo.
git push -u origin HEAD:%BRANCH%
if errorlevel 1 goto :erro_push

echo.
echo  ==============================================
echo     SUCESSO! O site foi enviado.
echo  ==============================================
echo.
echo  Endereço: %SITE_URL%
echo  As alterações demoram 1 a 2 minutos a aparecer online.
echo.
choice /c SN /m "  Abrir o site no navegador"
if errorlevel 2 goto :fim
start "" "%SITE_URL%"
goto :fim

:sem_index
echo  [ERRO] Não encontrei o index.html nesta pasta.
echo         Coloque o publicar.bat dentro da pasta do site, junto ao index.html.
goto :falhou

:sem_git
echo  [ERRO] O Git não está instalado neste computador.
echo         Instale-o em https://git-scm.com/download/win
echo         e depois volte a fazer duplo clique neste ficheiro.
goto :falhou

:erro_commit
echo  [ERRO] Não foi possível guardar as alterações. Veja a mensagem acima.
goto :falhou

:erro_push
echo.
echo  [ERRO] Não foi possível enviar para o GitHub. Causas mais comuns:
echo         - sem ligação à internet;
echo         - não iniciou sessão no GitHub, ou a conta não tem acesso ao repositório;
echo         - o GitHub tem alterações que não estão nesta pasta.
goto :falhou

:cancelado
echo.
echo  Publicação cancelada. Nada foi enviado.
goto :fim

:falhou
echo.
echo  A publicação NÃO foi concluída.

:fim
echo.
pause
endlocal
