# 🐧 Guía de Despliegue para Linux y macOS

## 📋 Descripción

Este documento proporciona instrucciones específicas para usuarios de **Linux** y **macOS** sobre cómo desplegar el proyecto Agente DevOps usando el script `deploy.sh`.

## 🚀 Script de Despliegue

### Archivo: `deploy.sh`

El script `deploy.sh` es la versión Unix/Linux del `deploy.bat` de Windows, manteniendo exactamente la misma lógica y flujo de despliegue.

## ⚙️ Prerrequisitos

### 1. **Sistema Operativo**
- ✅ **Linux** (Ubuntu 18.04+, CentOS 7+, RHEL 7+)
- ✅ **macOS** (10.14+)
- ❌ **Windows** (usar `deploy.bat` en su lugar)

### 2. **Herramientas Requeridas**

#### **Python**
```bash
# Verificar versión de Python
python3 --version
# Debe ser Python 3.9+ (recomendado 3.11)

# Instalar Python si no está disponible
# Ubuntu/Debian:
sudo apt update && sudo apt install python3 python3-pip

# CentOS/RHEL:
sudo yum install python3 python3-pip

# macOS (con Homebrew):
brew install python3
```

#### **AWS CLI**
```bash
# Verificar instalación
aws --version

# Instalar AWS CLI si no está disponible
# Linux:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS:
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### **Zip/Unzip**
```bash
# Verificar instalación
zip --version
unzip --version

# Instalar si no está disponible
# Ubuntu/Debian:
sudo apt install zip unzip

# CentOS/RHEL:
sudo yum install zip unzip

# macOS:
brew install zip
```

### 3. **Configuración AWS**
```bash
# Configurar credenciales AWS
aws configure

# O usar variables de entorno
export AWS_ACCESS_KEY_ID="tu_access_key"
export AWS_SECRET_ACCESS_KEY="tu_secret_key"
export AWS_DEFAULT_REGION="tu_region"
```

## 🔧 Preparación del Script

### 1. **Hacer Ejecutable el Script**
```bash
# Navegar al directorio del proyecto
cd cloudformation-templates

# Hacer ejecutable el script
chmod +x deploy.sh

# Verificar permisos
ls -la deploy.sh
# Debe mostrar: -rwxr-xr-x
```

### 2. **Verificar Estructura del Proyecto**
```bash
# Verificar que la estructura sea correcta
tree -I '.git|__pycache__|*.pyc'
# O usar ls
ls -la
```

## 🚀 Ejecución del Despliegue

### **Opción 1: Ejecución Directa**
```bash
# Ejecutar el script
./deploy.sh
```

### **Opción 2: Ejecución con Bash Explícito**
```bash
# Si hay problemas con el shebang
bash deploy.sh
```

### **Opción 3: Ejecución con Logs Detallados**
```bash
# Ejecutar con logs detallados
bash -x deploy.sh

# O guardar logs en archivo
./deploy.sh 2>&1 | tee deploy.log
```

## 📊 Flujo del Script

### **Fases de Ejecución**

1. **🧹 Limpieza Inicial**
   - Elimina archivos temporales existentes
   - Prepara entorno limpio

2. **📦 Creación de Lambda Layer**
   - Instala dependencias Python (`opensearch-py`, `boto3`, `cfnresponse`)
   - Empaqueta en archivo ZIP
   - Sube a S3

3. **🔧 Empaquetado de Funciones Lambda**
   - Comprime cada función Python individualmente
   - Sube a S3
   - Limpia archivos temporales

4. **☁️ Despliegue CloudFormation**
   - Crea artefacto del template
   - Despliega stack en AWS
   - Limpia archivos temporales

## 🐛 Troubleshooting

### **Problemas Comunes**

#### **1. Error de Permisos**
```bash
# Error: Permission denied
chmod +x deploy.sh

# O ejecutar con sudo si es necesario
sudo ./deploy.sh
```

#### **2. Python no Encontrado**
```bash
# Verificar instalación de Python
which python3
python3 --version

# Crear alias si es necesario
alias python=python3
```

#### **3. AWS CLI no Configurado**
```bash
# Verificar configuración
aws sts get-caller-identity

# Configurar si es necesario
aws configure
```

#### **4. Error de Dependencias**
```bash
# Instalar dependencias del sistema
# Ubuntu/Debian:
sudo apt install python3-dev build-essential

# CentOS/RHEL:
sudo yum groupinstall "Development Tools"
sudo yum install python3-devel

# macOS:
xcode-select --install
```

#### **5. Error de Memoria (macOS)**
```bash
# Aumentar límite de memoria para pip
export PIP_NO_CACHE_DIR=off
pip3 install --no-cache-dir opensearch-py boto3 cfnresponse
```

### **Logs de Debug**

#### **Ver Logs en Tiempo Real**
```bash
# Ejecutar con debug
bash -x deploy.sh

# O seguir logs específicos
tail -f /var/log/syslog | grep deploy
```

#### **Verificar Estado de AWS**
```bash
# Verificar stacks de CloudFormation
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Verificar buckets S3
aws s3 ls s3://lambda-artifacts-functions/
aws s3 ls s3://layer-artifacts-lambdas/
```

## 🔄 Mantenimiento

### **Actualizar Dependencias**
```bash
# Actualizar pip
pip3 install --upgrade pip

# Actualizar AWS CLI
pip3 install --upgrade awscli

# O reinstalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update
```

### **Limpiar Archivos Temporales**
```bash
# Limpieza manual si es necesario
rm -rf lambda-layer/python/
rm -f lambda-layer/my_dependencies_layer.zip
rm -f *.zip
rm -f packaged-*.yaml
```

### **Verificar Estado del Stack**
```bash
# Ver estado del stack
aws cloudformation describe-stacks --stack-name bedrock-devops-stack

# Ver eventos del stack
aws cloudformation describe-stack-events --stack-name bedrock-devops-stack
```

## 📱 Diferencias con Windows

| Aspecto | Windows (deploy.bat) | Linux/macOS (deploy.sh) |
|---------|----------------------|-------------------------|
| **Compresión** | `powershell Compress-Archive` | `zip -r` |
| **Separadores de ruta** | `\` | `/` |
| **Comandos de limpieza** | `del`, `rmdir /S /Q` | `rm -rf` |
| **Manejo de errores** | `if %ERRORLEVEL%` | `if [ $? -ne 0 ]` |
| **Variables** | `%VARIABLE%` | `$VARIABLE` |
| **Colores** | No soportado | Soporte completo con ANSI |

## 🎯 Mejoras del Script Unix

### **Características Adicionales**

- ✅ **Colores ANSI** para mejor legibilidad
- ✅ **Manejo robusto de errores** con `trap`
- ✅ **Funciones modulares** para mejor mantenimiento
- ✅ **Validaciones de archivos** más robustas
- ✅ **Logs estructurados** con separadores visuales

### **Compatibilidad**

- ✅ **Bash 4.0+** (recomendado)
- ✅ **Zsh** (macOS Catalina+)
- ✅ **Dash** (Ubuntu)
- ✅ **Ksh** (RHEL/CentOS)

## 📚 Recursos Adicionales

- [Bash Scripting Tutorial](https://www.gnu.org/software/bash/manual/bash.html)
- [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Python Installation Guide](https://docs.python.org/3/using/unix.html)
- [CloudFormation Best Practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html)

---

**¡Ahora puedes desplegar tu proyecto Agente DevOps en cualquier sistema Unix! 🚀**
