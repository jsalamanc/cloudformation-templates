import boto3
import cfnresponse
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth

def lambda_handler(event, context):
    print(event)
    try:
        if event['RequestType'] == 'Create':
            on_create(event, context)
        elif event['RequestType'] == 'Update':
            on_update(event, context)
        elif event['RequestType'] == 'Delete':
            on_delete(event, context)
    except Exception as e:
        cfnresponse.send(event, context, cfnresponse.FAILED, {}, str(e))

def on_create(event, context):
    properties = event['ResourceProperties']
    collection_endpoint = properties['CollectionEndpoint']
    index_name = properties['VectorIndexName']

    host = collection_endpoint.replace("https://", "").replace(":443", "")
    region = 'us-east-2' # Reemplaza con tu región si es diferente
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

    index_body = {
        "settings": {
            "index": {
                "knn": True,
                "knn.space_type": "l2"
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
        client.indices.create(index=index_name, body=index_body)
    
    cfnresponse.send(event, context, cfnresponse.SUCCESS, {'Message': 'Index created successfully'}, index_name)

def on_update(event, context):
    # Lógica para actualizar el índice. Para este caso, podemos no hacer nada.
    cfnresponse.send(event, context, cfnresponse.SUCCESS, {'Message': 'Update successful'}, event['PhysicalResourceId'])

def on_delete(event, context):
    # Lógica para eliminar el índice cuando el stack se elimina
    properties = event['ResourceProperties']
    collection_endpoint = properties['CollectionEndpoint']
    index_name = properties['VectorIndexName']
    
    host = collection_endpoint.replace("https://", "").replace(":443", "")
    region = 'us-east-2' # Reemplaza con tu región si es diferente
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
    
    if client.indices.exists(index=index_name):
        client.indices.delete(index=index_name)
    
    cfnresponse.send(event, context, cfnresponse.SUCCESS, {'Message': 'Index deleted successfully'}, event['PhysicalResourceId'])