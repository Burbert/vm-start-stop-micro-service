using namespace System.Net

param($Request, $TriggerMetadata)

$time_utc = (Get-Date).ToUniversalTime()
$time = '{0}:{1}' -f $time_utc.Hour, $time_utc.Minute

$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    Select-AzSubscription -SubscriptionId $subscription.id

    $vms = Get-AzVm

    if (-not ($vms)) {
        continue
    } else {
        foreach ($vm in $vms) {
            # only process if necessary tags are on vm
            if (-not($vm.tags.ContainsKey('shutdown') -and $vm.tags.ContainsKey('startup'))) {
                Write-Host "skipping VM: $($vm.name) - rg: $($vm.ResourceGroupName) - subscription: $($subscription.id) - tags not available"
                continue
            }

            $obj = [pscustomobject]@{
                'subscription_id'   = $subscription.id
                'name'           = $vm.name
                'resource_group' = $vm.ResourceGroupName
            }
            
            # check startup time
            if ($vm.tags['startup'] -eq $time) {
                Write-Host "starting VM: $($vm.name) - rg: $($vm.ResourceGroupName) - subscription: $($subscription.id)"
                Push-OutputBinding -Name start -Value $obj
            } else {
                Write-Host "skipping start VM: $($vm.name) - rg: $($vm.ResourceGroupName) - subscription: $($subscription.id)"
            }
            
            # check shutdown time
            if ($vm.tags['shutdown'] -eq $time) {
                Write-Host "stopping VM: $($vm.name) - rg: $($vm.ResourceGroupName) - subscription: $($subscription.id)"
                Push-OutputBinding -Name stop -Value $obj
            } else {
                Write-Host "skipping stop VM: $($vm.name) - rg: $($vm.ResourceGroupName) - subscription: $($subscription.id)"
            }
        }
    }
}
