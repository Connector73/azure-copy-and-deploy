# Description
This script copies MXV vhds from different account to logged in account.


# What it does

Copies source vhds to temporary storage.  
Deploys MX-Virtual based on template file.  
Deletes temporary storage.

# Using

Before starting script change these to source vhd values:

SRCACCKEY="source accout key"  
SRCACCNAME="source account name"  
SRCCONT="source container name"

Select correct subscription.  
In addition you can change location, resourse group name and deployment name.
# Requirements
Azure CLI 2.0