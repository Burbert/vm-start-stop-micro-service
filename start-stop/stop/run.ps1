param($QueueItem, $TriggerMetadata)

Select-AzSubscription -SubscriptionId $QueueItem.subscription_id

Stop-AzVM -Name $QueueItem.name -ResourceGroupName $QueueItem.resource_group -Confirm -NoWait
