@echo off



cd lambda-layer

echo creando carpeta python...
mkdir python

echo instalando opensearch-py...
pip install opensearch-py boto3 -t python/
echo opensearch-py instalado...

echo instalando cfnresponse...
pip install cfnresponse -t python/
echo cfnresponse instalado...
echo Esperando unos segundos porfavor...
timeout /t 20

echo Empaquetando layers...
powershell  Compress-Archive -Path ".\python" -DestinationPath ".\my_dependencies_layer.zip"

echo Subiendo layers a s3...
aws s3 cp my_dependencies_layer.zip s3://layer-artifacts-lambdas/

echo layers subidos..
echo eliminando carpeta python...
rmdir /S /Q ".\python"
echo carpeta python eliminada.

echo eliminando my_dependencies_layer.zip...
del my_dependencies_layer.zip
echo my_dependencies_layer.zip eliminando.





echo Empaquetando codigo Lambda...

REM Crear el archivo ZIP con el codigo Lambda
cd ..\src\function
powershell Compress-Archive -Path * -DestinationPath ..\..\function.zip -Force
cd ..\..

echo Subiendo a S3...
aws s3 cp function.zip s3://lambda-artifacts-functions/function.zip

echo Codigo Lambda subido exitosamente!
del function.zip





echo Creando artefacto del template..
aws cloudformation package --template-file template_ia.json --s3-bucket template-artifacts-devops --output-template-file packaged-template_ia.json

echo artefacto creado..
echo desplegando a cloudformation
aws cloudformation deploy --template-file packaged-template_ia.json --stack-name bedrock-devops-stack --capabilities CAPABILITY_NAMED_IAM