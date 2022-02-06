# VM Start Stop Micro Service

```powershell
# variables
$resource_group_name = 'start-stop-vms'
$location = 'westeurope'
$storage_account_function_app_name = 'func2109312903jkdhdfk'
$storage_account_queue_name = 'startstop23897837189'
$function_app_name = 'myfunctionapp12383838'
# create resource group
New-AzResourceGroup -Name $resource_group_name -Location $location

# create function app
$storage_account_function_app = New-AzStorageAccount -ResourceGroupName $resource_group_name -AccountName $storage_account_function_app_name -Location $location -SkuName Standard_LRS
$function_app = New-AzFunctionApp -Name $function_app_name -ResourceGroupName $resource_group_name -Location $location -StorageAccount $storage_account_function_app.StorageAccountName -Runtime PowerShell

# create storage account (for queue storage)
$storage_account = New-AzStorageAccount -ResourceGroupName $resource_group_name -AccountName $storage_account_queue_name -Location $location -SkuName Standard_LRS

@('start','stop') | % {
    New-AzStorageQueue -Name $_ -Context $storage_account.Context
}

$key = Get-AzStorageAccountKey -ResourceGroupName $resource_group_name -Name $storage_account_queue_name
$connection_string = "DefaultEndpointsProtocol=https;AccountName=$($storage_account_queue_name);AccountKey=$($key[0].Value);EndpointSuffix=core.windows.net"
Update-AzFunctionAppSetting -Name $function_app_name -ResourceGroupName $resource_group_name -AppSetting @{"QUEUE_CONNECTION_STRING" = $connection_string}
Update-AzFunctionAppSetting -Name $function_app_name -ResourceGroupName $resource_group_name -AppSetting @{"CHECKER_URL" = "https://$($function_app_name).azurewebsites.net/api/check_resources"}

$az_context = Get-AzContext
$master_key = Invoke-AzRestMethod -path "/subscriptions/$($context.Subscription.id)/resourceGroups/$($resource_group_name)/providers/Microsoft.Web/sites/$($function_app_name)/host/default/listKeys?api-version=2018-11-01" -Method POST | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty masterKey

Update-AzFunctionAppSetting -Name $function_app_name -ResourceGroupName $resource_group_name -AppSetting @{"ACCESS_KEY" = $master_key}

# deploy to function app
Set-Location -Path .\start-stop\

# make sure you have the azure function core tools installed
# install with scoop
# scoop install azure-functions-core-tools
# you also need to be logged in with azure cli
func azure functionapp publish $function_app_name

# delete resource group
Remove-AzResourceGroup -Name $resource_group_name -Location $location -Force
```
