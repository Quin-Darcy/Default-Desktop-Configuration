# Place the Desktop Application link paths to the apps 
# you want pinned to the taskbar here
$dalps = @("%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk", 
            "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Word.lnk", 
            "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Excel.lnk",
            "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Outlook.lnk",  
            "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Google Chomre.lnk")

# Function responsible for generating the start/taskbar layout XML file
function create_taskbar_layout($taskbar_path) 
{
    # This line generates the current Start Menu layout XML file 
    # The file is saved to the location specified in $taskbar_path
    Export-StartLayout -UseDesktopApplicationID -Path $taskbar_path
    
    # We create an XML object out of the layout file we just created
    [xml]$layout = Get-Content -Path $taskbar_path

    # Since we will be adding a new Taskbar element, we need to declare a new namespace
    $layout.LayoutModificationTemplate.SetAttribute("xmlns:taskbar", "http://schemas.microsoft.com/Start/2014/TaskbarLayout") 

    # This object will hold all of the document's namespaces
    # Each new element added to the document will be added WRT a namespace in $nsm
    $nsm = New-Object System.Xml.XmlNamespaceManager($layout.nametable) 
    $nsm.addnamespace("defaultlayout", $layout.LayoutModificationTemplate.GetNamespaceOfPrefix("defaultlayout")) 
    $nsm.addnamespace("start", $layout.LayoutModificationTemplate.GetNamespaceOfPrefix("start")) 
    $nsm.addnamespace("taskbar", $layout.LayoutModificationTemplate.GetNamespaceOfPrefix("taskbar")) 

    # Here we create the new Taskbar configuration elements
    # We give it an attribute which allows us to override Windows defaults
    # Then we append the element as a child element of LayoutModificationTemplate
    $tbxml_layer1 = $layout.CreateElement("CustomTaskbarLayoutCollection", $layout.LayoutModificationTemplate.NamespaceURI)
    $tbxml_layer1.SetAttribute("PinListPlacement", "Replace") 
    $tbxml_layer1.RemoveAttribute("xmlns") 
    $layout.LayoutModificationTemplate.AppendChild($tbxml_layer1) 

    $tbxml_layer2 = $layout.CreateElement("defaultlayout:TaskbarLayout",  $nsm.LookupNamespace("defaultlayout"))
    $tbxml_layer3 = $layout.CreateElement("taskbar:TaskbarPinList",  $nsm.LookupNamespace("taskbar"))
    
    # We loop through each of the application link paths and create new nodes out of them
    foreach($dalp in $dalps) 
    {
        $app_node = $layout.CreateElement("taskbar:DesktopApp",  $nsm.LookupNamespace("taskbar"))
        $app_node.SetAttribute("DesktopApplicationLinkPath", $dalp)
        $tbxml_layer3.AppendChild($app_node)
    }
    $tbxml_layer2.AppendChild($tbxml_layer3)
    $layout.LayoutModificationTemplate.CustomTaskbarLayoutCollection.AppendChild($tbxml_layer2)

    $layout.save($taskbar_path) 
}

# Function responsible for generating the default application association XML file
function create_default_appassoc($appassocs_path) 
{
    # This line generates the current deffault application associations XML file 
    # The file is saved to the location specified in $taskbar_path
    dism /online /Export-DefaultAppAssociations:$appassocs_path | Out-Null
    
    # We create an XML object out of the file we just created
    [xml]$appassocs = Get-Content -Path $appassocs_path

    # Collect each Association node
    $assoc_nodes = $appassocs.DefaultAssociations.Association
    
    # Iterate through all nodes
    # Set association by node's Identifier attribute (i.e., file extension)
    foreach($node in $assoc_nodes) 
    {
        if ($node.Identifier -eq ".htm") 
        {
            $node.SetAttribute("ProgId", "ChromeHTML")
            $node.SetAttribute("ApplicationName", "Google Chrome")
        }
        if ($node.Identifier -eq ".html") 
        {
            $node.SetAttribute("ProgId", "ChromeHTML")
            $node.SetAttribute("ApplicationName", "Google Chrome")
        }
        if ($node.Identifier -eq ".pdf") 
        {
            $node.SetAttribute("ProgId", "Acrobat.Document.DC")
            $node.SetAttribute("ApplicationName", "Adobe Acrobat")
        }
        if ($node.Identifier -eq "http") 
        {
            $node.SetAttribute("ProgId", "ChromeHTML")
            $node.SetAttribute("ApplicationName", "Google Chrome")
        }
        if ($node.Identifier -eq "https") 
        {
            $node.SetAttribute("ProgId", "ChromeHTML")
            $node.SetAttribute("ApplicationName", "Google Chrome")
        }
        if ($node.Identifier -eq "mailto") 
        {
            $node.SetAttribute("ProgId", "Outlook.URL.mailto.15")
            $node.SetAttribute("ApplicationName", "Outlook")
        }
    }
    $appassocs.save($appassocs_path) 
}

# Utility function for creating a registry key given a key path
function create_regkey($reg_path) 
{
    if (-Not (Test-Path -Path $reg_path)) 
    {
        Write-Output("Creating Registry Key: "+$reg_path)
        New-Item -Path $reg_path -Force
    }
}

# Utility function for creating a registry value given a key path, value name, value type, and value
function create_regvalue($reg_path, $reg_name, $reg_type, $reg_value) 
{
    if ((Get-ItemProperty $reg_path).PSObject.Properties.Name -Contains $reg_name) 
    {
        Write-Output("Creating Registry value: "+($reg_path+"\"+$reg_name))
        Set-ItemProperty -Path $reg_path -Name $reg_name -Value $reg_value -Force
    } 
    else 
    {
        Write-Output("Creating Registry value: "+($reg_path+"\"+$reg_name))
        New-ItemProperty -Path $reg_path -Name $reg_name -PropertyType $reg_type -Value $reg_value
    }
    Write-Output("    Value set: "+$reg_value+" "+"("+$reg_type+")")
}

# Function which changes the registry values corresponding to the taskbar layout
function set_taskbar_layout($taskbar_path) 
{
    $reg_path = "HKLM:\Software\Policies\Microsoft\Windows\Explorer"
    $reg_name1 = "LockedStartLayout"
    $reg_type1 = "DWord"
    $reg_value1 = 1
    $reg_name2 = "StartLayoutFile"
    $reg_type2 = "ExpandString"
    $reg_value2 = $taskbar_path

    create_regkey($reg_path)
    create_regvalue $reg_path $reg_name1 $reg_type1 $reg_value1
    create_regvalue $reg_path $reg_name2 $reg_type2 $reg_value2
}

# Function which changes registry values corresponding to the default application associations
function set_default_appassoc($appassoc_path) 
{
    # This changes the registry values corresponding to the default application associations
    $reg_path = "HKLM:\Software\Policies\Microsoft\Windows\System"
    $reg_name = "DefaultAssociationsConfiguration"
    $reg_type = "String"
    $reg_value = $appassoc_path
 
    create_regkey($reg_path)
    create_regvalue $reg_path $reg_name $reg_type $reg_value
}

# Stand-alone function for changing the keys in HKLM relating to Cortana
function disable_cortana 
{
    # To simulate the effect of disabling the Allow Cortana GPO
    # We first create the Windows Search folder, then add the
    # AllowCortana value with DWORD 0
    $reg_path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $reg_name = "AllowCortana"
    $reg_type = "DWord"
    $reg_value = 0

    create_regkey($reg_path)
    create_regvalue $reg_path $reg_name $reg_type $reg_value
}

# Stand-alone function for changing the keys in HKLM relating to Taskbar dynamic content
function disable_search_highlights 
{
    # This will disable the graphics which appear in the search bar
    $reg_path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $reg_name = "EnableDynamicContentInWSB"
    $reg_type = "DWord"
    $reg_value = 0

    create_regkey($reg_path)
    create_regvalue $reg_path $reg_name $reg_type $reg_value
}

# Function which loads default hive and sets the RunOnce value 
# This function is needed to assure script runs at new users's first login
function setup_runonce_script($script_path) 
{
    # Load default User Registry Hive to HKLM\NEW_USER
    $reg_path = "HKU:\NEW_USER\Software\Microsoft\Windows\CurrentVersion\Runonce"
    $reg_name = "Script"
    $reg_type = "String"
    $reg_value = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe $script_path"

    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

    REG LOAD HKU\NEW_USER "C:\Users\Default\NTUSER.DAT"

    create_regkey($reg_path)
    create_regvalue $reg_path $reg_name $reg_type $reg_value

    [gc]::Collect()
    REG UNLOAD HKU\NEW_USER
    Remove-PSDrive -Name HKU
}

# Caller function which calls the two XML generator functions
function create_xmls($taskbar_path, $appassoc_path) 
{
    # From this function we call the functions responsible for 
    # generating the default taskbar layout XML file and the
    # default application association XML file
    create_taskbar_layout($taskbar_path)
    create_default_appassoc($appassoc_path)
}

# Caller function which calls the HKLM modifier functions
function modify_HKLM_registry($taskbar_path, $appassoc_path) 
{
    Write-Output("Exporting Registry Keys...")
    # Define registry keys to export before change
    $reg_key = "HKLM\Software\Policies\Microsoft\Windows"

    # Export keys and remove any binary data
    reg export $reg_key "C:\Windows\Temp\key_backup.reg" 

    # These functions perform the same changes their 
    # corresponding GPOs would
    set_taskbar_layout($taskbar_path)
    set_default_appassoc($appassoc_path)
    disable_cortana
    disable_search_highlights
}

# HKCU script which is to be run at new user's first login is created here
# Entire script is stored as a String and written to a file then saved to $script_path
function drop_taskbar_cleanup_script($script_path) 
{
    $script_text = 'function taskbar_cleanup {
    # This function disables the Taskview Button, Taskbar Animations, Cortana Button, and News/Interests
    $reg_paths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", 
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds")

    $reg_names = @("ShowTaskviewButton", "TaskbarAnimations", 
                    "ShowCortanaButton", "ShellFeedsTaskbarViewMode")

    $reg_types = @("DWord", "DWord", "DWord", "DWord")
    $reg_values = @(0, 0, 0, 2)

    for(($i = 0); $i -lt $reg_names.length; $i++) 
    {
        if (-Not (Test-Path -Path $reg_paths[$i])) 
        {
            Write-Output("Creating Registry Key: "+$reg_paths[$i])
            New-Item -Path $reg_paths[$i] -Force | Out-Null
        }

        if ((Get-ItemProperty $reg_paths[$i]).PSObject.Properties.Name -Contains $reg_names[$i]) 
        {
            Write-Output("Creating Registry value: "+($reg_paths[$i]+"\"+$reg_names[$i]))
            Set-ItemProperty -Path $reg_paths[$i] -Name $reg_names[$i] -Value $reg_values[$i] -Force | Out-Null
        } 
        else 
        {
            Write-Output("Creating Registry value: "+($reg_paths[$i]+"\"+$reg_names[$i]))
            New-ItemProperty -Path $reg_paths[$i] -Name $reg_names[$i] -PropertyType $reg_types[$i] -Value $reg_values[$i] | Out-Null
        }
        Write-Output("    Value set: "+$reg_values[$i]+" "+"("+$reg_types[$i]+")")
    }
    
}
taskbar_cleanup

# Delete thyself
Remove-Item -fo $PSCommandPath'

    if (-Not (Test-Path -Path $script_path)) 
    {
        New-Item -Path $script_path
    }
    Set-Content $script_path $script_text
}

$taskbar_path = "C:\Windows\System32\taskbar_layout.xml"
$appassoc_path = "C:\Windows\System32\appassocs.xml"
$script_path = "C:\Windows\System32\hklu_script.ps1"
create_xmls $taskbar_path $appassoc_path
modify_HKLM_registry $taskbar_path $appassoc_path
drop_taskbar_cleanup_script($script_path)
setup_runonce_script($script_path)

# Delete thyself
Remove-Item -fo $PSCommandPath
