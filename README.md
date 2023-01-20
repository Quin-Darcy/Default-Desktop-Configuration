# Desktop Configuration
This program sets the default applications, sets the taskbar layout, and disables a few of the more 
decorative elements on the taskbar. 

## How it Works
---
### Taskbar Layout
The taskbar layout dictates the shortcuts which are pinned to the taskbar and this layout is defined within an XML file. Within this program, the function responsible for creating the XML file is called `create_taskbar_layout`. It takes one argument, `$taskbar_path` which is the file location that the final XML file will be saved to. The function starts by generating the default `StartLayout.xml` which is the layout found in the Start window. This is accomplished by running   
`Export-StartLayout -UseDesktopApplicationID -Path $taskbar_path`  
After this file is generated, the function goes on to create, format, and append the neccesary XML nodes corresponding to the applications to be pinned.

### Default Application Associations
Similar to the taskbar layout, the default applications can be defined in an XML file. Specifically, this file defines an association between file extension and the application to open files with that extension. Unsimilar to the taskbar layout, automating default applications is far less trivial. Since Windows 8, when a user manually sets a default application, this creates a few values in the registry. In
`HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\<extension>\UserChoice`
* Hash: (REG_SZ) salted hash of the application created by propietary Microsoft hash algorithm
* ProgId: (REG_SZ) ID of application

