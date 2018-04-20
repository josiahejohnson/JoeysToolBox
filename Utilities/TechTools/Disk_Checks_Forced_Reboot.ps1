#Attempts to run code 
try {
    
    #Gets Operating System Version and stores in variable $arr
    $OSVersion = (Get-CimInstance Win32_OperatingSystem).Version.substring(0,2)

    #$OSVersion is tested to see if its equal to the number 10 which represents Windows 10
    if($OSVersion -ne 10){

        chkdsk $env:SystemDrive
        
        $Result1 = Get-EventLog -LogName Application -Source Chkdsk | Select-Object -Last 1 | Where-Object {$_.Message -match 'Windows has scanned the file system and found no problems'}

        if($Result1){
         
             #sets a 3 layer check disk for next reboot
             fsutil dirty set $env:SystemDrive
         
             #System File Checker scans for corruptions with Windows Files and Registry Files and corrects them
             sfc /scannow

             #Reboots the computer after 60 minutes
             shutdown -r -t 3600
         }

     }


    Else{

            #Checks the volume for corruptions and stores the result of that scan in variable $Result
            $Result = Repair-Volume C -Scan

            #Checks to see if variable $Result is NOT equal to "No Errors Found." If not, it executes code inside of If Statement
            if ($Result -ne "NoErrorsFound"){

                #Writes out what is inside variable $Result
                write-warning $Result 

                #Schedules a 3 layer check disk for the next time the machine is restarted
                Repair-Volume -DriveLetter C -OfflineScanAndFix

                #System File Checker scans for corruptions with Windows Files and Registry Files and corrects them
                sfc /scannow

                #Reboots the computer after 60 minutes
                shutdown -r -t 3600

               
            }
  
            #If no corruptions are found initially, "Drive is OK" is displayed
            Else {“Drive is OK”}

        }

#Type 
}Catch{$error[0].Exception.Message}