########################################################################################################################
# 
# This script is meant to be used for the "" resource group
# This particular script will create the following:
#
# 1. A Resource Group(RG). 
# 2. A Storage account that the VMs will utilize
# 3. The Network Security Group to be applied to the subnet
# 4. A Load balancer with requisite rules
# 5. The required Subnet
# 6. The required NICs for the VMs
# 7. VMs 
#      4 servers
# 8. VM Disk Extensions
#
########################################################################################################################


# Set the Subscription that you want to deploy to
$subscription = "Your-Subscription-Here"

Set-AzureRmContext -Subscription $subscription

###########################################################
# RESOURCE GROUPS
###########################################################
$rgName   = "Your-RG-Here"
$location = "Where-You-Want-To-Deploy" #IE SouthCentralUS

New-AzureRmResourceGroup -Name $rgName -Location $location

###########################################################
# STORAGE ACCOUNT
###########################################################
$storageAcctName= ”Your-Storage-Acct-Here”
$storageAcctType= “Standard_LRS”

$storageAcct = New-AzureRmStorageAccount -Name $storageAcctName -ResourceGroupName $rgName –Type $storageAcctType -Location $location

###########################################################
# NETWORK SECURITY GROUPS
###########################################################
$nsgName = "NSG-Name-Here"

# Create NSG Rules
$rule1 = New-AzureRmNetworkSecurityRuleConfig `
    -Name 'TestEnvRDP' `
    -Description 'Allow RDP' `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389

$rule2 = New-AzureRmNetworkSecurityRuleConfig `
    -Name 'TestEnvHTTP' `
    -Description 'Allow HTTP' `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80

# Create NSG
$nsg = New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName $rgName `
    -Location $location `
    -Name $nsgName `
    -SecurityRules $rule1,$rule2


###########################################################
# VIRTUAL NETWORKS AND SUBNETS
###########################################################

# This will add a subnet to a pre-existing VNET
$vnetName    = Get-AzureRmVirtualNetwork -Name "VNET-Name-Here" -ResourceGroupName "VNET-RG-Here"
$subnet1Name = "New-Subnet-Name-Here" # This subnet's supernet is x.x.x.x/x 

$subnet1 = Add-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix "x.x.x.x/x" -VirtualNetwork $vnetName -NetworkSecurityGroup $nsg | Set-AzureRmVirtualNetwork

###########################################################
# LOAD BALANCER
###########################################################
$pipName             = "Public-IP-Name-Here"
$lbName              = "LoadBalancer-Name-Here"
$availabilitySetName = "AVSet-Name-Here"

# Create availability set for the VMs that will utilize this LB: This is REQUIRED!
$availabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $availabilitySetName -Location $location -Sku "Aligned" -PlatformFaultDomainCount 3

# Create a public IP
$pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $rgName `
    -Location $location `
    -AllocationMethod "Static" `
    -Name $pipName

# Create the config for the LB Ingress
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig `
    -Name "EnvFrontEndIP" `
    -PublicIpAddress $pip

# Create the LB Backend Address Pool
$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "EnvBackendPool"

# Create the health probe to monitor the status of responsive/non-responsive VMs
$probe = New-AzureRmLoadBalancerProbeConfig `
    -Name "Health-Probe" `
    -Protocol tcp `
    -Port 80 `
    -IntervalInSeconds 16 `
    -ProbeCount 2

# Create the LB rule to distribute load to VMs
$lbRule = New-AzureRmLoadBalancerRuleConfig `
    -Name "EnvLoadBalancerRule1" `
    -FrontendIpConfiguration $frontendIP `
    -BackendAddressPool $backendPool `
    -Protocol Tcp `
    -FrontendPort 80 `
    -BackendPort 80 `
    -Probe $probe

# Create NAT rules
$natrule1 = New-AzureRmLoadBalancerInboundNatRuleConfig `
    -Name 'EnvLoadBalancerRDP1' `
    -FrontendIpConfiguration $frontendIP `
    -Protocol tcp `
    -FrontendPort 4221 `
    -BackendPort 3389

$natrule2 = New-AzureRmLoadBalancerInboundNatRuleConfig `
    -Name 'EnvLoadBalancerRDP2' `
    -FrontendIpConfiguration $frontendIP `
    -Protocol tcp `
    -FrontendPort 4222 `
    -BackendPort 3389

# Create LB
$lb = New-AzureRmLoadBalancer `
  -ResourceGroupName $rgName `
  -Name $lbName `
  -Location $location `
  -FrontendIpConfiguration $frontendIP `
  -BackendAddressPool $backendPool `
  -Probe $probe `
  -LoadBalancingRule $lbrule `
  -InboundNatRule $natrule1,$natrule2

###########################################################
# NICs
###########################################################
$ip1config = New-AzureRmNetworkInterfaceIpConfig `
    -Name "IPConfigEnv" -PrivateIpAddressVersion IPv4 `
    -SubnetId "Your-Subscription-Id-Here" `
    -LoadBalancerBackendAddressPoolId $backendPool.Id

# NIC name generator function: This function will return an array of names according to the count variable
function NIC-Name-Generator {

    param(

        [int]$desiredNICCount,
        [string]$nicName
    )

    if ($nicList) {
        Remove-Variable $nicList # This ensures a clean list on each use
    }

    $nicCounterVar = 1
    $fixedNICList  = @() # Fixed list due to Powershell code limitation regarding appending fixed lists. Actual list is $nicList

   

    # Iteration of a count for unique naming per env
    while($nicCounterVar -ne $desiredNICCount + 1){
        $nicList = $fixedNICList += $nicName+$nicCounterVar
        $nicCounterVar += 1
    }

    return $nicList
}


# SC Server NICs
###########################################################
$scOutputArrayFromFunction = NIC-Name-Generator -desiredNICCount 4 -nicName "Env-NIC"

$scNIC1Name = $scOutputArrayFromFunction[0]
$scNIC2Name = $scOutputArrayFromFunction[1]
$scNIC3Name = $scOutputArrayFromFunction[2]
$scNIC4Name = $scOutputArrayFromFunction[3]

# SC NICs
$scNIC1 = New-AzureRmNetworkInterface -Name $scNIC1Name -ResourceGroupName $rgName -Location $location -IpConfiguration $ip1config  
$scNIC2 = New-AzureRmNetworkInterface -Name $scNIC2Name -ResourceGroupName $rgName -Location $location -IpConfiguration $ip1config
$scNIC3 = New-AzureRmNetworkInterface -Name $scNIC3Name -ResourceGroupName $rgName -Location $location -IpConfiguration $ip1config
$scNIC4 = New-AzureRmNetworkInterface -Name $scNIC4Name -ResourceGroupName $rgName -Location $location -IpConfiguration $ip1config

###########################################################
# VIRTUAL MACHINES
###########################################################

# WINDOWS VMs FOLLOWING
#######################################################
$windowsPublisherName = "MicrosoftWindowsServer"
$windowsOfferName     = "WindowsServer"
$windowsSKUName       = "2016-Datacenter"
$windowsVMSize        = "Standard_D2_v2"
$scCred               = Get-Credential -Message "Type the name and password for the local admin account"

# VM name generator function: This function will return an array of names according to the count variable
function VM-Name-Generator {

    param(
    
        [int]$desiredVMCount,
        [string]$vmName
    )

    if ($vmList) {
        Remove-Variable $vmList # This ensures a clean list on each use
    }

    $vmCounterVar = 1
    $fixedVMList  = @() # Fixed list due to Powershell code limitation regarding appending fixed lists. Actual list is $vmList

    
    # Iteration of a count for unique naming per env
    while($vmCounterVar -ne $desiredVMCount + 1){
        $vmList = $fixedVMList += $vmName+$vmCounterVar
        $vmCounterVar += 1
    }

    return $vmList

}

# SC VMs
#######################################################

# Invoking VM naming function
$scvmOutputArrayFromFunction = VM-Name-Generator -desiredVMCount 4 -vmName "Env-Server-"

$scVM1Name = $scvmOutputArrayFromFunction[0]
$scVM2Name = $scvmOutputArrayFromFunction[1]
$scVM3Name = $scvmOutputArrayFromFunction[2]
$scVM4Name = $scvmOutputArrayFromFunction[3]

# SC VM 1
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$scVM1Config = New-AzureRmVMConfig -VMName $scVM1Name -VMSize $windowsVMSize -AvailabilitySetId $availabilitySet.Id
$scVM1Config = Set-AzureRmVMOperatingSystem -VM $scVM1Config -Windows -ComputerName $scVM1Name -Credential $scCred
$scVM1Config = Set-AzureRmVMSourceImage -VM $scVM1Config -PublisherName $windowsPublisherName -Offer $windowsOfferName -Skus $windowsSKUName -Version "latest"
$scVM1Config = Add-AzureRmVMNetworkInterface -VM $scVM1Config -Id $scNIC1.Id

# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $scVM1Config -Verbose

# SC VM 2
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$scVM2Config = New-AzureRmVMConfig -VMName $scVM2Name -VMSize $windowsVMSize -AvailabilitySetId $availabilitySet.Id
$scVM2Config = Set-AzureRmVMOperatingSystem -VM $scVM2Config -Windows -ComputerName $scVM2Name -Credential $scCred
$scVM2Config = Set-AzureRmVMSourceImage -VM $scVM2Config -PublisherName $windowsPublisherName -Offer $windowsOfferName -Skus $windowsSKUName -Version "latest"
$scVM2Config = Add-AzureRmVMNetworkInterface -VM $scVM2Config -Id $scNIC2.Id

# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $scVM2Config -Verbose

# SC VM 3
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$scVM3Config = New-AzureRmVMConfig -VMName $scVM3Name -VMSize $windowsVMSize -AvailabilitySetId $availabilitySet.Id
$scVM3Config = Set-AzureRmVMOperatingSystem -VM $scVM3Config -Windows -ComputerName $scVM3Name -Credential $scCred
$scVM3Config = Set-AzureRmVMSourceImage -VM $scVM3Config -PublisherName $windowsPublisherName -Offer $windowsOfferName -Skus $windowsSKUName -Version "latest"
$scVM3Config = Add-AzureRmVMNetworkInterface -VM $scVM3Config -Id $scNIC3.Id

# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $scVM3Config -Verbose

# SC VM 4
# This block of code is creating the configs for the VM by 'ADDING' each subsequent line to $vmXConfig the variable
$scVM4Config = New-AzureRmVMConfig -VMName $scVM4Name -VMSize $windowsVMSize -AvailabilitySetId $availabilitySet.Id
$scVM4Config = Set-AzureRmVMOperatingSystem -VM $scVM4Config -Windows -ComputerName $scVM4Name -Credential $scCred
$scVM4Config = Set-AzureRmVMSourceImage -VM $scVM4Config -PublisherName $windowsPublisherName -Offer $windowsOfferName -Skus $windowsSKUName -Version "latest"
$scVM4Config = Add-AzureRmVMNetworkInterface -VM $scVM4Config -Id $scNIC4.Id

# Create the virtual machine
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $scVM4Config -Verbose

###########################################################
# DISK EXTENSIONS
###########################################################
$storageType  = 'Standard_LRS'
$dataDisk1Name = $scVM1Name + '_datadisk1'
$dataDisk2Name = $scVM2Name + '_datadisk1'
$dataDisk3Name = $scVM3Name + '_datadisk1'
$dataDisk4Name = $scVM4Name + '_datadisk1'
$diskConfig = New-AzureRmDiskConfig -SkuName $storageType -Location $location -CreateOption Empty -DiskSizeGB 100

# SC VM 1 Disk Extension
#######################################################
$dataDisk1  = New-AzureRmDisk -DiskName $dataDisk1Name -Disk $diskConfig -ResourceGroupName $rgName

$vm1 = Get-AzureRmVM -Name $scVM1Name -ResourceGroupName $rgName 
$vm1 = Add-AzureRmVMDataDisk -VM $vm1 -Name $dataDisk1Name -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1

Update-AzureRmVM -VM $vm1 -ResourceGroupName $rgName

# SC VM 2 Disk Extension
#######################################################
$dataDisk2  = New-AzureRmDisk -DiskName $dataDisk2Name -Disk $diskConfig -ResourceGroupName $rgName

$vm2 = Get-AzureRmVM -Name $scVM2Name -ResourceGroupName $rgName 
$vm2 = Add-AzureRmVMDataDisk -VM $vm2 -Name $dataDisk2Name -CreateOption Attach -ManagedDiskId $dataDisk2.Id -Lun 1

Update-AzureRmVM -VM $vm2 -ResourceGroupName $rgName

# SC VM 3 Disk Extension
#######################################################
$dataDisk3  = New-AzureRmDisk -DiskName $dataDisk3Name -Disk $diskConfig -ResourceGroupName $rgName

$vm3 = Get-AzureRmVM -Name $scVM3Name -ResourceGroupName $rgName 
$vm3 = Add-AzureRmVMDataDisk -VM $vm3 -Name $dataDisk3Name -CreateOption Attach -ManagedDiskId $dataDisk3.Id -Lun 1

Update-AzureRmVM -VM $vm3 -ResourceGroupName $rgName

# SC VM 4 Disk Extension
#######################################################
$dataDisk4  = New-AzureRmDisk -DiskName $dataDisk4Name -Disk $diskConfig -ResourceGroupName $rgName

$vm4 = Get-AzureRmVM -Name $scVM4Name -ResourceGroupName $rgName 
$vm4 = Add-AzureRmVMDataDisk -VM $vm4 -Name $dataDisk4Name -CreateOption Attach -ManagedDiskId $dataDisk4.Id -Lun 1

Update-AzureRmVM -VM $vm4 -ResourceGroupName $rgName
