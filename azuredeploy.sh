#!/bin/bash

# login to customer account
az login

# Select subscription name or ID
SUBSCRIPTION="Visual Studio Professional"

az account set -s $SUBSCRIPTION

# all contents of source container will be copied
# destination container, destination account name, destination account key
DESTCONT="vhds"
ACCNAME="temporarystorageforvhds"
ACCKEY=""

# source account key, source account name, source container
SRCACCKEY="source accout key"
SRCACCNAME="source account name"
SRCCONT="source container name"

LOCATION="westeurope"
RESGROUPNAME="mxv-resgroup"


# create resource group
echo "Creating resource group..."
az group create -l $LOCATION -n $RESGROUPNAME


# create storage account and container
echo "Creating temporary storage account for vhds..."
az storage account create -g $RESGROUPNAME -n $ACCNAME

ACCKEY="$(az storage account keys list -n $ACCNAME -g $RESGROUPNAME --query [].[value][1] -o tsv)"

az storage container create -n $DESTCONT --account-name $ACCNAME --account-key $ACCKEY


# start copy
echo "Start copy..."
az storage blob copy start-batch --destination-container $DESTCONT \
                                --account-name $ACCNAME \
                                --account-key $ACCKEY \
                                --source-account-key $SRCACCKEY \
                                --source-account-name $SRCACCNAME \
                                --source-container $SRCCONT

echo "Waiting for copy...Check if copy is over every 10 sec..."
echo "Start time: `date +%H:%M:%S`"
sleep 10

OSDISKNAME="$(az storage blob list --container-name $DESTCONT --account-key $ACCKEY --account-name $ACCNAME --query [].[name][0] -o tsv)"
DATADISK1NAME="$(az storage blob list --container-name $DESTCONT --account-key $ACCKEY --account-name $ACCNAME --query [].[name][1] -o tsv)"
DATADISK2NAME="$(az storage blob list --container-name $DESTCONT --account-key $ACCKEY --account-name $ACCNAME --query [].[name][2] -o tsv)"

while [ '"success"' != $(az storage blob show --account-name ${ACCNAME} --account-key ${ACCKEY} -c ${DESTCONT} -n ${OSDISKNAME} --query properties.copy.status) ]
do
sleep 10
done

while [ '"success"' != $(az storage blob show --account-name ${ACCNAME} --account-key ${ACCKEY} -c ${DESTCONT} -n ${DATADISK1NAME} --query properties.copy.status) ]
do
sleep 10
done

while [ '"success"' != $(az storage blob show --account-name ${ACCNAME} --account-key ${ACCKEY} -c ${DESTCONT} -n ${DATADISK2NAME} --query properties.copy.status) ]
do
sleep 10
done

echo "Finish time: `date +%H:%M:%S`"

# deploy VM
echo "Start deployment..."

OSDISK="https://"$ACCNAME".blob.core.windows.net/"$DESTCONT"/"$OSDISKNAME
DATADISK1="https://"$ACCNAME".blob.core.windows.net/"$DESTCONT"/"$DATADISK1NAME
DATADISK2="https://"$ACCNAME".blob.core.windows.net/"$DESTCONT"/"$DATADISK2NAME

az group deployment create \
    --name "ExampleDeployment" \
    --resource-group $RESGROUPNAME \
    --template-file template.json \
    --parameters \
                location=$LOCATION \
                vhdUrl=$OSDISK \
                dataDiskVhdUri1=$DATADISK1 \
                dataDiskVhdUri2=$DATADISK2 
echo "Finish deployment..."


# delete temprary storage
echo "Deleting storage account..."
az storage account delete -y -n $ACCNAME -g $RESGROUPNAME
echo "Deleted"