<#
.SYNOPSIS
    Matte OS test VM on Hyper-V (run from Windows).

.EXAMPLE
    .\matte-vm.ps1 setup       # enable Hyper-V if needed, then create the VM
    .\matte-vm.ps1 start       # power on and open the VM window
    .\matte-vm.ps1 ip          # show the VM's IP address (for SSH / VS Code)
    .\matte-vm.ps1 snapshot    # save a checkpoint (do this after a clean install)
    .\matte-vm.ps1 restore     # roll back to the latest checkpoint
    .\matte-vm.ps1 eject       # remove the install ISO once the OS is installed
    .\matte-vm.ps1 stop        # shut the VM down

    Asks for administrator approval itself. Writes everything it prints to matte-vm.log next to this file.
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet('setup', 'start', 'connect', 'ip', 'snapshot', 'restore', 'eject', 'stop')]
    [string]$Action = 'setup',
    [string]$Name = 'MatteOS',
    [string]$IsoPath = "$env:USERPROFILE\Downloads\bazzite-nvidia-open-stable-live-amd64.iso",
    [string]$VmRoot = 'D:\VMs',
    [int]$MemoryGB = 8,
    [int]$Cpus = 6,
    [int]$DiskGB = 80,
    [string]$SnapshotName = ''
)

$ErrorActionPreference = 'Stop'

# --- Ask for admin rights (Hyper-V needs them) ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`"", $Action,
        '-Name', $Name, '-IsoPath', "`"$IsoPath`"", '-VmRoot', "`"$VmRoot`"",
        '-MemoryGB', $MemoryGB, '-Cpus', $Cpus, '-DiskGB', $DiskGB, '-SnapshotName', "`"$SnapshotName`"")
    Start-Process powershell -Verb RunAs -ArgumentList $argList
    return
}

Start-Transcript -Path (Join-Path $PSScriptRoot 'matte-vm.log') -Force | Out-Null
try {
    # --- Hyper-V must be on ---
    $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    if ($feature.State -ne 'Enabled') {
        if ($Action -ne 'setup') { throw 'Hyper-V is not enabled yet. Run "setup" first.' }
        Write-Host 'Turning on Hyper-V...'
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart | Out-Null
        Write-Host 'DONE: Hyper-V is enabled. RESTART WINDOWS, then run "setup" again to create the VM.'
        return
    }

    # Let the normal user manage VMs next time (takes effect after signing out and in).
    try { Add-LocalGroupMember -Group 'Hyper-V Administrators' -Member $env:USERNAME -ErrorAction Stop } catch { }

    function Get-MatteVm { Get-VM -Name $Name -ErrorAction SilentlyContinue }

    switch ($Action) {
        'setup' {
            if (Get-MatteVm) { Write-Host "VM '$Name' already exists. Nothing to do."; break }
            if (-not (Test-Path $IsoPath)) { throw "Installer ISO not found: $IsoPath" }

            $vmDir = Join-Path $VmRoot $Name
            New-Item -ItemType Directory -Force -Path $vmDir | Out-Null
            $vhd = Join-Path $vmDir "$Name.vhdx"

            New-VHD -Path $vhd -SizeBytes ($DiskGB * 1GB) -Dynamic | Out-Null
            New-VM -Name $Name -Generation 2 -MemoryStartupBytes ($MemoryGB * 1GB) -VHDPath $vhd `
                -SwitchName 'Default Switch' -Path $VmRoot | Out-Null
            Set-VM -Name $Name -ProcessorCount $Cpus -StaticMemory -CheckpointType Standard -AutomaticCheckpointsEnabled $false
            Set-VMFirmware -VMName $Name -EnableSecureBoot Off
            Add-VMDvdDrive -VMName $Name -Path $IsoPath
            Set-VMFirmware -VMName $Name -FirstBootDevice (Get-VMDvdDrive -VMName $Name)
            Set-VMVideo -VMName $Name -HorizontalResolution 1920 -VerticalResolution 1080 -ResolutionType Single
            Enable-VMIntegrationService -VMName $Name -Name 'Guest Service Interface'

            Write-Host "DONE: VM '$Name' created ($MemoryGB GB RAM, $Cpus CPUs, $DiskGB GB disk) in $vmDir."
            Write-Host 'Next: .\matte-vm.ps1 start, then install from the ISO.'
        }
        'start' {
            Start-VM -Name $Name
            Start-Process vmconnect.exe -ArgumentList 'localhost', $Name
        }
        'connect' { Start-Process vmconnect.exe -ArgumentList 'localhost', $Name }
        'ip' {
            $addr = (Get-VMNetworkAdapter -VMName $Name).IPAddresses | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }
            if ($addr) { Write-Host "VM IP: $($addr -join ', ')" } else { Write-Host 'No IP yet. Is the VM running and booted?' }
        }
        'snapshot' {
            $label = if ($SnapshotName) { $SnapshotName } else { 'matte-' + (Get-Date -Format 'yyyy-MM-dd-HHmm') }
            Checkpoint-VM -Name $Name -SnapshotName $label
            Write-Host "Checkpoint saved: $label"
        }
        'restore' {
            $cp = Get-VMCheckpoint -VMName $Name | Sort-Object CreationTime | Select-Object -Last 1
            if (-not $cp) { throw 'No checkpoints yet. Run "snapshot" first.' }
            Restore-VMCheckpoint -VMCheckpoint $cp -Confirm:$false
            Write-Host "Restored: $($cp.Name)"
        }
        'eject' {
            Set-VMDvdDrive -VMName $Name -Path $null
            Set-VMFirmware -VMName $Name -FirstBootDevice (Get-VMHardDiskDrive -VMName $Name)
            Write-Host 'ISO removed; the VM now boots from its disk.'
        }
        'stop' { Stop-VM -Name $Name }
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}
finally {
    Stop-Transcript | Out-Null
}
