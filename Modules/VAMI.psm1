﻿Function Get-VAMISummary {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 20, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves some basic information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return basic VAMI summary info
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMISummary
#>
    $systemVersionAPI = Get-CisService -Name 'com.vmware.appliance.system.version'
    $results = $systemVersionAPI.get() | select product, type, version, build, install_time

    $systemUptimeAPI = Get-CisService -Name 'com.vmware.appliance.system.uptime'
    $ts = [timespan]::fromseconds($systemUptimeAPI.get().toString())
    $uptime = $ts.ToString("hh\:mm\:ss\,fff")

    $summaryResult = [pscustomobject] @{
        Product = $results.product;
        Type = $results.type;
        Version = $results.version;
        Build = $results.build;
        InstallTime = $results.install_time;
        Uptime = $uptime
    }
    $summaryResult
}

Function Get-VAMIHealth {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 25, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves health information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return VAMI health
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIHealth
#>
    $healthOverall = (Get-CisService -Name 'com.vmware.appliance.health.system').get()
    $healthLastCheck = (Get-CisService -Name 'com.vmware.appliance.health.system').lastcheck()
    $healthCPU = (Get-CisService -Name 'com.vmware.appliance.health.load').get()
    $healthMem = (Get-CisService -Name 'com.vmware.appliance.health.mem').get()
    $healthSwap = (Get-CisService -Name 'com.vmware.appliance.health.swap').get()
    $healthStorage = (Get-CisService -Name 'com.vmware.appliance.health.storage').get()

    # DB health only applicable for Embedded/External VCSA Node
    $vami = (Get-CisService -Name 'com.vmware.appliance.system.version').get()

    if($vami.type -eq "vCenter Server with an embedded Platform Services Controller" -or $vami.type -eq "vCenter Server with an external Platform Services Controller") {
        $healthVCDB = (Get-CisService -Name 'com.vmware.appliance.health.databasestorage').get()
    } else {
        $healthVCDB = "N/A"
    }
    $healthSoftwareUpdates = (Get-CisService -Name 'com.vmware.appliance.health.softwarepackages').get()

    $healthResult = [pscustomobject] @{
        HealthOverall = $healthOverall;
        HealthLastCheck = $healthLastCheck;
        HealthCPU = $healthCPU;
        HealthMem = $healthMem;
        HealthSwap = $healthSwap;
        HealthStorage = $healthStorage;
        HealthVCDB = $healthVCDB;
        HealthSoftware = $healthSoftwareUpdates
    }
    $healthResult
}

Function Get-VAMIAccess {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 26, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves access information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return VAMI access interfaces (Console,DCUI,Bash Shell & SSH)
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIAccess
#>
    $consoleAccess = (Get-CisService -Name 'com.vmware.appliance.access.consolecli').get()
    $dcuiAccess = (Get-CisService -Name 'com.vmware.appliance.access.dcui').get()
    $shellAccess = (Get-CisService -Name 'com.vmware.appliance.access.shell').get()
    $sshAccess = (Get-CisService -Name 'com.vmware.appliance.access.ssh').get()

    $accessResult = New-Object PSObject -Property @{
        Console = $consoleAccess;
        DCUI = $dcuiAccess;
        BashShell = $shellAccess.enabled;
        SSH = $sshAccess
    }
    $accessResult
}

Function Get-VAMITime {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 27, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves the time and NTP info from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return current Time and NTP information
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMITime
#>
    $systemTimeAPI = Get-CisService -Name 'com.vmware.appliance.system.time'
    $timeResults = $systemTimeAPI.get()

    $timeSync = (Get-CisService -Name 'com.vmware.appliance.techpreview.timesync').get()
    $timeSyncMode = $timeSync.mode

    $timeResult  = [pscustomobject] @{
        Timezone = $timeResults.timezone;
        Date = $timeResults.date;
        CurrentTime = $timeResults.time;
        Mode = $timeSyncMode;
        NTPServers = "N/A";
        NTPStatus = "N/A";
    }

    if($timeSyncMode -eq "NTP") {
        $ntpServers = (Get-CisService -Name 'com.vmware.appliance.techpreview.ntp').get()
        $timeResult.NTPServers = $ntpServers.servers
        $timeResult.NTPStatus = $ntpServers.status
    }
    $timeResult
}

Function Get-VAMINetwork {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Jan 31, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves network information from VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return networking information including details for each interface
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMINetwork
#>
    $netResults = @()

    $Hostname = (Get-CisService -Name 'com.vmware.appliance.networking.dns.hostname').get()
    $dns = (Get-CisService -Name 'com.vmware.appliance.networking.dns.servers').get()

    Write-Host "Hostname: " $hostname
    Write-Host "DNS Servers: " $dns.servers

    $interfaces = (Get-CisService -Name 'com.vmware.appliance.networking.interfaces').list()
    foreach ($interface in $interfaces) {
        $ipv4API = (Get-CisService -Name 'com.vmware.appliance.techpreview.networking.ipv4')
        $spec = $ipv4API.Help.get.interfaces.CreateExample()
        $spec+= $interface.name
        $ipv4result = $ipv4API.get($spec)

        $interfaceResult = [pscustomobject] @{
            Inteface =  $interface.name;
            MAC = $interface.mac;
            Status = $interface.status;
            Mode = $ipv4result.mode;
            IP = $ipv4result.address;
            Prefix = $ipv4result.prefix;
            Gateway = $ipv4result.default_gateway;
            Updateable = $ipv4result.updateable
        }
        $netResults += $interfaceResult
    }
    $netResults
}

Function Get-VAMIDisks {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Feb 02, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves VMDK disk number to partition mapping VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return VMDK disk number to OS partition mapping
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIDisks
#>
    $storageAPI = Get-CisService -Name 'com.vmware.appliance.system.storage'
    $disks = $storageAPI.list()

    foreach ($disk in $disks | sort {[int]$_.disk.toString()}) {
        $disk | Select Disk, Partition
    }
}

Function Start-VAMIDiskResize {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Feb 02, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function triggers an OS partition resize after adding additional disk capacity
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function triggers OS partition resize operation
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Start-VAMIDiskResize
#>
    $storageAPI = Get-CisService -Name 'com.vmware.appliance.system.storage'
    Write-Host "Initiated OS partition resize operation ..."
    $storageAPI.resize()
}

Function Get-VAMIStatsList {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Feb 06, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves list avialable monitoring metrics in VAMI interface (5480)
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return list of available monitoring metrics that can be queried
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIStatsList
#>
    $monitoringAPI = Get-CisService -Name 'com.vmware.appliance.monitoring'
    $ids = $monitoringAPI.list() | Select id | Sort-Object -Property id

    foreach ($id in $ids) {
        $id
    }
}

Function Get-VAMIStorageUsed {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Date:          Feb 06, 2016
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
	===========================================================================
    .SYNOPSIS
        This function retrieves the individaul OS partition storage utilization
        for a VCSA node which can be an Embedded VCSA, External PSC or External VCSA.
    .DESCRIPTION
        Function to return individual OS partition storage utilization
    .EXAMPLE
        Connect-CisServer -Server 192.168.1.51 -User administrator@vsphere.local -Password VMware1!
        Get-VAMIStorageUsed
#>
    $monitoringAPI = Get-CisService 'com.vmware.appliance.monitoring'
    $querySpec = $monitoringAPI.help.query.item.CreateExample()

    # List of IDs from Get-VAMIStatsList to query
    $querySpec.Names = @(
    "storage.used.filesystem.autodeploy",
    "storage.used.filesystem.boot",
    "storage.used.filesystem.coredump",
    "storage.used.filesystem.imagebuilder",
    "storage.used.filesystem.invsvc",
    "storage.used.filesystem.log",
    "storage.used.filesystem.netdump",
    "storage.used.filesystem.root",
    "storage.used.filesystem.updatemgr",
    "storage.used.filesystem.vcdb_core_inventory",
    "storage.used.filesystem.vcdb_seat",
    "storage.used.filesystem.vcdb_transaction_log",
    "storage.totalsize.filesystem.autodeploy",
    "storage.totalsize.filesystem.boot",
    "storage.totalsize.filesystem.coredump",
    "storage.totalsize.filesystem.imagebuilder",
    "storage.totalsize.filesystem.invsvc",
    "storage.totalsize.filesystem.log",
    "storage.totalsize.filesystem.netdump",
    "storage.totalsize.filesystem.root",
    "storage.totalsize.filesystem.updatemgr",
    "storage.totalsize.filesystem.vcdb_core_inventory",
    "storage.totalsize.filesystem.vcdb_seat",
    "storage.totalsize.filesystem.vcdb_transaction_log"
    )

    # Tuple (Filesystem Name, Used, Total) to store results
    $storageStats = @{
    "autodeploy"=@{"name"="/storage/autodeploy";"used"=0;"total"=0};
    "boot"=@{"name"="/boot";"used"=0;"total"=0};
    "coredump"=@{"name"="/storage/core";"used"=0;"total"=0};
    "imagebuilder"=@{"name"="/storage/imagebuilder";"used"=0;"total"=0};
    "invsvc"=@{"name"="/storage/invsvc";"used"=0;"total"=0};
    "log"=@{"name"="/storage/log";"used"=0;"total"=0};
    "netdump"=@{"name"="/storage/netdump";"used"=0;"total"=0};
    "root"=@{"name"="/";"used"=0;"total"=0};
    "updatemgr"=@{"name"="/storage/updatemgr";"used"=0;"total"=0};
    "vcdb_core_inventory"=@{"name"="/storage/db";"used"=0;"total"=0};
    "vcdb_seat"=@{"name"="/storage/seat";"used"=0;"total"=0};
    "vcdb_transaction_log"=@{"name"="/storage/dblog";"used"=0;"total"=0}
    }

    $querySpec.interval = "DAY1"
    $querySpec.function = "MAX"
    $querySpec.start_time = ((get-date).AddDays(-1))
    $querySpec.end_time = (Get-Date)
    $queryResults = $monitoringAPI.query($querySpec) | Select * -ExcludeProperty Help

    foreach ($queryResult in $queryResults) {
        # Update hash if its used storage results
        if($queryResult.name -match "used") {
            $key = (($queryResult.name).toString()).split(".")[-1]
            $value = [Math]::Round([int]($queryResult.data[1]).toString()/1MB,2)
            $storageStats[$key]["used"] = $value
        # Update hash if its total storage results
        } else {
            $key = (($queryResult.name).toString()).split(".")[-1]
            $value = [Math]::Round([int]($queryResult.data[1]).toString()/1MB,2)
            $storageStats[$key]["total"] = $value
        }
    }

    $storageResults = @()
    foreach ($key in $storageStats.keys | Sort-Object -Property name) {
        $statResult = [pscustomobject] @{
            Filesystem = $storageStats[$key].name;
            Used = $storageStats[$key].used;
            Total = $storageStats[$key].total
        }
        $storageResults += $statResult
    }
    $storageResults
}