// Parameters for resource group, automation account, action group, and VM
param automationAccountName string
param actionGroupName string
param runbookName string
param resourceGroupName string
param location string = resourceGroup().location
param vmResourceId string // Resource ID of the VM you want to stop

// Step 1: Create the Automation Account
resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13' = {
  name: automationAccountName
  location: location
}

// Step 2: Create the Runbook (PowerShell) in the Automation Account
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2020-01-13' = {
  name: '${automationAccountName}/${runbookName}'
  location: location
  properties: {
    runbookType: 'PowerShell'
    logVerbose: true
    logProgress: true
    // Runbook Content: PowerShell script to stop the VM
    description: 'Runbook to stop the Azure VM'
  }
}

// Step 3: Upload the PowerShell Script into the Runbook
resource runbookContent 'Microsoft.Automation/automationAccounts/runbooks/content@2020-01-13' = {
  name: '${automationAccountName}/${runbookName}/content'
  properties: {
    content: '''
      param(
    [string]$vmResourceId
    )

    Write-Output "Stopping VM: $vmResourceId"

    # Stop the Azure VM using the provided resource ID
    Stop-AzVM -ResourceId $vmResourceId -Force

    Write-Output "VM Stopped Successfully"
    '''
  }
}

// Step 4: Create the Action Group with the Automation Runbook as an action
resource actionGroup 'Microsoft.Insights/actionGroups@2021-06-01' = {
  name: actionGroupName
  location: location
  properties: {
    groupShortName: 'VMStopGroup'
    enabled: true
    automationRunbookReceivers: [
      {
        automationRunbook: {
          id: runbook.id
        }
        webhookResourceId: automationAccount.id
        runbookAction: {
          automationRunbook: {
            id: runbook.id
          }
          runbookParameters: {
            vmResourceId: vmResourceId // Passing the VM Resource ID to the runbook
          }
        }
      }
    ]
  }
}

output automationAccountId string = automationAccount.id
output runbookId string = runbook.id
output actionGroupId string = actionGroup.id
