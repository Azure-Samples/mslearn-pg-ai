REGION=eastus
RG_NAME=rg-learn-postgresql-ai-$REGION
ADMIN_PASSWORD=Pa$$w0rd

az account set --subscription <subscriptionName|subscriptionId>
az group create --name $RG_NAME --location $REGION

az deployment group create --resource-group $RG_NAME --template-file "deploy.bicep" --parameters restore=false adminLogin=pgAdmin adminLoginPassword=$ADMIN_PASSWORD