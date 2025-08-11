import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Función Lambda que se ejecuta cuando se crea un objeto en el bucket S3.
    """
    logger.info("S3 event triggered me!")
    logger.info("Event Data: %s", json.dumps(event, indent=2))

    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']
        logger.info(f"Nuevo objeto creado en el bucket '{bucket_name}': {object_key}")

    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }