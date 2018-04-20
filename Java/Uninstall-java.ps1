(gwmi win32_product | where {($_.Name -match "JAVA 8") -or ($_.Name -match "JAVA 7")}).UNINSTALL()


