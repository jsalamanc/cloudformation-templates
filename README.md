# 🤖 Agente DevOps con AWS Bedrock y OpenSearch Serverless

## 📋 Descripción del Proyecto

Este proyecto implementa una infraestructura completa en AWS para un agente DevOps inteligente que utiliza **Amazon Bedrock** y **OpenSearch Serverless** para crear una base de conocimiento vectorial. El sistema permite sincronizar automáticamente documentos desde S3 y proporcionar respuestas inteligentes basadas en embeddings.

## 🏗️ Arquitectura del Sistema

### Componentes Principales

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   S3 Bucket     │───▶│  Lambda Trigger  │───▶│  OpenSearch         │
│   (Documentos)  │    │  (S3 Event)      │    │  Serverless         │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────────┐
                       │  Bedrock         │    │  Vector Index       │
                       │  Knowledge Base  │◄───│  (HNSW + FAISS)    │
                       └──────────────────┘    └─────────────────────┘
```

### Stack de Recursos AWS

1. **S3 Bucket** - Almacenamiento de documentos DevOps
2. **OpenSearch Serverless** - Base de datos vectorial
3. **Lambda Functions** - Procesamiento y sincronización
4. **Bedrock Knowledge Base** - Gestión de conocimiento
5. **IAM Roles** - Permisos y seguridad
6. **Lambda Layer** - Dependencias compartidas

## 🔄 Flujos del Sistema

### 1. Flujo de Despliegue
```
deploy.bat → Lambda Layer → S3 Upload → CloudFormation → Stack Creation
```

### 2. Flujo de Sincronización de Documentos
```
S3 Object Created → Lambda Trigger → OpenSearch Index → Bedrock KB Update
```

### 3. Flujo de Creación de Índice Vectorial
```
CloudFormation → Custom Resource → Lambda → OpenSearch Index Creation
```

## 📁 Estructura del Proyecto

```
cloudformation-templates/
├── .gitignore                          # Archivos a ignorar en Git
├── deploy.bat                          # Script de despliegue para Windows
├── deploy.sh                           # Script de despliegue para Linux/macOS
├── devops-agent-infrastructure.yaml    # Template principal de CloudFormation
├── lambda-layer/                       # Dependencias compartidas
└── src/
    └── functions/
        ├── create_index_handler.py     # Creador de índices vectoriales
        └── sync_s3_knowledge.py       # Sincronizador S3-OpenSearch
```

## 🚀 Funcionalidades

### ✅ Características Implementadas

- **Sincronización Automática**: Los documentos se procesan automáticamente al subirse a S3
- **Índice Vectorial**: Creación automática de índices con HNSW y FAISS
- **Base de Conocimiento**: Integración completa con Amazon Bedrock
- **Escalabilidad**: OpenSearch Serverless para manejo automático de recursos
- **Seguridad**: IAM roles específicos y encriptación AES256

### 🔧 Funciones Lambda

#### `create_index_handler.py`
- **Propósito**: Crear índices vectoriales en OpenSearch Serverless
- **Trigger**: CloudFormation Custom Resource
- **Funcionalidades**:
  - Conexión autenticada con SigV4
  - Reintentos inteligentes con backoff exponencial
  - Configuración de índices KNN con HNSW
  - Manejo de eventos Create/Update/Delete

#### `sync_s3_knowledge.py`
- **Propósito**: Sincronizar documentos S3 con la base de conocimiento
- **Trigger**: Eventos S3 ObjectCreated
- **Funcionalidades**:
  - Logging detallado de eventos
  - Procesamiento de metadatos S3
  - Preparación para integración con Bedrock

## ⚙️ Configuración

### Parámetros del Template

| Parámetro | Descripción | Valor por Defecto |
|-----------|-------------|-------------------|
| `ProjectName` | Nombre del proyecto | `devops-agent` |
| `Environment` | Ambiente de despliegue | `dev` |
| `EmbeddingModel` | Modelo de embeddings | `amazon.titan-embed-text-v2:0` |
| `LambdaArtifactBucketName` | Bucket para artefactos Lambda | `lambda-artifacts-functions` |

### Modelos de Embeddings Soportados

- `amazon.titan-embed-text-v1`
- `amazon.titan-embed-text-v2:0`
- `cohere.embed-english-v3`
- `cohere.embed-multilingual-v3`

## 🚀 Despliegue

### Prerrequisitos

1. **AWS CLI** configurado con credenciales apropiadas
2. **Python 3.11** instalado
3. **Buckets S3** preexistentes:
   - `lambda-artifacts-functions` (para código Lambda)
   - `layer-artifacts-lambdas` (para Lambda Layers)
   - `template-artifacts-devops` (para templates)

### **Scripts de Despliegue Disponibles**

- **Windows**: `deploy.bat` - Script batch nativo
- **Linux/macOS**: `deploy.sh` - Script bash con colores y manejo robusto de errores

> 💡 **Nota**: Ambos scripts implementan exactamente la misma lógica y flujo de despliegue.

### Proceso de Despliegue

#### **Windows**
```cmd
deploy.bat
```

#### **Linux/macOS**
```bash
chmod +x deploy.sh
./deploy.sh
```

#### **El script automatiza**:
- Instalación de dependencias Python
- Creación de Lambda Layers
- Empaquetado y subida de funciones Lambda
- Despliegue del stack de CloudFormation

### Verificación del Despliegue

```bash
aws cloudformation describe-stacks --stack-name bedrock-devops-stack
```

## 📊 Outputs del Stack

| Output | Descripción | Uso |
|--------|-------------|-----|
| `S3BucketName` | Nombre del bucket S3 | Referencia para aplicaciones |
| `VectorCollectionEndpoint` | Endpoint OpenSearch | Conexión desde aplicaciones |
| `BedrockKnowledgeBaseId` | ID de la base de conocimiento | Integración con Bedrock |
| `DevOpsAgentRoleArn` | ARN del rol del agente | Permisos para aplicaciones |

## 🔒 Seguridad

### Políticas de Acceso

- **Encriptación**: AES256 para S3 y OpenSearch
- **IAM Roles**: Principio de menor privilegio
- **Red**: Acceso público controlado para OpenSearch
- **Auditoría**: CloudTrail y CloudWatch Logs

### Permisos Específicos

- **S3**: GetObject, PutObject, DeleteObject, ListBucket
- **OpenSearch**: APIAccessAll para operaciones vectoriales
- **Bedrock**: InvokeModel, Retrieve, RetrieveAndGenerate

## 🧪 Testing y Monitoreo

### CloudWatch Logs

- **Lambda Functions**: Logs detallados de ejecución
- **OpenSearch**: Métricas de rendimiento y errores
- **S3**: Notificaciones de eventos

### Métricas Clave

- Latencia de respuesta Lambda
- Tiempo de procesamiento de documentos
- Uso de recursos OpenSearch
- Tasa de éxito de sincronización

## 🔄 Mantenimiento

### Actualizaciones

1. **Código Lambda**: Modificar archivos en `src/functions/`
2. **Dependencias**: Actualizar `lambda-layer/` y redeploy
3. **Infraestructura**: Modificar `devops-agent-infrastructure.yaml`

### Limpieza

```bash
# Eliminar stack completo
aws cloudformation delete-stack --stack-name bedrock-devops-stack

# Limpiar buckets S3
aws s3 rm s3://lambda-artifacts-functions/ --recursive
aws s3 rm s3://layer-artifacts-lambdas/ --recursive
```

## 🐛 Troubleshooting

### Problemas Comunes

1. **Error de permisos IAM**
   - Verificar roles y políticas
   - Comprobar credenciales AWS CLI

2. **Timeout en Lambda**
   - Aumentar timeout en template
   - Verificar conectividad OpenSearch

3. **Error de conexión OpenSearch**
   - Verificar políticas de red
   - Comprobar endpoint y autenticación

### Logs de Debug

```bash
# Ver logs de Lambda
aws logs tail /aws/lambda/devops-agent-dev-sync-knowledge --follow

# Ver logs de OpenSearch
aws logs describe-log-groups --log-group-name-prefix "/aws/opensearch"
```

## 📚 Recursos Adicionales

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [OpenSearch Serverless Guide](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/serverless.html)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [CloudFormation Custom Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html)

## 🤝 Contribución

1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit de cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

**Desarrollado con ❤️ para la comunidad DevOps**
