# Desktop Configuration
This program sets the default applications, sets the taskbar layout, and disables a few of the more 
decorative elements on the taskbar. 

## How it Works
---
### Taskbar Layout - File Creation
The taskbar layout dictates the shortcuts which are pinned to the taskbar and this layout is defined by XML file. Within this program, the function responsible for creating the XML file is called `create_taskbar_layout`. It takes one argument, `$taskbar_path` which is the file location that the final XML file will be saved to. The function starts by generating the default `StartLayout.xml` which is the layout found in the Start window. This is accomplished by running   
`Export-StartLayout -UseDesktopApplicationID -Path $taskbar_path`  
After this file is generated, the function goes on to create, format, and append the neccesary XML nodes corresponding to the applications to be pinned.

### Taskbar Layout - GPO


### Default Application Associations - File Creation
Similar to the taskbar layout, the default applications can be defined in an XML file. Specifically, this file defines an association between file extension and the application to open files with that extension. Like the previous funtion, we first generate a default XML template with the following command  
`dism /online /Export-DefaultAppAssociations:$appassocs_path | Out-Null`  
This produces the current default application association file. The rest of the function serves only to edit the nodes using the applications defined in the global array `$dalps`, which contains the Desktop Application link paths for the desired default applications. 

### Default Application Associations - GPO
Unsimilar to the taskbar layout, automating default applications is far less trivial. Since Windows 8, when a user manually sets a default application, this creates a few values in the registry. At  
`HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\<extension>\UserChoice`  
there are the following registry values
* Hash: (REG_SZ) salted hash of the application created by propietary Microsoft hash algorithm
* ProgId: (REG_SZ) ID of application  


The Hash value is what prevents users from being able to automate the task of setting their default applications. Used in the calculation of this hash is information which indicates whether the value was set manually by a user (through the Windows GUI) or by a script, and the values will be ignored if it was not set manually by a user.   
The way around this is to use the following GPO:  
`Computer Configuration\Administrator Templates\Windows Components\File Explorer\Set a default associations configuration file`  
Within this GPO, an administrator supplies a path to the default application association XML file. There are two important conditions which must be met for this GPO to apply
* It applies only to a new user's *first* login.
* It applies only to users who login to a domain joined device.  

Yet another snag is the fact that GPOs are not simply enabled and configured through PowerShell. However, GPOs ultimately are just APIs which control registry values. Microsoft has provided a [document](https://www.microsoft.com/en-us/download/details.aspx?id=25250) which lists all available GPOs and the registry values that underpin them. This presents an opening to how we can automate the default application. The registry key for the GPO is:  
`HKLM:\Software\Policies\Microsoft\Windows\System`  
and the key created is  
`DefaultAssociationsConfiguration`  
which is of type string and holds the file path to the application association xml file. Note: When the GPO is not configured or is disabled, the `System` folder does not exist.  
The function responsible for making the necessary changes in the registry is called `set_default_appassoc()`. It takes one argument, `appassoc_path`, which is the file location the XML is saved to. 


