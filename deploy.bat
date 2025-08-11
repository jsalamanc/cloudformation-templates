@echo off

REM Configurar manejo de errores
setlocal EnableDelayedExpansion

REM Variable para rastrear si hubo errores
set "ERROR_OCCURRED=false"

REM Ejecutar limpieza inicial al comenzar
call :initial_cleanup

cd lambda-layer

echo ----------------------------------------
echo creando carpeta python...
echo ----------------------------------------
mkdir python
if %ERRORLEVEL% neq 0 goto error_handler

echo ----------------------------------------
echo instalando opensearch-py...
echo ----------------------------------------
pip install opensearch-py boto3 -t python/
if %ERRORLEVEL% neq 0 goto error_handler
echo ----------------------------------------
echo opensearch-py instalado...
echo ----------------------------------------

echo ----------------------------------------
echo instalando cfnresponse...
echo ----------------------------------------
pip install cfnresponse -t python/
if %ERRORLEVEL% neq 0 goto error_handler
echo ----------------------------------------
echo cfnresponse instalado...
echo ----------------------------------------

echo ----------------------------------------
echo Empaquetando layers...
echo ----------------------------------------
powershell Compress-Archive -Path ".\python" -DestinationPath ".\my_dependencies_layer.zip"
if %ERRORLEVEL% neq 0 goto error_handler

echo ----------------------------------------
echo Subiendo layers a s3...
echo ----------------------------------------
aws s3 cp my_dependencies_layer.zip s3://layer-artifacts-lambdas/
if %ERRORLEVEL% neq 0 goto error_handler

echo ----------------------------------------
echo layers subidos..
echo ----------------------------------------
echo eliminando carpeta python...
rmdir /S /Q ".\python"
if %ERRORLEVEL% neq 0 goto error_handler
echo ----------------------------------------
echo carpeta python eliminada.
echo ----------------------------------------

echo eliminando my_dependencies_layer.zip...
del my_dependencies_layer.zip
if %ERRORLEVEL% neq 0 goto error_handler
echo ----------------------------------------
echo my_dependencies_layer.zip eliminando.
echo ----------------------------------------

echo ========================================
echo Empaquetando codigo Lambda...
echo ========================================

REM Recorrer la carpeta functions y comprimir cada lambda individualmente
cd ..\src\functions

REM Obtener la lista de archivos .py en la carpeta functions
for %%f in (*.py) do (
    echo ----------------------------------------
    echo Comprimiendo %%f...
    echo ----------------------------------------
    powershell Compress-Archive -Path "%%f" -DestinationPath "..\..\%%~nf.zip" -Force
    if !ERRORLEVEL! neq 0 (
        echo ----------------------------------------
        echo ❌ Error al comprimir %%f
        echo ----------------------------------------
        set "ERROR_OCCURRED=true"
        call :cleanup_temp_files
        goto end_script
    )
    
    echo ----------------------------------------
    echo Subiendo %%~nf.zip a S3...
    echo ----------------------------------------
    aws s3 cp "..\..\%%~nf.zip" "s3://lambda-artifacts-functions/%%~nf.zip"
    if !ERRORLEVEL! neq 0 (
        echo ----------------------------------------
        echo ❌ Error al subir %%~nf.zip a S3
        echo ----------------------------------------
        set "ERROR_OCCURRED=true"
        call :cleanup_temp_files
        goto end_script
    )
    
    echo ----------------------------------------
    echo Eliminando %%~nf.zip local...
    echo ----------------------------------------
    del "..\..\%%~nf.zip"
    if !ERRORLEVEL! neq 0 (
        echo ----------------------------------------
        echo ❌ Error al eliminar %%~nf.zip
        echo ----------------------------------------
        set "ERROR_OCCURRED=true"
        call :cleanup_temp_files
        goto end_script
    )
    
    echo ----------------------------------------
    echo %%f procesado exitosamente!
    echo ----------------------------------------
)

cd ..\..

echo ========================================
echo Todos los lambdas han sido procesados y subidos a S3!
echo ========================================

echo ========================================
echo Creando artefacto del template..
echo ========================================
aws cloudformation package --template-file devops-agent-infrastructure.yaml --s3-bucket template-artifacts-devops --output-template-file packaged-devops-agent-infrastructure.yaml
if %ERRORLEVEL% neq 0 goto error_handler

echo ----------------------------------------
echo artefacto creado..
echo ----------------------------------------
echo ========================================
echo desplegando a cloudformation
echo ========================================
aws cloudformation deploy --template-file packaged-devops-agent-infrastructure.yaml --stack-name bedrock-devops-stack --capabilities CAPABILITY_NAMED_IAM
if %ERRORLEVEL% neq 0 goto error_handler

del packaged-devops-agent-infrastructure.yaml
if %ERRORLEVEL% neq 0 goto error_handler

goto end_script

REM ========================================
REM FUNCIONES DEL SCRIPT
REM ========================================

REM Función para limpiar archivos temporales al inicio
:initial_cleanup
echo ========================================
echo 🧹 LIMPIEZA INICIAL - Eliminando archivos temporales existentes
echo ========================================

REM Limpiar carpeta python si existe
if exist "lambda-layer\python" (
    echo Eliminando carpeta python existente...
    rmdir /S /Q "lambda-layer\python"
    echo ✅ Carpeta python eliminada.
) else (
    echo ℹ️ Carpeta python no existe - continuando...
)

REM Limpiar archivo zip del layer si existe
if exist "lambda-layer\my_dependencies_layer.zip" (
    echo Eliminando my_dependencies_layer.zip existente...
    del "lambda-layer\my_dependencies_layer.zip"
    echo ✅ my_dependencies_layer.zip eliminado.
) else (
    echo ℹ️ my_dependencies_layer.zip no existe - continuando...
)

REM Limpiar archivos zip de lambdas si existen
set "lambdas_cleaned=0"
for %%f in (src\functions\*.py) do (
    set "lambda_name=%%~nf"
    if exist "!lambda_name!.zip" (
        echo Eliminando !lambda_name!.zip existente...
        del "!lambda_name!.zip"
        echo ✅ !lambda_name!.zip eliminado.
        set /a "lambdas_cleaned+=1"
    )
)
if !lambdas_cleaned! gtr 0 (
    echo ✅ Se eliminaron !lambdas_cleaned! archivos zip de lambdas.
) else (
    echo ℹ️ No hay archivos zip de lambdas para eliminar.
)

REM Limpiar archivo YAML empaquetado si existe
if exist "packaged-devops-agent-infrastructure.yaml" (
    echo Eliminando packaged-devops-agent-infrastructure.yaml existente...
    del "packaged-devops-agent-infrastructure.yaml"
    echo ✅ packaged-devops-agent-infrastructure.yaml eliminado.
) else (
    echo ℹ️ packaged-devops-agent-infrastructure.yaml no existe - continuando...
)

echo ========================================
echo ✅ LIMPIEZA INICIAL COMPLETADA - Entorno limpio listo
echo ========================================
echo.
goto :eof

REM Función para limpiar archivos temporales
:cleanup_temp_files
echo ----------------------------------------
echo 🧹 Limpiando archivos temporales...
echo ----------------------------------------

REM Limpiar carpeta python si existe
if exist "lambda-layer\python" (
    echo Eliminando carpeta python...
    rmdir /S /Q "lambda-layer\python"
    echo Carpeta python eliminada.
)

REM Limpiar archivo zip del layer si existe
if exist "lambda-layer\my_dependencies_layer.zip" (
    echo Eliminando my_dependencies_layer.zip...
    del "lambda-layer\my_dependencies_layer.zip"
    echo my_dependencies_layer.zip eliminado.
)

REM Limpiar archivos zip de lambdas si existen
for %%f in (src\functions\*.py) do (
    set "lambda_name=%%~nf"
    if exist "!lambda_name!.zip" (
        echo Eliminando !lambda_name!.zip...
        del "!lambda_name!.zip"
        echo !lambda_name!.zip eliminado.
    )
)

REM Limpiar archivo YAML empaquetado si existe
if exist "packaged-devops-agent-infrastructure.yaml" (
    echo Eliminando packaged-devops-agent-infrastructure.yaml...
    del "packaged-devops-agent-infrastructure.yaml"
    echo packaged-devops-agent-infrastructure.yaml eliminado.
)

echo ----------------------------------------
echo ✅ Limpieza de archivos temporales completada
echo ----------------------------------------
goto :eof

REM Función para manejar errores
:error_handler
if %ERRORLEVEL% neq 0 (
    echo.
    echo ----------------------------------------
    echo ❌ ERROR: Comando falló con código de salida %ERRORLEVEL%
    echo ----------------------------------------
    echo.
    
    REM Marcar que hubo un error
    set "ERROR_OCCURRED=true"
    
    REM Limpiar archivos temporales antes de salir
    call :cleanup_temp_files
    
    goto end_script
)

:end_script
echo.
echo ========================================
if "%ERROR_OCCURRED%"=="true" (
    echo ❌ DEPLOY COMPLETADO CON ERRORES
    echo Revisa los mensajes de error arriba para identificar los problemas.
) else (
    echo ✅ DEPLOY COMPLETADO EXITOSAMENTE
    echo Todos los recursos han sido desplegados correctamente.
)
echo ========================================

echo.
echo ----------------------------------------
echo Presiona cualquier tecla para cerrar esta ventana...
echo ----------------------------------------
pause >nul