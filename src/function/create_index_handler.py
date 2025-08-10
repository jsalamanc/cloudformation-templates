
import boto3
import cfnresponse
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
import json
import time
import random

def create_opensearch_client(collection_endpoint, region):
    """
    Crea y retorna un cliente de OpenSearch Serverless con autenticación SigV4.
    """
    try:
        host = collection_endpoint.replace("https://", "").split(':')[0]
        service = 'aoss'
        credentials = boto3.Session().get_credentials()
        auth = AWSV4SignerAuth(credentials, region, service)

        client = OpenSearch(
            hosts=[{'host': host, 'port': 443}],
            http_auth=auth,
            use_ssl=True,
            verify_certs=True,
            connection_class=RequestsHttpConnection,
            pool_maxsize=20
        )
        return client
    except Exception as e:
        print(f"Error al crear el cliente de OpenSearch: {e}")
        raise

def wait_for_opensearch_ready(client, max_attempts=20):
    """
    Espera a que el cliente de OpenSearch Serverless pueda hacer una llamada de API válida.
    """
    base_delay = 5
    max_delay = 120
    
    for attempt in range(max_attempts):
        try:
            print(f"Intento {attempt + 1}/{max_attempts}: Verificando conexión a OpenSearch Serverless...")
            # Usa una API válida para verificar la conexión, como listar índices
            # Esto debería retornar un 200 y una lista vacía si no hay índices,
            # pero no un 404 o un error de conexión si el servicio está listo.
            client.indices.get_alias() 
            print("¡Conectado exitosamente a OpenSearch Serverless!")
            return True
        except Exception as e:
            error_msg = str(e)
            print(f"Intento {attempt + 1} falló: {error_msg}")
            
            # Reintentar si el error es de conexión o indica que el servicio no está listo
            if any(keyword in error_msg.lower() for keyword in ["404", "notfounderror", "connection refused", "timeout", "unavailable", "service unavailable", "host is not available"]):
                if attempt < max_attempts - 1:
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    jitter = random.uniform(0.5, 1.5) * delay
                    actual_delay = delay + jitter
                    
                    print(f"OpenSearch no está listo. Esperando {actual_delay:.1f} segundos antes del siguiente intento...")
                    time.sleep(actual_delay)
                    continue
                else:
                    print(f"Máximo número de intentos alcanzado ({max_attempts}). OpenSearch no está listo.")
                    raise Exception(f"OpenSearch no está listo después de {max_attempts} intentos. Último error: {error_msg}")
            else:
                # Para otros errores, lanzar la excepción inmediatamente
                print(f"Error no relacionado con disponibilidad: {error_msg}")
                raise e
    
    return False

def lambda_handler(event, context):
    print(event)
    response_data = {'Message': 'Operación completada exitosamente.'}
    status = cfnresponse.SUCCESS

    try:
        properties = event['ResourceProperties']
        collection_endpoint = properties['CollectionEndpoint']
        index_name = properties['VectorIndexName']
        region = 'us-east-2' # Ajusta esto a tu región de AWS

        client = create_opensearch_client(collection_endpoint, region)

        if event['RequestType'] == 'Delete':
            # Lógica para la eliminación de la pila
            print(f"Procesando solicitud de eliminación para el índice {index_name}")
            if client.indices.exists(index=index_name):
                client.indices.delete(index=index_name)
                print(f"Índice {index_name} eliminado.")
            else:
                print(f"El índice {index_name} no existe, no se hace nada.")

        else: # 'Create' o 'Update'
            print(f"Procesando solicitud para crear/actualizar el índice {index_name}")
            
            # Esperar a que el endpoint esté listo
            if not wait_for_opensearch_ready(client):
                raise Exception("No se pudo conectar a OpenSearch Serverless")

            index_body = {
                "settings": {
                    "index": {
                        "knn": True
                    }
                },
                "mappings": {
                    "properties": {
                        "bedrock-knowledge-base-default-vector-devops": {
                            "type": "knn_vector",
                            "dimension": 1024,
                            "method": {
                                "engine": "faiss",
                                "name": "hnsw",
                                "parameters": {}
                            }
                        },
                        "AMAZON_BEDROCK_TEXT_CHUNK": {
                            "type": "text"
                        },
                        "AMAZON_BEDROCK_METADATA": {
                            "type": "text"
                        }
                    }
                }
            }
            
            if not client.indices.exists(index=index_name):
                print(f"Creando índice {index_name}...")
                client.indices.create(index=index_name, body=index_body)
                print(f"Índice {index_name} creado exitosamente.")
            else:
                print(f"El índice {index_name} ya existe. No se tomaron medidas.")
        response_data['VectorIndexName'] = index_name
    except Exception as e:
        print(f"Error durante el procesamiento: {str(e)}")
        response_data['Message'] = str(e)
        status = cfnresponse.FAILED

    cfnresponse.send(event, context, status, response_data, event.get('LogicalResourceId', ''))