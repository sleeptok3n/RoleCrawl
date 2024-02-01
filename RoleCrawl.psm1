# Author: Eli Ainhorn (sleeptok3n)
# License: BSD 3-Clause

Write-Host -ForegroundColor Green " 
   ▄████████  ▄██████▄   ▄█          ▄████████  ▄████████    ▄████████    ▄████████  ▄█     █▄   ▄█      
  ███    ███ ███    ███ ███         ███    ███ ███    ███   ███    ███   ███    ███ ███     ███ ███              
  ███    ███ ███    ███ ███         ███    █▀  ███    █▀    ███    ███   ███    ███ ███     ███ ███      
 ▄███▄▄▄▄██▀ ███    ███ ███        ▄███▄▄▄     ███         ▄███▄▄▄▄██▀   ███    ███ ███     ███ ███      
▀▀███▀▀▀▀▀   ███    ███ ███       ▀▀███▀▀▀     ███        ▀▀███▀▀▀▀▀   ▀███████████ ███     ███ ███      
▀███████████ ███    ███ ███         ███    █▄  ███    █▄  ▀███████████   ███    ███ ███     ███ ███      
  ███    ███ ███    ███ ███▌    ▄   ███    ███ ███    ███   ███    ███   ███    ███ ███ ▄█▄ ███ ███▌    ▄
  ███    ███  ▀██████▀  █████▄▄██   ██████████ ████████▀    ███    ███   ███    █▀   ▀███▀███▀  █████▄▄██
  ███    ███            ▀                                   ███    ███                          ▀               
                              
                               ""Navigating through the permissions maze""
                                    by Eli Ainhorn (sleeptok3n)                                                   
"
if ($IsWindows -or [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
    Write-Host "Detected Windows environment." -ForegroundColor Yellow
} elseif ($IsMacOS) {
    Write-Host "Detected macOS environment." -ForegroundColor Yellow
    if (-not (Get-Module -ListAvailable -Name PSmacOS)) {
        Write-Host "PSmacOS module not found. Installing..." -ForegroundColor Yellow
        Install-Module PSmacOS -Scope CurrentUser -Force
        Import-Module PSmacOS -Force
        Write-Host "PSmacOS module installed successfully." -ForegroundColor Yellow
    } else {
        Write-Host "PSmacOS module is already installed." -ForegroundColor Yellow
        Import-Module PSmacOS
    }
} elseif ($IsLinux) {
    Write-Host "Detected Linux environment." -ForegroundColor Yellow
    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.GraphicalTools)) {
        Write-Host "Microsoft.PowerShell.GraphicalTools module not found. Installing..." -ForegroundColor Yellow
        Install-Module Microsoft.PowerShell.GraphicalTools -Scope CurrentUser -Force
        Import-Module Microsoft.PowerShell.GraphicalTools -Force
        Write-Host "Microsoft.PowerShell.GraphicalTools module installed successfully." -ForegroundColor Yellow
    } else {
        Write-Host "Microsoft.PowerShell.GraphicalTools module is already installed." -ForegroundColor Yellow
    }
} else {
    Write-Host "Detected an unknown environment. Some features may not work as expected." -ForegroundColor Yellow
}
function Show-Data {
    param([Parameter(Mandatory=$true)] [object]$Data)

    if ($IsMacOS) {
        $Data | Out-GridView
    } else {
        # Use Out-GridView on Windows and other platforms
        $Data | Out-GridView
    }
}

function Select-Subscriptions {
    param ([object[]]$allSubscriptions)
    $allSubscriptions | Out-GridView -PassThru -Title "Select One or More Subscriptions"
}


function Connect-ToAzure {
    $azContext = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $azContext -or -not $azContext.Account) {
        Write-Host "No active Azure session found. Initiating login..."
        $azContext = Connect-AzAccount
    }
    else {
        Write-Host "Using existing Azure session for $($azContext.Account.Id)"
    }
    $accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/").Token
    $headers = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type'  = 'application/json'
    }
    return $headers
}


function Get-SelectedSubscriptions {
    $allSubscriptions = Get-AzSubscription
    $selectedSubscriptions = Select-Subscriptions -allSubscriptions $allSubscriptions
    return $selectedSubscriptions
}

function Initialize-Scan {
    $startTime = Get-Date
    Write-Host "Scan started at: $startTime" -ForegroundColor Green
    return $startTime
}

function Finalize-Scan {
    param($startTime, $filePath)
    $endTime = Get-Date
    $totalDuration = $endTime - $startTime
    Write-Host "Scan completed at: $endTime" -ForegroundColor Green
    Write-Host "Total Duration: $totalDuration" -ForegroundColor Green
    Write-Host "Operation completed. Check the $filePath file for details." -ForegroundColor Yellow
}

function Get-AzUserRoleAssignments {
    $startTime = Initialize-Scan
    $headers = Connect-ToAzure
    $selectedSubscriptions = Get-SelectedSubscriptions
    if (-not $selectedSubscriptions) { return }

 try {
        $token = ((Get-AzAccessToken).Token).Split(".")[1].Replace('-', '+').Replace('_', '/')
        while ($token.Length % 4) { $token += "=" }  # Ensure proper Base64 padding
        $userObjectId = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($token)) | ConvertFrom-Json).oid
    } catch {
        Write-Host "Failed to extract user object ID from the token." -ForegroundColor Red
        return
    }

    if (-not $userObjectId) {
        Write-Host "User Object ID is required to proceed." -ForegroundColor Red
        return
    }

    $results = @()
    foreach ($subscription in $selectedSubscriptions) {
        Set-AzContext -SubscriptionId $subscription.Id
        $subscriptionScope = "/subscriptions/$($subscription.Id)"

        # Check role assignments at the subscription level
        try {
            $subscriptionRoleAssignments = Get-AzRoleAssignment -ObjectId $userObjectId -Scope $subscriptionScope -ErrorAction Stop
            foreach ($roleAssignment in $subscriptionRoleAssignments) {
                if ($roleAssignment.Scope -eq $subscriptionScope) {
                    $outputMessage = "Found role assignment for user: $userObjectId - Subscription: $($subscription.Name), Role: $($roleAssignment.RoleDefinitionName), Scope: $($subscription.Id)"
                    Write-Host $outputMessage -ForegroundColor Green

                    $results += New-Object PSObject -Property @{
                        SubscriptionName = $subscription.Name
                        Scope = $roleAssignment.Scope
                        ResourceName = $resource.Name
                        ResourceType = $resource.ResourceType
                        UserID = $userObjectId
                        RoleDefinitionName = $roleAssignment.RoleDefinitionName
                    }
                }
            }
        } catch {
            Write-Host "Error checking subscription-level roles: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Check role assignments at the resource level
        $resources = Get-AzResource
        foreach ($resource in $resources) {
            try {
                $roleAssignments = Get-AzRoleAssignment -ObjectId $userObjectId -Scope $resource.Id -ErrorAction SilentlyContinue
                foreach ($roleAssignment in $roleAssignments) {
                    $outputMessage = "Found role assignment for user: $userObjectId - Subscription: $($subscription.Name), Resource: $($resource.Name), Role: $($roleAssignment.RoleDefinitionName), Scope: $($roleAssignment.Scope), Resource Type: $($resource.ResourceType)"
                    Write-Host $outputMessage -ForegroundColor Green

                    $results += New-Object PSObject -Property @{
                        SubscriptionName = $subscription.Name
                        Scope = $roleAssignment.Scope
                        ResourceName = $resource.Name
                        ResourceType = $resource.ResourceType
                        UserID = $userObjectId
                        RoleDefinitionName = $roleAssignment.RoleDefinitionName
                    }
                }
            } catch {
                Write-Host "Error with resource: $($resource.Id) - $($_.Exception.Message)" -ForegroundColor Red
            }

            $progress = [math]::Round(($resources.IndexOf($resource) / $resources.Count) * 100, 2)
            Write-Progress -Activity "Checking Roles" -Status "$progress% Complete:" -PercentComplete $progress
        }
    }

    $results | Export-Csv -Path "UserRoleAssignments.csv" -NoTypeInformation
    Finalize-Scan -startTime $startTime -filePath "UserRoleAssignments.csv"
}

function Get-AzGroupRoleAssignments {
    $startTime = Initialize-Scan
    $headers = Connect-ToAzure
    $selectedSubscriptions = Get-SelectedSubscriptions
    if (-not $selectedSubscriptions) { return }

    $inputOption = Read-Host "Enter 'id' to input a single group ID or 'file' to input a file path with group IDs"
    $groupIds = @()
    if ($inputOption -eq "file") {
        $filePath = Read-Host "Enter the full path to the text file containing group IDs"
        $groupIds = Get-Content $filePath
    } else {
        $singleGroupId = Read-Host "Enter the Azure AD Group Object ID"
        $groupIds += $singleGroupId
    }

    $results = @()
    foreach ($groupId in $groupIds) {
        foreach ($subscription in $selectedSubscriptions) {
            Set-AzContext -SubscriptionId $subscription.Id
            $subscriptionScope = "/subscriptions/$($subscription.Id)"

            # Check role assignments at the subscription level
            try {
                $subscriptionRoleAssignments = Get-AzRoleAssignment -ObjectId $groupId -Scope $subscriptionScope -ErrorAction Stop
                foreach ($roleAssignment in $subscriptionRoleAssignments) {
                    $outputMessage = "Found role assignment for group: $groupId - Subscription: $($subscription.Name), Role: $($roleAssignment.RoleDefinitionName), Scope: $($subscription.Id)"
                    Write-Host $outputMessage -ForegroundColor Green

                    $results += New-Object PSObject -Property @{
                        SubscriptionName = $subscription.Name
                        Scope = $roleAssignment.Scope
                        ResourceName = $resource.Name
                        ResourceType = $resource.ResourceType
                        GroupID = $groupId
                        RoleDefinitionName = $roleAssignment.RoleDefinitionName
                    }
                }
            } catch {
                Write-Host "Error checking subscription-level roles: $($_.Exception.Message)" -ForegroundColor Red
            }
            # Check role assignments at the resource level
            $resources = Get-AzResource
            foreach ($resource in $resources) {
                try {
                    $roleAssignments = Get-AzRoleAssignment -ObjectId $groupId -Scope $resource.Id -ErrorAction Stop
                    foreach ($roleAssignment in $roleAssignments) {
                        $outputMessage = "Found role assignment for group: $groupId - Subscription: $($subscription.Name), Resource: $($resource.Name), Role: $($roleAssignment.RoleDefinitionName), Scope: $($roleAssignment.Scope), Resource Type: $($resource.ResourceType)"
                        Write-Host $outputMessage -ForegroundColor Green

                        $results += New-Object PSObject -Property @{
                            SubscriptionName = $subscription.Name
                            Scope = $roleAssignment.Scope
                            ResourceName = $resource.Name
                            ResourceType = $resource.ResourceType
                            GroupID = $groupId
                            RoleDefinitionName = $roleAssignment.RoleDefinitionName
                        }
                    }
                } catch {
                    Write-Host "Error with resource: $($resource.Id) - $($_.Exception.Message)" -ForegroundColor Red
                }

                $progress = [math]::Round(($resources.IndexOf($resource) / $resources.Count) * 100, 2)
                Write-Progress -Activity "Checking Roles" -Status "$progress% Complete:" -PercentComplete $progress
            }
        }
    }

    $results | Export-Csv -Path "GroupRoleAssignments.csv" -NoTypeInformation
    Finalize-Scan -startTime $startTime -filePath "GroupRoleAssignments.csv"
}

Export-ModuleMember -Function 'Get-AzUserRoleAssignments', 'Get-AzGroupRoleAssignments'
