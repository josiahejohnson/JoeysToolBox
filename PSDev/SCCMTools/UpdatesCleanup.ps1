<#

    Author: Trevor Sullivan
    
    Author E-mail: pcgeek86@gmail.com
    
    Description: This script cleans up various software updates (patch) related objects in System Center Configuration Manager
                by removing expired (and eventually superseded) software updates from them. The objects affected include Update Lists,
                Deployment Management objects, and Software Updates Packages.

                This script could be significantly optimized by retrieving a list of all expired SMS_SoftwareUpdate.CI_ID using a single
                WMI query, and then doing a comparison on that, rather than testing if each, individual update is expired. Although WMI is fairly
                quick at returning query results, it does create unnecessary performance issues by making hundreds of WMI calls rather than a handful.
#>

$VerbosePreference = "continue"

function Get-SccmSiteCode
{
    param($ServerName)
    
    $SccmSiteCode = @(Get-WmiObject -Namespace root\sms -Class SMS_ProviderLocation -ComputerName $ServerName)[0].SiteCode
    # Write-Host "Found SCCM site code for $ServerName: $SccmSiteCode"
    Write-Output $SccmSiteCode
}

function Remove-SccmExpiredUpdates
{
    param(
        [Parameter(Mandatory = $true)]
        $SccmServer ,
        [Parameter(Mandatory = $false)]
        $SccmSiteCode ,
        [Hashtable]
        $PackageFilter = $null
    )
    
    process
    {
        if (-not (Test-Connection $SccmServer) -and -not (Get-WmiObject -ComputerName $SccmServer -Namespace root -Class __NAMESPACE -Filter "Name = 'sms'"))
        {
            Write-Error "Could not find SCCM provider on $SccmServer"
            break
        }
        
        # Get the SCCM site code for the server
        if (-not $SccmSiteCode)
        {
            $SccmSiteCode = (Get-SccmSiteCode $SccmServer)
        }
        
        
        #region Clean up Update Lists
        # Remove expired updates from update (authorization) lists that are owned by this SCCM primary site
        $UpdateLists = @(Get-WmiObject -Namespace root\sms\site_$SccmSiteCode -Class SMS_AuthorizationList -ComputerName $SccmServer -Filter "SourceSite = '$SccmSiteCode'")
        
        foreach ($UpdateList in $UpdateLists)
        {
            # The Updates property on SMS_AuthorizationList is a lazy property,
            # so we must get a direct reference to the WMI object
            $UpdateList = [wmi]"$($UpdateList.__PATH)"
            
            Write-Verbose "$($UpdateList.LocalizedDisplayName) has $($UpdateList.Updates.Count) updates in it"

            # For each update list object, iterate over update IDs and test if they are expired
            foreach ($UpdateId in $UpdateList.Updates)
            {
                # Write-Verbose "Testing if update ID $UpdateId is expired"
                
                # If update is expired, then remove it from the list of updates assigned to this update list
                if (Test-SccmUpdateExpired -SccmServer $SccmServer -UpdateId $UpdateId)
                {
                    $UpdateList.Updates = @($UpdateList.Updates | ? { $_ -ne $UpdateId })
                    Write-Verbose ("Update count is now: " + $UpdateList.Updates.Count)
                }
            }
            
            # Commit the Update List back to the SCCM provider
            $UpdateList.Put()
        }
        #endregion
        

        
        #region Clean up Update Assignments (Deployment Management)
        # Get a list of all Deployment Management objects that are owned by this SCCM site
        $UpdatesAssignments = Get-WmiObject -Namespace root\sms\site_$SccmSiteCode -Class SMS_UpdatesAssignment -ComputerName $SccmServer -Filter "SourceSite = '$SccmSiteCode'"

        # For each update assignment, get a list of CIs and filter out expired updates
        foreach ($UpdatesAssignment in $UpdatesAssignments)
        {
            $UpdatesAssignment = [wmi]"$($UpdatesAssignment.__PATH)"
            Write-Verbose "$($UpdatesAssignment.AssignmentName) has $($UpdatesAssignment.AssignedCIs.Count) updates in it"
            foreach ($UpdateId in $UpdatesAssignment.AssignedCIs)
            {
                # Write-Verbose "Testing if update ID $UpdateId is expired"
                
                # Test if the update is expired
                if (Test-SccmUpdateExpired -SccmServer $SccmServer -UpdateId $UpdateId)
                {
                    # Remove the update from the array of update IDs assigned to this updates assigment object
                    $UpdatesAssignment.AssignedCIs = @($UpdatesAssignment.AssignedCIs | ? { $_ -ne $UpdateId })
                    Write-Verbose ("Update count is now: " + $UpdatesAssignment.AssignedCIs.Count)
                }
            }
            
            # Write the modified updates assignment object back to the provider
            $UpdatesAssignment.Put();
        }
        #endregion
        

        #region Clean up Software Update Packages
        
        # Software packages are a little bit different from the other software updates objects. This is how the various objects relate:
        # SMS_SoftwareUpdate <-> SMS_CiToContent <-> SMS_PackageToContent <-> SMS_SoftwareUpdatesPackage
        # http://social.technet.microsoft.com/Forums/en-US/configmgrsdk/thread/fc68ced0-e39a-4ea2-b59d-c2efa2695b1d#fc68ced0-e39a-4ea2-b59d-c2efa2695b1d

        $ExpiredContentQuery = "select SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from SMS_SoftwareUpdate
                                join SMS_CIToContent on SMS_CIToContent.CI_ID = SMS_SoftwareUpdate.CI_ID
                                join SMS_PackageToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID
                                where SMS_SoftwareUpdate.IsExpired = 'true'"
        
        if ($PackageFilter)
        {
            $ExpiredContentQuery = $ExpiredContentQuery + " and SMS_PackageToContent.PackageID = '$($PackageFilter.PackageID)'"
        }

        $ExpiredContentList = $null
        $ExpiredContentList = @(Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -Query $ExpiredContentQuery)

        # For each update package, get a list of CIs and filter out expired updates
        foreach ($ExpiredContent in $ExpiredContentList)
        {
            Write-Host "Removing content ID $($ExpiredContent.ContentID) from package $($ExpiredContent.PackageID)"
            
            # Retrieve the instance of the Software Updates Package that contains the content
            $SoftwareUpdatesPackage = [wmi]"\\$SccmServer\root\sms\site_$($SccmSiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($ExpiredContent.PackageID)'"
            
            # Remove all expired updates based on their ID from the update package
            if ($SoftwareUpdatesPackage.RemoveContent($ExpiredContent.ContentID, $false).ReturnValue -eq 0)
            {
                Write-Host "Successfully removed $($ExpiredContent.ContentID) from $($ExpiredContent.PackageID)"
            }
        }

        if ($ExpiredContentList.Count -gt 0)
        {
            # Get a list of all software updates packages
            $SoftwareUpdatesPackages = Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -Class SMS_SoftwareUpdatesPackage
            
            # Update
            foreach ($SoftwareUpdatesPackage in $SoftwareUpdatesPackages)
            {
                if ($SoftwareUpdatesPackage.RefreshPkgSource().ReturnValue -eq 0)
                {
                    Write-Host ("Successfully refreshed package source for: " + $SoftwareUpdatesPackage.PackageID)
                }
            }
        }
        else
        {
            Write-Host "No expired content found in any packages. Skipping package refreshes."
        }
        #endregion
    }
}

function Test-SccmUpdateExpired
{
    param(
        [Parameter(Mandatory = $true)]
        $SccmServer,
        [Parameter(Mandatory = $false)]
        $SccmSiteCode,
        [Parameter(Mandatory = $true)]
        $UpdateId
    )

    # Get the SCCM site code for the server
    if (-not $SccmSiteCode) {
        $SccmSiteCode = (Get-SccmSiteCode $SccmServer)
    }

    # Find update that is expired with the specified CI_ID (unique ID) value
    $ExpiredUpdateQuery = "select * from SMS_SoftwareUpdate where IsExpired = 'true' and CI_ID = '$UpdateId'"
    $Update = @(Get-WmiObject -ComputerName $SccmServer -Namespace root\sms\site_$SccmSiteCode -Query $ExpiredUpdateQuery)
    
    # If the WMI query returns more than 0 instances (should NEVER be more than 1 at most), then the update is expired.
    if ($Update.Count -gt 0)
    {
        Write-Verbose ("Found an expired software update (KB$($Update[0].ArticleID)) with ID " + $Update[0].CI_ID )
        return $true
    }
    else
    {
        return $false
    }
}

Clear-Host
# Remove-SccmExpiredUpdates -SccmServer sccm1 -PackageFilter @{ PackageID = '00000007' }
Remove-SccmExpiredUpdates -SccmServer "sccm.ad.grcc.edu"