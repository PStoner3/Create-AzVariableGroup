<#
  .SYNOPSIS
  Create an Azure Pipeline variable group.

  .DESCRIPTION
  The Create-AzVariableGroup.ps1 script creates an Azure Pipelines variable group for the given
  organization and project

  .PARAMETER InputPath
  None. The Create-AzVariableGroup.ps1 script does not take external input.

  .PARAMETER OutputPath
  None. The Create-AzVariableGroup.ps1 script does not write external output.

  .INPUTS
  None. You can't pipe objects to Create-AzVariableGroup.ps1.

  .OUTPUTS
  Create-AzVariableGroup.ps1 write individual command output to the console.

  .EXAMPLE
  PS> .\Create-AzVariableGroup.ps1
#>

# NoProject provide a list of projects to exclude from creating variable groups
$NoProject = ""

# projectList contains a list of projects for a given organization
$projectList = az devops project list --org https://dev.azure.com/<Your Organization> --query "value[].[name]" -o tsv

# vg_id holds the ID of the newly created variable group
$vg_id = 0


# Global variables used to create Azure Pipelines variable groups. The user must provide the required values
# These can be changed to suit your needs. 
#
#The variables below are to setup a variable group to  authenticate to both Azure Devops 
# Artifatcs registry and an Azure Container Registry
Set-Variable isSecret -Option Constant -Value true
Set-Variable artifacts_password -Option Constant -Value "<Azure DevOps Artifact PAT>"
Set-Variable artifacts_url -Option Constant -Value "https://pkgs.dev.azure.com/<Your Organization>/_packaging/mfg_artifacts/maven/v1"
Set-Variable artifacts_user -Option Constant -Value "<Your Azure DevOps Artifacts user name>"
Set-Variable password -Option Constant -Value "<Azure Container Registry password 1>"
Set-Variable password2 -Option Constant -Value "<Azure Container Registry password 2>"
Set-Variable server -Option Constant -Value "<Azure Container Registry server name>"
Set-Variable user -Option Constant -Value "<Azure Container Registry user name>"
Set-Variable vg_name -Option Constant -Value "<Name of the Variable Group>"
Set-Variable org -Option Constant -Value " https://dev.azure.com/<Your Organization>/"

function Add-VariableGroup{
    Param($project)

    # Add-VariableGroup function executes the az cli command to create a variable group
    # Input parameter is the project for which to create the variable group

    Write-Output $(az pipelines variable-group create --name "$vg_name" --variables artifacts_password="$artifacts_password" artifacts_url="$artifacts_url" artifacts_user="$artifacts_user" password="" password2="" server="$server" user="$user" --authorize true --org "$org" -p "$project")
}

function Get-VgId{
    Param($project)

    # Get-VgId function executes the az cli command to obtain the id of the 
    # specified organization and project.
    # Input parameter is the project for which to create the variable group

    $vg_id = az pipelines variable-group list --org "$org" -p "$project" --query "[].[id]" -o tsv
    Write-Output $vg_id
}

function Update-Secrets{
    Param($project)

    # Update-Secrets function executes the az cli command to add/update secrets
    # in the variable group
    # Input parameter is the project for which to create the variable group

    Write-Output $(az pipelines variable-group variable update --id $vg_id --name password --org "$org" -p "$project" --secret "$isSecret" --value "$password")
    Write-Output $(az pipelines variable-group variable update --id $vg_id --name password2 --org "$org" -p "$project" --secret "$isSecret" --value "$password2")
}

function Get-AzVariableGroup{
    Param($project)

    # Get-AzVariableGroup function executes the az cli command to show the variable group
    # Input parameter is the project for which to create the variable group

    Write-Output $(az pipelines variable-group show --group-id $vg_id --org "$org" -p "$project" --output yaml)
}

# Main loop is executed when the script runs.
foreach ($proj in $projectList){
    if($NoProject.Contains($proj))
    {
        continue
    }
    
    Write-Output $proj

    Add-VariableGroup($proj)
    Get-VgId($proj)
    Update-Secrets($proj)
    Get-AzVariableGroup($proj)
    Write-Output "`r`n"
}
