# Installs the Azure Resoure Manager if not installed
Install-Module -Name AzureRM -AllowClobber

# Enable Script Execution
$execPolicy = Get-ExecutionPolicy
if ($execPolicy -eq "Restricted"){
    Set-ExecutionPolicy RemoteSigned
}

# Import module
$module_Imported = Get-Module -Name AzureRM
if ($module_Imported.name -ne "AzureRM"){
    Import-Module AzureRM
}

# Get your available subscriptions
Get-AzureRmSubscription

# Connect to particular subcription
Connect-AzureRmAccount -Subscription "Your-Subscription-Name-Goes-Here"

# Get, Set, Verify Azure subscriptions
Get-AzureRmSubscription

Select-AzureRmSubscription -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # Comment for name of subscription1
Select-AzureRmSubscription -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # Comment for name of subscription2
Select-AzureRmSubscription -SubscriptionId xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx # Comment for name of subscription3

(Get-AzureRmContext).Subscription #Check which subscription is set as current default
