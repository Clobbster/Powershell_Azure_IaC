11/28/2018

This is a collection of Azure Powershell that I've put together to use as a quickstart training guide to get myself
and others quickly working with Infrastructure as Code in the Azure space. I found that it was difficult to get started
so worked bit by bit so that those coming after me would have at least an easier time in getting started. 

1. PSInstall_and_Subcr_Selection.ps1
	This script will show you how to install the tools you need to get started. After installation and connection
	it goes through the cmdlets that will show you how to verify the current subscription and how to select one of 
	your choosing.

2. VM4-Env.ps1
	This script will, with little modification, provision everything that you need for an environment with 4 VMs. 
	If you already have your own Resource Groups(RGs), Virtual Networks(VNets), Storage, and Network Security 
	Groups(NSGs), you can always modify this document to reflect what you currently have.

NEXT STEPS:
	Potential 'Next Steps' would be to utilize Powershell Dot Sourcing to better structure your Infrastructure
	as Code Codebase. I find that Powershell being so useful in Azure that this may not be necessary. It will be
	up to your entrerprise needs and discretion. 

	I fully intend to keep this as up to date as necessary to ensure that I have a sizable toolbox to pull tools
	from regarding this repo. 

