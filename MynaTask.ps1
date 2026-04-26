Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="MynaTask"
        Height="650" Width="1100"
        Background="#050505"
        WindowStartupLocation="CenterScreen">

    <Grid Margin="10">

        <!-- HEADER -->
        <TextBlock Text="Myna Task"
                   Foreground="#00FF88"
                   FontSize="18"
                   Margin="10,0,0,0">
            <TextBlock.Effect>
                <DropShadowEffect Color="#00FF88"
                                  BlurRadius="20"
                                  ShadowDepth="0"/>
            </TextBlock.Effect>
        </TextBlock>

        <!-- SEARCH -->
        <TextBox Name="SearchBox"
                 Width="200"
                 Height="25"
                 Margin="10,40,0,0"
                 Background="#111"
                 Foreground="#00FF88"
                 VerticalAlignment="Top"/>

        <!-- BUTTONS -->
        <StackPanel Orientation="Horizontal" Margin="220,40,0,0" VerticalAlignment="Top">

            <Button Name="BtnRefresh" Content="Refresh" Margin="5"
                    Background="#111" Foreground="#00FF88" BorderBrush="#00FF88"/>

            <Button Name="BtnKill" Content="Kill" Margin="5"
                    Background="#111" Foreground="Red" BorderBrush="Red"/>

            <Button Name="BtnOpen" Content="Open" Margin="5"
                    Background="#111" Foreground="Cyan" BorderBrush="Cyan"/>

        </StackPanel>

        <!-- CPU -->
        <ProgressBar Name="CPUBar"
                     Height="20"
                     Margin="10,70,10,0"
                     VerticalAlignment="Top"
                     Foreground="#00FF88"
                     Background="#111"/>

        <!-- DATAGRID -->
        <DataGrid Name="ProcGrid"
                  Margin="10,100,10,120"
                  AutoGenerateColumns="False"
                  IsReadOnly="True"
                  Background="#050505"
                  Foreground="#00FF88"
                  BorderThickness="0"
                  GridLinesVisibility="None"
                  RowBackground="#050505"
                  AlternatingRowBackground="#080808"
                  AlternationCount="2">

            <DataGrid.Resources>

                <!-- HEADER -->
                <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#0f0f0f"/>
                    <Setter Property="Foreground" Value="#00FF88"/>
                    <Setter Property="FontWeight" Value="Bold"/>
                </Style>

                <!-- ROW -->
                <Style TargetType="DataGridRow">
                    <Setter Property="Foreground" Value="#00FF88"/>

                    <Style.Triggers>

                        <!-- SELECT -->
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#002233"/>
                            <Setter Property="Foreground" Value="#00FFFF"/>
                        </Trigger>

                        <!-- HIGH RISK -->
                        <DataTrigger Binding="{Binding Risk}" Value="80">
                            <Setter Property="Background" Value="#220000"/>
                            <Setter Property="Foreground" Value="#FF4444"/>
                        </DataTrigger>

                        <!-- MID RISK -->
                        <DataTrigger Binding="{Binding Risk}" Value="50">
                            <Setter Property="Background" Value="#332200"/>
                            <Setter Property="Foreground" Value="#FFA500"/>
                        </DataTrigger>

                    </Style.Triggers>
                </Style>

            </DataGrid.Resources>

            <DataGrid.Columns>
                <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="200"/>
                <DataGridTextColumn Header="PID" Binding="{Binding Id}" Width="80"/>
                <DataGridTextColumn Header="CPU" Binding="{Binding CPU}" Width="100"/>
                <DataGridTextColumn Header="RAM MB" Binding="{Binding RAM}" Width="120"/>
                <DataGridTextColumn Header="Risk" Binding="{Binding Risk}" Width="80"/>
                <DataGridTextColumn Header="Path" Binding="{Binding Path}" Width="*"/>
            </DataGrid.Columns>

        </DataGrid>

        <!-- DETAIL -->
        <TextBlock Name="DetailText"
                   Margin="10,0,10,10"
                   VerticalAlignment="Bottom"
                   Foreground="#00FF88"
                   TextWrapping="Wrap"/>

    </Grid>
</Window>
"@

# ===== LOAD =====
$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)

$SearchBox = $win.FindName("SearchBox")
$BtnRefresh = $win.FindName("BtnRefresh")
$BtnKill = $win.FindName("BtnKill")
$BtnOpen = $win.FindName("BtnOpen")
$CPUBar = $win.FindName("CPUBar")
$ProcGrid = $win.FindName("ProcGrid")
$DetailText = $win.FindName("DetailText")

# ===== DATA =====
$data = New-Object System.Collections.ObjectModel.ObservableCollection[object]

function Get-Risk($p){
    $r = 0
    if(($p.WorkingSet64/1MB) -gt 400){ $r += 20 }
    if(-not $p.Path){ $r += 10 }
    return [int][math]::Min($r,100)
}

function Load-Data {
    $data.Clear()

    Get-Process | Select-Object -First 120 | ForEach-Object {
        $ram = [math]::Round($_.WorkingSet64/1MB,1)
        $cpu = [int]$_.CPU
        $risk = Get-Risk $_

        $data.Add([PSCustomObject]@{
            Name = $_.ProcessName
            Id   = $_.Id
            CPU  = $cpu
            RAM  = $ram
            Risk = $risk
            Path = $_.Path
        })
    }

    $ProcGrid.ItemsSource = $data
}

# SEARCH
$SearchBox.Add_TextChanged({
    $txt = $SearchBox.Text.ToLower()
    $ProcGrid.ItemsSource = $data | Where-Object {
        $_.Name.ToLower().Contains($txt)
    }
})

# DETAIL
$ProcGrid.Add_SelectionChanged({
    if($ProcGrid.SelectedItem){
        $p = $ProcGrid.SelectedItem
        $DetailText.Text = "Name: $($p.Name) | PID: $($p.Id) | RAM: $($p.RAM) MB | Risk: $($p.Risk)`nPath: $($p.Path)"
    }
})

# BUTTONS
$BtnRefresh.Add_Click({ Load-Data })

$BtnKill.Add_Click({
    if($ProcGrid.SelectedItem){
        try{
            Stop-Process -Id $ProcGrid.SelectedItem.Id -Force
            Load-Data
        }catch{}
    }
})

$BtnOpen.Add_Click({
    if($ProcGrid.SelectedItem -and $ProcGrid.SelectedItem.Path){
        Start-Process explorer.exe "/select, $($ProcGrid.SelectedItem.Path)"
    }
})

# CPU
$cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Processor","% Processor Time","_Total")
$cpuCounter.NextValue() | Out-Null

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(1200)

$timer.Add_Tick({
    $cpu = $cpuCounter.NextValue()
    $CPUBar.Value = [math]::Min([int]$cpu,100)
})

$timer.Start()

# START
Load-Data
$win.ShowDialog()