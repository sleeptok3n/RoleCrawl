# RoleCrawl

![RoleCrawl](https://github.com/sleeptok3n/RoleCrawl/assets/38359072/304a5dad-add1-4f75-9091-27afb2f20551)

RoleCrawl is a PowerShell tool designed to audit User and Group role assignments within Azure, covering both subscription and resource scopes. It provides two key functions: one for auditing individual user roles and another for group roles. This tool efficiently enables a thorough exploration and analysis of role assignments, revealing potential security vulnerabilities and configuration issues in access controls.

## Prerequisites
PowerShell 5.1 or later.

Azure PowerShell Module installed.

## Installation
Import the RoleCrawl module into your PowerShell session.

```PowerShell
Import-Module ./RoleCrawl.psm1
```

## Usage
### Auditing User Role Assignments
```PowerShell
Get-AzUserRoleAssignments
```
This command audits and displays the Azure role assignments for the current user.
It connects to Azure, retrieves the current user's details, lists all subscriptions through an Out-Gridview, and allows you to select which subscriptions to audit, The tool then scans for role assignments at the subscription and resource levels and outputs the results.

### Auditing Group Role Assignments
```PowerShell
Invoke-GroupRoleAssignments
```
This command audits role assignments for specified Azure AD Groups.
After running this command, you will be prompted to input either a single Azure AD Group Object ID or a file path containing multiple IDs. The tool then performs a similar audit as for users, but for the specified groups.

## Output
The results are displayed in real time in the console and are then exported to CSV files (_AzureUserRoleAssignments.csv_ and _AzureGroupRoleAssignments.csv_) for further analysis.

## Use cases
RoleCrawl was initially developed as an "offensive" tool, aimed at providing a comprehensive solution for mapping the intricate permissions landscape within an Azure tenant. Its core functionality was designed to uncover who or what has access to specific resources or subscriptions, thereby exposing potential vulnerabilities in role-based access controls.

With that being said, it may also be leveraged for Incident Response to efficiently traverse the complex landscape of permissions following a security breach. By pinpointing exactly who had access to compromised resources or subscriptions, RoleCrawl can aid in unraveling the attack vector, helping teams to quickly contain the breach and mitigate its impact.

RoleCrawl extends its utility to proactive security measures, serving as a comprehensive tool for regular Security Audits. It can assist organizations in ensuring that their Azure environments adhere to best practices and comply with stringent regulatory standards. By regularly auditing role assignments, organizations can maintain a tight security posture and prevent unauthorized access.

With RoleCrawl, managing and optimizing role assignments becomes an intuitive process, aligning with the principle of least privilege. This preventive approach minimizes the attack surface by ensuring that users and groups possess only the permissions essential for their roles.

## Operational usage example
As a big fan of Beau Bollock's (@dafthack) [GraphRunner](https://github.com/dafthack/GraphRunner), I have found RoleCrawl to be extremely handy when used together, with the [Get-UpdatableGroups](https://github.com/dafthack/GraphRunner/wiki/Recon-&-Enumeration-Modules#get-updatablegroups) and [Get-DynamicGroups](https://github.com/dafthack/GraphRunner/wiki/Recon-&-Enumeration-Modules#get-updatablegroups) modules from GraphRunner, you can read more about what these modules do and are used for [here](https://www.blackhillsinfosec.com/introducing-graphrunner/). These modules essentially generate a list of groups, and depending on the size and scope of the Azure tenant in question, manually checking these groups' role assignments against resources and subscriptions can be daunting and extremely time consuming. Instead, by compiling a list of the Group IDs, you can utilize the **"Get-AzGroupRoleAssignments"** module within RoleCrawl to efficiently determine the role assignments any controlled groups might have across any resources or subscriptions within the tenant.
