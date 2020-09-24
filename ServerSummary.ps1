#COPYRIGHT 2020
#This is the intellectual property of Vince Ryan Bufete completed as of 9/24/2020

#bootstrap integration
$link1 = '"https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css"'
$link2 = '"https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"'
$link3 = '"https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"'

#basic HTML dependencies
$viewport = '"viewport"'
$content = '"width=device-width, initial-scale=1"'
$stylesheet = '"stylesheet"'

#bootstrap classes
$container = '"container"'
$accordion = '"accordion"'
$panel_heading = '"panel-heading"'
$panel_group = '"panel-group"'
$panel_title = '"panel-title"'
$collapse = '"collapse"'
$data_parent = '"#accordion"'
$panel_default = '"panel panel-default"'
$panel_collapse_in = '"panel-collapse collapse in"'
$panel_body = '"panel-body"'
$panel_collapse = '"panel-collapse collapse"'

#favicon
$fav_ip = '"fas fa-wifi"'

#collapse variables
$collapse_href = @();
$collapse_id = @();
$collapse_href = '"#collapse1"' , '"#collapse2"' , '"#collapse3"' , '"#collapse4"' , '"#collapse5"' , '"#collapse6"' , '"#collapse7"' , '"#collapse8"' , '"#collapse9"' , '"#collapse10"'
$collapse_id = '"collapse1"' , '"collapse2"' , '"collapse3"' , '"collapse4"' , '"collapse5"' , '"collapse6"' , '"collapse7"' , '"collapse8"' , '"collapse9"' , '"collapse10"'

#javascript
$js = "$" + "('table').addClass('table table-striped table-sm table-bordered');"

#get server info
#get hostname
$hostname = "$env:computername"

#get Windows Version
$winver = (Get-WmiObject -Class Win32_OperatingSystem).Caption

#get IP
function get_ip{
        Get-WmiObject Win32_NetworkAdapterConfiguration | Select-Object Description, 
        @{Name='IpAddress';Expression={$_.IpAddress -join '; '}}, 
        @{Name='IpSubnet';Expression={$_.IpSubnet -join '; '}}, 
        @{Name='DefaultIPgateway';Expression={$_.DefaultIPgateway -join '; '}}
        }
$IP = get_ip | Select Description, IpAddress  | ConvertTo-Html #-head $header 

#get CPU/RAM

$CPU = Get-WmiObject -Class Win32_Processor | Select-Object -Property Name, Number* | ConvertTo-Html

$PysicalMemory = Get-WmiObject -class "win32_physicalmemory" -namespace "root\CIMV2" -ComputerName $hostname
$RAM = $PysicalMemory | Select Tag,BankLabel,@{n="Capacity(GB)";e={$_.Capacity/1GB}},Manufacturer,PartNumber,Speed | ConvertTo-Html

#get Roles
Import-Module ServerManager;
$roles = Get-WindowsFeature | Where-Object { $_.Installed -eq $true -and $_.SubFeatures.Count -eq 0} | Select DisplayName, Name | ConvertTo-Html #-head $header 

#get disk info
$diskinfo = Get-Volume | select @{n='Name';e={$env:COMPUTERNAME}}, DriveLetter, FileSystemLabel, FileSystem, @{n='SizeGB';e={[math]::Round($_.Size/1GB)}}, @{n='FreeSpaceGB';e={[math]::Round($_.SizeRemaining/1GB)}}, AllocationUnitSize, OperationalStatus, HealthStatus | sort DriveLetter | ConvertTo-Html #-head $header 

#get installed apps
$installed = @();
$installed2 = @();
$display_installed = @();
$localinstall = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $localinstall){
    $installed += $obj.GetValue('DisplayName') + " - " + $obj.GetValue('DisplayVersion')
}


$userinstall = Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($obj in $userinstall){
    $installed += $obj.GetValue('DisplayName') + " - " + $obj.GetValue('DisplayVersion')
}

$otherinstall = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*|  Select DisplayName
foreach($obj in $otherinstall){
    $installed += $obj.DisplayName
}


foreach($obj in $installed){
if($obj.length -gt 3){
$installed2 += $obj
    }
} 
$display_installed += "<table>"
$display_installed += "<thead><th>Installed Applications</th></thead>"
$display_installed += "<tbody>"
foreach($obj in $installed2){
$display_installed += "<tr><td>$($obj)</td></tr>"
}
$display_installed += "</tbody></table>"

#get local admins
#function to trim excess from local admins command
function trim-list($serveradmins) {

       $trim = $serveradmins.Count - 2 #2 is the comments below
       #6 is the beginning of the admins list dropping comments
       For ($i=6; $i -le $serveradmins.Count; $i++) {
           if($i -lt $trim){
           $serveradmins[$i]
                        
        }       
    }
}

$admins = net localgroup administrators;
$admins = trim-list($admins);

$admins_report = "<br><table>"
$admins_report += "<thead><th>Usernames</th></thead>"
foreach($admin in $admins){
$admins_report += "<tr><td>$($admin)</td></tr>"
}
$admins_report += "</table>"


#get running services
$services = Get-Service | Where-Object {$_.Status -like '*Running*'} | Select-Object Name, DisplayName, Status | ConvertTo-Html #-head $header 

#get netstat
$netstat = get-nettcpconnection | Where-Object { ($_.State -eq "Established") -or ($_.State -eq "Listen") } | select local*,remote*,state,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | ConvertTo-Html #-head $header 

#display winpackages
$winpackage = Get-WindowsPackage -Online | select packagename, packagestate, releasetype, installtime | Convertto-HTML

#get shared folders
$shared =get-wmiobject -class win32_share -property * | select name, path, description | ConvertTo-Html #-head $header 

#display server info
$report = "

<!DOCTYPE html>
<html>
<head>
  <meta name=$viewport content=$content>
  <link rel=$stylesheet href=$link1> 
  <script src=$link2></script>
  <script src=$link3></script>
  <script>
    function addclass() {
        table.classList.add('table table-striped')
    }
  </script>
  <style>
  .panel-body{
        margin: 1vw;
   }
    table{
     width: 80% !important;
    }
  </style>
</head>
<body onload='addclass()'>

<div class=$container>
  <h2 style='margin-bottom: 0px;'>Server Summary: $($hostname)</h2>
  <h3 style='margin-top: 0px;'>$($winver)</h3>
  <hr>
  <p><strong>Note:</strong> <i class=$fav_ip></i>This document was generated using the MTS server summary script and is for internal use only.</p>
  <div class=$panel_group id=$accordion>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[0])> IP Addresses</a>
        </h4>
      </div>
      <div id=$($collapse_id[0]) class=$panel_collapse_in>
        <div class=$panel_body’>
        
        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $($IP)
        </table>
        </center><!--CONTENT HERE-->
        
        </div>
      </div>
    </div>

        <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[1])>CPU/RAM</a>
        </h4>
      </div>
      <div id=$($collapse_id[1]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $CPU
        $RAM
        </table>
        </center><!--CONTENT HERE-->

        </div>
      </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[2])>Disk Information</a>
        </h4>
      </div>
      <div id=$($collapse_id[2]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $diskinfo
        </table>
        </center><!--CONTENT HERE-->

            </div>
        </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[3])>Roles and Features</a>
        </h4>
      </div>
      <div id=$($collapse_id[3]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $roles
        </table>
        </center><!--CONTENT HERE-->

        </div>
      </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[4])>Local Administrators</a>
        </h4>
      </div>
      <div id=$($collapse_id[4]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        $admins_report
        </center><!--CONTENT HERE-->

        </div>
      </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[5])>Installed Applications</a>
        </h4>
      </div>
      <div id=$($collapse_id[5]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $display_installed
        </table>
        </center><!--CONTENT HERE-->
        </div>
      </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[6])>Running Services</a>
        </h4>
      </div>
      <div id=$($collapse_id[6]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $services
        </table>
        </center><!--CONTENT HERE-->

        </div>
      </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[7])>Listening Ports</a>
        </h4>
      </div>
      <div id=$($collapse_id[7]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $netstat
        </table>
        </center><!--CONTENT HERE-->

        </div>
      </div>
    </div>

    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[8])>Installed Packages</a>
        </h4>
      </div>
      <div id=$($collapse_id[8]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $winpackage
        </table>
        </center><!--CONTENT HERE-->

            </div>
        </div>
    </div>
    
    <div class=$panel_default>
      <div class=$panel_heading>
        <h4 class=$panel_title>
          <a data-toggle=$collapse data-parent=$data_parent href=$($collapse_href[9])>Shared Folders</a>
        </h4>
      </div>
      <div id=$($collapse_id[9]) class=$panel_collapse’>
        <div class=‘panel-body’>

        <!--CONTENT HERE--><center>
        <table class='table table-bordered'>
        $shared
        </table>
        </center><!--CONTENT HERE-->

            </div>
        </div>
    </div>
    
</body>
</html>
 
<script>
$($js)
</script>

"

$report | Out-File -FilePath "C:\Temp\test3.html"
