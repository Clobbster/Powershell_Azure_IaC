########################################################################################################################
# This script is meant to be used as a guide or template for everything required to launch VMs in the Azure Cloud Space.
# This particular script will create the following:
#
# 1. A Resource Group(RG). 
# 2. A Virtual Network with 4 subnets
# 3. An Azure Network Security Group. Only two rules have been defined for the first subnet.
# 4. A Storage account that the VMs will utilize
# 5. The required NICs for the VMs
# 6. Four VMs 
#
########################################################################################################################


# Set the Subscription that you want to deploy to
$subscription = "Put-Your-Subscription-Here"

Set-AzureRmContext -Subscription $subscription

###########################################################
# RESOURCE GROUPS
###########################################################
$rgName   = "CRRG-PS-Test"
$location = "SouthCentralUS"

New-AzureRmResourceGroup -Name $rgName -Location $location


###########################################################
# VIRTUAL NETWORKS AND SUBNETS
###########################################################
$vnetName    = "CRVN-PS-Test"
$subnet1Name = "Subnet1"
$subnet2Name = "Subnet2"
$subnet3Name = "Subnet3"
$subnet4Name = "Subnet4"

$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix "10.1.0.0/25"
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix "10.1.0.128/25"
$subnet3 = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet3Name -AddressPrefix "10.1.1.0/25"
$subnet4 = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet4Name -AddressPrefix "10.1.1.128/25"

New-AzureRmVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $rgName `
    -Location $location `
    -AddressPrefix "10.1.0.0/23" `
    -Subnet $subnet1,$subnet2,$subnet3,$subnet4


###########################################################
# NETWORK SECURITY GROUPS
###########################################################
$nsgName = "CRNSG-PS-Test"

# NSG Subnet 1
###########################################################
# Create an NSG rule to allow HTTP traffic in from the Internet to Subnet1.
$subnet1NSGrule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Create an NSG rule to allow RDP traffic from the Internet to Subnet1.
$Subnet1NSGrule2 = New-AzureRmNetwork
rotocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group for the Subnet1.
$subnet1NSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
  -Name $nsgName -SecurityRules $subnet1NSGrule1,`
                                $Subnet1NSGrule2

# NSG Subnet 2
###########################################################

# NSG Subnet 3
###########################################################

# NSG Subnet 4
###########################################################


###########################################################
# STORAGE ACCOUNT
###########################################################
$storageAcctName= ”crstoretestps”
$storageAcctType= “Standard_LRS”

$storageAcct = New-AzureRmStorageAccount -Name $storageAcctName -ResourceGroupName $rgName –Type $storageAcctType -Location $location


###########################################################
# NICs
###########################################################
$nicCounterVar    = 1
$desiredNICCount  = 4 
$fixedNICList     = @() # Fixed list due to Powershell code limitation regarding appending fixed lists. Actuall list is $nicList

# Iteration of a count for unique naming per env
while($nicCounterVar -ne $desiredNICCount + 1){
    $nicList = $fixedNICList += "CRVM-NIC"+$nicCounterVar
    $nicCounterVar += 1
}

$nicList # Add forEach loop here to print to the user what is being created. For nic in list, creating nic.
$nic1Name = $nicList[0]
$nic2Name = $nicList[1]
$nic3Name = $nicList[2]
$nic4Name = $nicList[3]

# NIC1
$IP1config = New-AzureRmNetworkInterfaceIpConfig -Name "IPConfig1" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "10.1.0.10" -SubnetId "/subscriptions/68cf210d-efb0-4615-8b0f-20ae6c9ff0c3/resourceGroups/CRRG-PS-Test/providers/Microsoft.Network/virtualNetworks/CRVN-PS-Test/subnets/Subnet1"
$nic1 = New-AzureRmNetworkInterface -Name $nic1Name -ResourceGroupName $rgName -Location $location -IpConfiguration $IP1config

# NIC2
$IP2config = New-AzureRmNetworkInterfaceIpConfig -Name "IPConfig2" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "10.1.0.138" -SubnetId "/subscriptions/68cf210d-efb0-4615-8b0f-20ae6c9ff0c3/resourceGroups/CRRG-PS-Test/providers/Microsoft.Network/virtualNetworks/CRVN-PS-Test/subnets/Subnet2"
$nic2 = New-AzureRmNetworkInterface -Name $nic2Name -ResourceGroupName $rgName -Location $location -IpConfiguration $IP2config

# NIC3
$IP3config = New-AzureRmNetworkInterfaceIpConfig -Name "IPConfig3" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "10.1.1.10" -SubnetId "/subscriptions/68cf210d-efb0-4615-8b0f-20ae6c9ff0c3/resourceGroups/CRRG-PS-Test/providers/Microsoft.Network/virtualNetworks/CRVN-PS-Test/subnets/Subnet3"
$nic3 = New-AzureRmNetworkInterface -Name $nic3Name -ResourceGroupName $rgName -Location $location -IpConfiguration $IP3config

# NIC4
$IP4config = New-AzureRmNetworkInterfaceIpConfig -Name "IPConfig4" -PrivateIpAddressVersion IPv4 -PrivateIpAddress "10.1.1.138" -SubnetId "/subscriptions/68cf210d-efb0-4615-8b0f-20ae6c9ff0c3/resourceGroups/CRRG-PS-Test/providers/Microsoft.Network/virtualNetworks/CRVN-PS-Test/subnets/Subnet4"
$nic4 = New-AzureRmNetworkInterface -Name $nic4Name -ResourceGroupName $rgName -Location $location -IpConfiguration $IP4config

###########################################################
# VIRTUAL MACHINES
###########################################################
$publisherName = "MicrosoftWindowsServer"
$offerName     = "WindowsServer"
$skuName       = "2016-Datacenter"
$vmSize        = "Standard_D2_v2"
$cred          = Get-Credential -Message "Type the name and password for the local admin account"
$counterVar    = 1
$desiredCount  = 4 
$fixedList     = @() # Fixed list due to Powershell code limitation regarding appending fixed lists. Actuall list is $vmList

# Iteration of a count for unique naming per VM
while($counterVar -ne $desiredCount + 1){
    $vmList   = $fixedList += "CRVM-Test-PS"+$counterVar
    $counterVar += 1
}

$vm1Name = $vmList[0]
$vm2Name = $vmList[1]
$vm3Name = $vmList[2]
$vm4Name = $vmList[3] 


# VM 1
#######################################################
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$vm1Config = New-AzureRmVMConfig -VMName $vm1Name -VMSize $vmSize
$vm1Config = Set-AzureRmVMOperatingSystem -VM $vm1Config -Windows -ComputerName $vm1Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm1Config = Set-AzureRmVMSourceImage -VM $vm1Config -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version "latest"
$vm1Config = Add-AzureRmVMNetworkInterface -VM $vm1Config -Id $nic1.Id

# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm1Config -Verbose


# VM 2
#######################################################
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$vm2Config = New-AzureRMVMConfig -VMName $vm2Name -VMSize $vmSize
$vm2Config = Set-AzureRmVMOperatingSystem -VM $vm2Config -Windows -ComputerName $vm2Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm2Config = Set-AzureRmVMSourceImage -VM $vm2Config -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version "latest"
$vm2Config = Add-AzureRmVMNetworkInterface -VM $vm2Config -Id $nic2.Id


# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm2Config -Verbose

# VM 3
#######################################################
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$vm3Config = New-AzureRMVMConfig -VMName $vm3Name -VMSize $vmSize
$vm3Config = Set-AzureRmVMOperatingSystem -VM $vm3Config -Windows -ComputerName $vm3Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm3Config = Set-AzureRmVMSourceImage -VM $vm3Config -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version "latest"
$vm3Config = Add-AzureRmVMNetworkInterface -VM $vm3Config -Id $nic3.Id


# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm3Config -Verbose


# VM 4
#######################################################
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$vm4Config = New-AzureRMVMConfig -VMName $vm4Name -VMSize $vmSize
$vm4Config = Set-AzureRmVMOperatingSystem -VM $vm4Config -Windows -ComputerName $vm4Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm4Config = Set-AzureRmVMSourceImage -VM $vm4Config -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version "latest"
$vm4Config = Add-AzureRmVMNetworkInterface -VM $vm4Config -Id $nic4.Id


# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm4Config -Verbose