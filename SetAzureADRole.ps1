<#
    .SYNOPSIS
        Uses Out-Gridview to choose Role and Role group for assignment to RGs across Azure Subscriptions
    .EXAMPLE
        .\SetAzureADRole.ps1

#>

#if not logged in to Azure, start login
if ((Get-AzureRmContext).Account -eq $Null) {
    Connect-AzureRmAccount -Environment AzureUSGovernment}
    
#if not logged in to AzureAD, start login
try {$var = Get-AzureADTenantDetail } 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] 
    {Connect-AzureAD -AzureEnvironmentName AzureUSGovernment }

# Get Role Group

$RoleGroup = get-azureadgroup | Out-GridView -Title "Select Role Group" -OutputMode Single 

# Get Role 

$Role = Get-AzureRmRoleDefinition | Out-GridView -Title "Select Role" -OutputMode Single 

#Get Subs:

$subs = Get-AzureRmSubscription | Out-GridView -OutputMode Multiple -Title "Select Subscriptions"

#Get All RGs acrossss subs

$RGs = @()

foreach ( $sub in $subs )
{

    Select-AzureRmSubscription -SubscriptionName $sub.Name
    
    $SubRGs = Get-AzureRmResourceGroup |  
        Add-Member -MemberType NoteProperty -Name Subscription -Value $sub.Name -PassThru |
        Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $sub.Id -PassThru |
        Out-GridView -OutputMode Multiple -Title "Select Resource Groups"

    foreach ( $SubRG in $SubRGs )
    {

    $RGs = $RGS + $SubRg

    }
}

# Git-R-Done

foreach ( $RG in $RGs )
{
   
    Write-Host "Working with RG ""$($RG.ResourceGroupName)"" in Sub ""$($RG.Subscription)""" -ForegroundColor Cyan
    
    Select-AzureRmSubscription -SubscriptionName $RG.Subscription | Out-Null

    Write-Host "New Azure Role Assigment for Group ""$($RoleGroup.DisplayName)"" with Role of ""$($Role.Name)"" on RG ""$($RG.ResourceGroupName)"""

    New-AzureRmRoleAssignment -ObjectId $RoleGroup.ObjectId -RoleDefinitionName $Role.Name  -ResourceGroupName $RG.ResourceGroupName
        
}



