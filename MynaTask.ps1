#First logic boot
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}
if ($Host.Runspace.ApartmentState -ne 'STA') {
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -File "$PSCommandPath"; return
}

try {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
} catch {
    [System.Windows.MessageBox]::Show("SYSTEM ERROR!")
    exit
}

Write-Host "[>] Myna X CONSOLE"

# --- [ 2. NTDLL ENGINE (SUSPEND/RESUME LOGIC) ] ---
$Win32Code = @'
    using System;
    using System.Runtime.InteropServices;
    public class OmniEngine {
        [DllImport("ntdll.dll")] public static extern int NtSuspendProcess(IntPtr h);
        [DllImport("ntdll.dll")] public static extern int NtResumeProcess(IntPtr h);
    }
'@
Add-Type -TypeDefinition $Win32Code

#UI
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MynaTask Pro" Height="750" Width="1150"
        Background="#050508" WindowStartupLocation="CenterScreen">
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="MYNATASK Pro" FontSize="30" FontWeight="Black" Foreground="#00FF88">
                <TextBlock.Effect>
                    <DropShadowEffect Color="#00FF88" BlurRadius="15" ShadowDepth="0" Opacity="0.8"/>
                </TextBlock.Effect>
            </TextBlock>
            <TextBlock Text="PRO SYSTEM MANAGER | AUTHOR: ItsMynaX" Foreground="#444" FontSize="10" FontWeight="Bold" Margin="2,0,0,0"/>
        </StackPanel>

        <Grid Grid.Row="1" Margin="0,0,0,15">
            <StackPanel Orientation="Horizontal">
                <TextBox Name="SearchBox" Width="220" Height="28" Background="#0A0A0E" Foreground="#00FF88" 
                         BorderBrush="#333" VerticalContentAlignment="Center" Padding="8,0"/>
                
                <Button Name="BtnRefresh" Content="REFRESH" Width="85" Height="28" Margin="10,0,5,0" Background="#111" Foreground="#00FF88" BorderBrush="#00FF88"/>
                <CheckBox Name="CheckAuto" Content="Auto-Sync" IsChecked="True" Foreground="#666" VerticalAlignment="Center" Margin="10,0"/>
                
                <Separator Width="15" Visibility="Hidden"/>
                <Button Name="BtnSuspend" Content="SUSPEND" Width="85" Height="28" Margin="5,0" Background="#111" Foreground="#FFA500" BorderBrush="#FFA500"/>
                <Button Name="BtnResume" Content="RESUME" Width="85" Height="28" Margin="5,0" Background="#111" Foreground="#00CCFF" BorderBrush="#00CCFF"/>
                <Button Name="BtnKill" Content="TERMINATE" Width="95" Height="28" Margin="5,0" Background="#200" Foreground="#FF4444" BorderBrush="#FF4444"/>
            </StackPanel>
            
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <ProgressBar Name="CPUBar" Width="130" Height="6" Background="#111" Foreground="#00FF88" BorderThickness="0" VerticalAlignment="Center"/>
                <TextBlock Name="CPUPct" Text="0%" Foreground="#00FF88" FontSize="11" Margin="10,0,0,0" VerticalAlignment="Center" Width="35"/>
            </StackPanel>
        </Grid>

        <DataGrid Name="ProcGrid" Grid.Row="2" AutoGenerateColumns="False" IsReadOnly="True"
                  Background="#08080C" Foreground="#EEE" RowBackground="#0B0B10" AlternatingRowBackground="#0E0E14"
                  BorderBrush="#1A1A24" SelectionMode="Single" FontFamily="Consolas" FontSize="13"
                  VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling">
            
            <DataGrid.Resources>
                <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#12121A"/>
                    <Setter Property="Foreground" Value="#00FF88"/>
                    <Setter Property="Padding" Value="10"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                </Style>
            </DataGrid.Resources>

            <DataGrid.Columns>
                <DataGridTextColumn Header="NAME" Binding="{Binding Name}" Width="220"/>
                <DataGridTextColumn Header="PID" Binding="{Binding Id}" Width="80"/>
                <DataGridTextColumn Header="RAM" Binding="{Binding RAMDisplay}" Width="100"/>
                <DataGridTextColumn Header="PATH" Binding="{Binding Path}" Width="*"/>
            </DataGrid.Columns>
        </DataGrid>

        <Border Grid.Row="3" Background="#0A0A0E" Margin="0,15,0,0" Padding="12" CornerRadius="4" BorderBrush="#1A1A24" BorderThickness="1">
            <TextBlock Name="ConsoleLog" Text="[SYSTEM] Engine Ready." Foreground="#00FF88" FontFamily="Consolas" FontSize="11"/>
        </Border>
    </Grid>
</Window>
"@

# --- [ 4. LOGIC MAPPING - FIX NULL ERROR ] ---
try {
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $win = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    [System.Windows.MessageBox]::Show("Loi nap giao dien XAML!")
    exit
}

# Mapping UI Elements
$SearchBox  = $win.FindName("SearchBox")
$BtnRefresh = $win.FindName("BtnRefresh")
$BtnSuspend = $win.FindName("BtnSuspend")
$BtnResume  = $win.FindName("BtnResume")
$BtnKill    = $win.FindName("BtnKill")
$CheckAuto  = $win.FindName("CheckAuto")
$CPUBar     = $win.FindName("CPUBar")
$CPUPct     = $win.FindName("CPUPct")
$ProcGrid   = $win.FindName("ProcGrid")
$ConsoleLog = $win.FindName("ConsoleLog")

# Data Collection
$ProcessCollection = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$ProcGrid.ItemsSource = $ProcessCollection

# --- [ 5. CORE FUNCTIONS ] ---

$script:Updating = $false

function Refresh-Processes {
    if ($script:Updating) { return }
    $script:Updating = $true

    $selectedID = if ($ProcGrid.SelectedItem) { $ProcGrid.SelectedItem.Id } else { $null }

    $list = Get-Process | Sort-Object WorkingSet64 -Descending
    
    $ProcessCollection.Clear()
    foreach ($p in $list) {
        $path = "System/Denied"
        try { $path = $p.Path } catch {}
        
        $ProcessCollection.Add([PSCustomObject]@{
            Name       = $p.ProcessName
            Id         = $p.Id
            RAMDisplay = "$([math]::Round($p.WorkingSet64/1MB, 1)) MB"
            Path       = $path
        })
    }

    if ($selectedID) {
        $item = $ProcessCollection | Where-Object { $_.Id -eq $selectedID }
        if ($item) { $ProcGrid.SelectedItem = $item }
    }

    $script:Updating = $false
}

function Invoke-Action($type) {
    $p = $ProcGrid.SelectedItem
    if (-not $p) { return }
    
    try {
        $handle = (Get-Process -Id $p.Id).Handle
        if ($type -eq "Suspend") { 
            [OmniEngine]::NtSuspendProcess($handle)
            $ConsoleLog.Text = "[>] SUCCESS: Suspended $($p.Name)"
            Write-Host "[>] SUCCESS: Suspended"
        } elseif ($type -eq "Resume") {
            [OmniEngine]::NtResumeProcess($handle)
            $ConsoleLog.Text = "[>] SUCCESS: Resumed $($p.Name)"
            Write-Host "[>] SUCCESS: Resumed"
        }
    } catch {
        $ConsoleLog.Text = "[!] ERROR: Access Denied to PID $($p.Id)"
        Write-Host "[!] ERROR: Access Denied to PID $($p.Id)"
    }
}

# --- [ 6. EVENT HANDLERS ] ---

$BtnRefresh.Add_Click({ Refresh-Processes })
$BtnSuspend.Add_Click({ Invoke-Action "Suspend" })
$BtnResume.Add_Click({ Invoke-Action "Resume" })
$BtnKill.Add_Click({
    if ($ProcGrid.SelectedItem) {
        try {
            Stop-Process -Id $ProcGrid.SelectedItem.Id -Force
            Refresh-Processes
            $ConsoleLog.Text = "[X] TERMINATED: $($ProcGrid.SelectedItem.Name)"
        } catch { $ConsoleLog.Text = "[!] ERROR: Failed to Kill process." }
    }
})

$SearchBox.Add_TextChanged({
    $txt = $SearchBox.Text.ToLower()
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($ProcessCollection)
    $view.Filter = [Predicate[object]]{ param($item) $item.Name.ToLower().Contains($txt) }
})

# --- [ 7. PERFORMANCE TIMERS ] ---

$cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
    $val = [int]$cpuCounter.NextValue()
    $CPUBar.Value = $val
    $CPUPct.Text = "$val%"
})

$syncTimer = New-Object System.Windows.Threading.DispatcherTimer
$syncTimer.Interval = [TimeSpan]::FromSeconds(3.5)
$syncTimer.Add_Tick({
    if ($CheckAuto.IsChecked -and -not $SearchBox.IsFocused) {
        Refresh-Processes
    }
})

# --- [ 8. START ] ---
Refresh-Processes
$timer.Start()
$syncTimer.Start()
Write-Host "[>] SUCCESS: Booted"
Write-Host "[!] Notice: The program may experience lag every 1-2 seconds due to loading multiple processes"
$win.ShowDialog() | Out-Null
