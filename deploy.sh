#!/bin/bash

# Configurar manejo de errores
set -e

# Variable para rastrear si hubo errores
ERROR_OCCURRED=false

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Función para imprimir separadores
print_separator() {
    echo "----------------------------------------"
}

print_header() {
    echo "========================================"
}

# Función para manejar errores
error_handler() {
    local exit_code=$?
    print_message $RED "❌ ERROR: Comando falló con código de salida $exit_code"
    ERROR_OCCURRED=true
    cleanup_temp_files
    exit 1
}

# Configurar trap para capturar errores
trap 'error_handler' ERR

# Función para limpiar archivos temporales al inicio
initial_cleanup() {
    print_header
    print_message $BLUE "🧹 LIMPIEZA INICIAL - Eliminando archivos temporales existentes"
    print_header

    # Limpiar carpeta python si existe
    if [ -d "lambda-layer/python" ]; then
        print_message $YELLOW "Eliminando carpeta python existente..."
        rm -rf "lambda-layer/python"
        print_message $GREEN "✅ Carpeta python eliminada."
    else
        print_message $BLUE "ℹ️ Carpeta python no existe - continuando..."
    fi

    # Limpiar archivo zip del layer si existe
    if [ -f "lambda-layer/my_dependencies_layer.zip" ]; then
        print_message $YELLOW "Eliminando my_dependencies_layer.zip existente..."
        rm "lambda-layer/my_dependencies_layer.zip"
        print_message $GREEN "✅ my_dependencies_layer.zip eliminado."
    else
        print_message $BLUE "ℹ️ my_dependencies_layer.zip no existe - continuando..."
    fi

    # Limpiar archivos zip de lambdas si existen
    local lambdas_cleaned=0
    for lambda_file in src/functions/*.py; do
        if [ -f "$lambda_file" ]; then
            local lambda_name=$(basename "$lambda_file" .py)
            if [ -f "${lambda_name}.zip" ]; then
                print_message $YELLOW "Eliminando ${lambda_name}.zip existente..."
                rm "${lambda_name}.zip"
                print_message $GREEN "✅ ${lambda_name}.zip eliminado."
                ((lambdas_cleaned++))
            fi
        fi
    done

    if [ $lambdas_cleaned -gt 0 ]; then
        print_message $GREEN "✅ Se eliminaron $lambdas_cleaned archivos zip de lambdas."
    else
        print_message $BLUE "ℹ️ No hay archivos zip de lambdas para eliminar."
    fi

    # Limpiar archivo YAML empaquetado si existe
    if [ -f "packaged-devops-agent-infrastructure.yaml" ]; then
        print_message $YELLOW "Eliminando packaged-devops-agent-infrastructure.yaml existente..."
        rm "packaged-devops-agent-infrastructure.yaml"
        print_message $GREEN "✅ packaged-devops-agent-infrastructure.yaml eliminado."
    else
        print_message $BLUE "ℹ️ packaged-devops-agent-infrastructure.yaml no existe - continuando..."
    fi

    print_header
    print_message $GREEN "✅ LIMPIEZA INICIAL COMPLETADA - Entorno limpio listo"
    print_header
    echo
}

# Función para limpiar archivos temporales
cleanup_temp_files() {
    print_separator
    print_message $BLUE "🧹 Limpiando archivos temporales..."
    print_separator

    # Limpiar carpeta python si existe
    if [ -d "lambda-layer/python" ]; then
        print_message $YELLOW "Eliminando carpeta python..."
        rm -rf "lambda-layer/python"
        print_message $BLUE "Carpeta python eliminada."
    fi

    # Limpiar archivo zip del layer si existe
    if [ -f "lambda-layer/my_dependencies_layer.zip" ]; then
        print_message $YELLOW "Eliminando my_dependencies_layer.zip..."
        rm "lambda-layer/my_dependencies_layer.zip"
        print_message $BLUE "my_dependencies_layer.zip eliminado."
    fi

    # Limpiar archivos zip de lambdas si existen
    for lambda_file in src/functions/*.py; do
        if [ -f "$lambda_file" ]; then
            local lambda_name=$(basename "$lambda_file" .py)
            if [ -f "${lambda_name}.zip" ]; then
                print_message $YELLOW "Eliminando ${lambda_name}.zip..."
                rm "${lambda_name}.zip"
                print_message $BLUE "${lambda_name}.zip eliminado."
            fi
        fi
    done

    # Limpiar archivo YAML empaquetado si existe
    if [ -f "packaged-devops-agent-infrastructure.yaml" ]; then
        print_message $YELLOW "Eliminando packaged-devops-agent-infrastructure.yaml..."
        rm "packaged-devops-agent-infrastructure.yaml"
        print_message $BLUE "packaged-devops-agent-infrastructure.yaml eliminado."
    fi

    print_separator
    print_message $GREEN "✅ Limpieza de archivos temporales completada"
    print_separator
}

# Función principal
main() {
    # Ejecutar limpieza inicial al comenzar
    initial_cleanup

    cd lambda-layer

    print_separator
    print_message $BLUE "creando carpeta python..."
    print_separator
    mkdir -p python

    print_separator
    print_message $BLUE "instalando opensearch-py..."
    print_separator
    pip install opensearch-py boto3 -t python/
    print_separator
    print_message $GREEN "opensearch-py instalado..."
    print_separator

    print_separator
    print_message $BLUE "instalando cfnresponse..."
    print_separator
    pip install cfnresponse -t python/
    print_separator
    print_message $GREEN "cfnresponse instalado..."
    print_separator

    print_separator
    print_message $BLUE "Empaquetando layers..."
    print_separator
    zip -r my_dependencies_layer.zip python/
    if [ $? -ne 0 ]; then
        print_message $RED "❌ Error al empaquetar el layer"
        exit 1
    fi

    print_separator
    print_message $BLUE "Subiendo layers a s3..."
    print_separator
    aws s3 cp my_dependencies_layer.zip s3://layer-artifacts-lambdas/
    if [ $? -ne 0 ]; then
        print_message $RED "❌ Error al subir el layer a S3"
        exit 1
    fi

    print_separator
    print_message $GREEN "layers subidos.."
    print_separator
    
    print_message $BLUE "eliminando carpeta python..."
    rm -rf python/
    print_separator
    print_message $GREEN "carpeta python eliminada."
    print_separator

    print_message $BLUE "eliminando my_dependencies_layer.zip..."
    rm my_dependencies_layer.zip
    print_separator
    print_message $GREEN "my_dependencies_layer.zip eliminado."
    print_separator

    print_header
    print_message $BLUE "Empaquetando codigo Lambda..."
    print_header

    # Recorrer la carpeta functions y comprimir cada lambda individualmente
    cd ../src/functions

    # Obtener la lista de archivos .py en la carpeta functions
    for lambda_file in *.py; do
        if [ -f "$lambda_file" ]; then
            local lambda_name=$(basename "$lambda_file" .py)
            
            print_separator
            print_message $BLUE "Comprimiendo $lambda_file..."
            print_separator
            
            zip -j "../../${lambda_name}.zip" "$lambda_file"
            if [ $? -ne 0 ]; then
                print_separator
                print_message $RED "❌ Error al comprimir $lambda_file"
                print_separator
                ERROR_OCCURRED=true
                cleanup_temp_files
                exit 1
            fi
            
            print_separator
            print_message $BLUE "Subiendo ${lambda_name}.zip a S3..."
            print_separator
            aws s3 cp "../../${lambda_name}.zip" "s3://lambda-artifacts-functions/${lambda_name}.zip"
            if [ $? -ne 0 ]; then
                print_separator
                print_message $RED "❌ Error al subir ${lambda_name}.zip a S3"
                print_separator
                ERROR_OCCURRED=true
                cleanup_temp_files
                exit 1
            fi
            
            print_separator
            print_message $BLUE "Eliminando ${lambda_name}.zip local..."
            print_separator
            rm "../../${lambda_name}.zip"
            if [ $? -ne 0 ]; then
                print_separator
                print_message $RED "❌ Error al eliminar ${lambda_name}.zip"
                print_separator
                ERROR_OCCURRED=true
                cleanup_temp_files
                exit 1
            fi
            
            print_separator
            print_message $GREEN "$lambda_file procesado exitosamente!"
            print_separator
        fi
    done

    cd ../..

    print_header
    print_message $GREEN "Todos los lambdas han sido procesados y subidos a S3!"
    print_header

    print_header
    print_message $BLUE "Creando artefacto del template.."
    print_header
    aws cloudformation package --template-file devops-agent-infrastructure.yaml --s3-bucket template-artifacts-devops --output-template-file packaged-devops-agent-infrastructure.yaml
    if [ $? -ne 0 ]; then
        print_message $RED "❌ Error al crear el artefacto del template"
        exit 1
    fi

    print_separator
    print_message $GREEN "artefacto creado.."
    print_separator
    
    print_header
    print_message $BLUE "desplegando a cloudformation"
    print_header
    aws cloudformation deploy --template-file packaged-devops-agent-infrastructure.yaml --stack-name bedrock-devops-stack --capabilities CAPABILITY_NAMED_IAM
    if [ $? -ne 0 ]; then
        print_message $RED "❌ Error al desplegar a CloudFormation"
        exit 1
    fi

    rm packaged-devops-agent-infrastructure.yaml
    if [ $? -ne 0 ]; then
        print_message $RED "❌ Error al eliminar el template empaquetado"
        exit 1
    fi

    # Éxito
    print_message $GREEN "✅ DEPLOY COMPLETADO EXITOSAMENTE"
    print_message $GREEN "Todos los recursos han sido desplegados correctamente."
}

# Ejecutar función principal
main "$@"
