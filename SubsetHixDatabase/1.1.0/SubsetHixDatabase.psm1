<#

    .SYNOPSIS
        Vult een HiX database met gespecificeerde patientdata.

    .DESCRIPTION
        Vult een HiX database die via de Chipsoft HiX Clone tool aangemaakt is 
        met gespecificeerde patientdata vanuit specifieke tabellen en modules.

    .PARAMETER SourceSqlInstance
        Bron SQL Server Instance.
        De connectie naar de SQL Server Instance wordt opgezet doormiddel van
        Integrated Security, oftewel, de account waaronder deze functie gestart wordt.

    .PARAMETER SourceDatabase
        Bron database waaruit de patient gegevens geladen worden.

    .PARAMETER TargetSqlInstance
        Doel SQL Server Instance.
        De connectie naar de SQL Server Instance wordt opgezet doormiddel van
        Integrated Security, oftewel, de account waaronder deze functie gestart wordt.

    .PARAMETER TargetDatabase
        Doel database waarin de patient gegevens geimporteerd worden.

    .PARAMETER CloneInputFile
        Een JSON bestand welke de tabellen en de benodigde informatie bevat die gebruikt wordt op
        het inladen uit te voeren.

    .PARAMETER Timerange
        Het aantal dagen voor, of na, de huidige datum waarop een patient een afspraak of opname heeft gehad.
        Uit deze range van datums worden de dynamische patient nummers geselecteerd van welke de
        data gekopieerd wordt naar de doel database.

    .PARAMETER MaxNumberOfPatients
        Het maximaal aantal dynamische patient nummers die geselecteerd worden uit de datum range die
        bepaald is door de Timerange parameter. De selectie van deze patient nummers gebeurt
        willekeurig indien er meer patienten in de gespecificeerde Timerange aanwezig zijn dan er
        via de MaxNumberOfPatients parameter ingesteld zijn.

    .PARAMETER TruncateBeforeLoad
        Optionele parameter (standaard $false) welke ervoor zorgt dat de doel tabel voor
        het inladen van de patient data geleegd wordt.

    .PARAMETER ImportPatientIds
        Optionele parameter (standaard $false). Door deze parameter op $true te zetten worden
        zelf gespecificeerde patient nummers toegevoegd aan de lijst van patient nummers van
        welke de data gekopieerd wordt naar de doel database.
        Op het moment dat deze parameter op $true ingesteld staat dient ook de $PatientIdImportFile
        parameter gebruikt te worden.

    .PARAMETER PatientIdImportFile
        Optionele parameter. Geeft de locatie aan van het patient nummer import bestand.
        Elk patient nummer wat voorkomt in dit import bestand wordt toegevoegd aan de lijst van 
        patient nummers van welke de data gekopieerd wordt naar de doel database.
        Elke regel in het patient nummer import bestand dient een uniek patien nummer te zijn.

    .PARAMETER OnlyUseImportedPatientIds
        Optionele parameter (standaard $false). Door deze parameter op $true te zetten worden
        er geen dynamisch geselecteerde patient nummers geimporteerd en alleen de patient
        nummers die in het patient nummer import bestand staan gebruikt voor het inladen van
        gegevens naar de doel database.
        Op het moment dat deze parameter op $true staat moeten ook de ImportPatientIds op
        $true gezet zijn en de PatientIdImportFile parameter gevuld zijn.

    .PARAMETER Timeout
        Optionele parameter (standaard 0, oftewel geen timeout) welke de timeout in seconden aangeeft van elke 
        batch van het kopieer commando. Indien de batch meer tijd dan de timeout in beslag neemt
        wordt deze automatisch afgebroken.
        Door de Timeout op 0 te zetten wordt er geen timeout gebruikt.

    .PARAMETER ContinueOnError
        Optionele parameter (standaard $false). Door deze parameter op $true te zetten gaat
        het script bij sommige errors - zoals het inladen van data in de doel database - door 
        naar de volgende actie in plaats van af te breken.

    .PARAMETER DebugMode
        Optionele parameter (standaard $false). De DebugMode parameter retourneerd een aantal
        additionele gegevens naar de commandline die bruikbaar kunnen zijn voor het troubleshooten
        van eventuele fouten.

    .NOTES
        Author: E. van de Laar
        Versie: 1.1 (15-05-2025)
        Website: https://www.privinity.com
        Copyright: (C) Privinity, info@privinity.com
        License: GNU AGPL v3 https://www.gnu.org/licenses/agpl-3.0.txt

    .LINK
        https://github.com/Privinity/Chipsoft-HiX-Subset-Module

    .EXAMPLE
        Start-SubsetHixDatabase -SourceSqlInstance "SQL-BRON01" -SourceDatabase "HIX_BRON" -TargetSqlInstance "SQL-DOEL01" -TargetDatabase "HIX_CLONE" -CloneInputFile "C:\table_list.json" -Timerange 14 -MaxNumberOfPatients 100

        Kopieert de patientgegevens voor de gespecificeerde tabellen in het clone input bestand (C:\table_list.json) van de HIX_BRON database op de SQL-BRON01 server 
        naar de HIX_CLONE database op de SQL-DOEL01 server. Hierbij wordt de data van maximaal 100 patienten gebruikt die 14 dagen voor, of 14 dagen na, het uitvoeren
        van dit commando een afspraak of opname hebben gehad.

    .EXAMPLE
        Start-SubsetHixDatabase -SourceSqlInstance "SQL-BRON01" -SourceDatabase "HIX_BRON" -TargetSqlInstance "SQL-DOEL01" -TargetDatabase "HIX_CLONE" -CloneInputFile "C:\table_list.json" -Timerange 14 -MaxNumberOfPatients 100 -ImportPatientIds $true -PatientIdImportFile "C:\patientIds.txt"
        
        Kopieert de patientgegevens voor de gespecificeerde tabellen in het clone input bestand (C:\table_list.json) van de HIX_BRON database op de SQL-BRON01 server 
        naar de HIX_CLONE database op de SQL-DOEL01 server. Hierbij wordt de data van maximaal 100 patienten gebruikt die 14 dagen voor, of 14 dagen na, het uitvoeren
        van dit commando een afspraak of opname hebben gehad. Daarnaast wordt voor alle patientnummers die in het PatientIdImportFile bestand staan alle gegevens
        additioneel gekopieerd.

    .EXAMPLE
        Start-SubsetHixDatabase -SourceSqlInstance "SQL-BRON01" -SourceDatabase "HIX_BRON" -TargetSqlInstance "SQL-DOEL01" -TargetDatabase "HIX_CLONE" -CloneInputFile "C:\table_list.json" -Timerange 14 -MaxNumberOfPatients 100 -ImportPatientIds $true -PatientIdImportFile "C:\patientIds.txt" -OnlyUseImportedPatientIds $true
        
        Kopieert de patientgegevens voor de gespecificeerde tabellen in het clone input bestand (C:\table_list.json) van de HIX_BRON database op de SQL-BRON01 server 
        naar de HIX_CLONE database op de SQL-DOEL01 server. Door het instellen van de -OnlyUseImportedPatientIds parameter op $true worden alleen patientgegevens voor
        de patientnummers die in het PatientIdImportFile bestand staan gekopieerd.

#>

function Start-SubsetHixDatabase {    
   
    [CmdletBinding(DefaultParameterSetName = "Default", SupportsShouldProcess, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SourceSqlInstance,
        [Parameter(Mandatory=$true)]
        [string]$SourceDatabase,
        [Parameter(Mandatory=$true)]
        [string]$TargetSqlInstance,
        [Parameter(Mandatory=$true)]
        [string]$TargetDatabase,
        [Parameter(Mandatory=$true)]
        [string]$CloneInputFile,
        [Parameter(Mandatory=$true)]
        [int]$Timerange,
        [Parameter(Mandatory=$true)]
        [int]$MaxNumberOfPatients,
        [Parameter(Mandatory=$false)]
        [bool]$TruncateBeforeLoad = $false,
        [Parameter(Mandatory=$false)]
        [bool]$ImportPatientIds = $false,
        [Parameter(Mandatory=$false)]
        [string]$PatientIdImportFile = "",
        [Parameter(Mandatory=$false)]
        [bool]$OnlyUseImportedPatientIds = $false,
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 0,
        [Parameter(Mandatory=$false)]
        [bool]$ContinueOnError = $false,
        [Parameter(Mandatory=$false)]
        [bool]$DebugMode = $false
    )

    begin {

        # Define the LogMessage function
        function LogMessage
        {

            Param
            (
                [Parameter(Mandatory=$true, Position=0)]
                [string] $messsageType,
                [Parameter(Mandatory=$true, Position=1)]
                [string] $message,
                [Parameter(Mandatory=$false, Position=2)]
                [string] $exceptionMessage
            )

            # Set the current date/time
            $timestamp = Get-Date

            # Depending on the messageType change the log color
            switch ($messsageType) {
                "Info" {  
                    Write-Host "$timestamp - $message"
                }

                "Success" {  
                    Write-Host -f green "$timestamp - $message"
                }

                "Error" {
                    Write-host -f red "$timestamp - $message, foutmelding: $exceptionMessage"
                }

                "Debug" {
                    Write-host -f Blue "$timestamp - Debug: $message"
                }

                Default {}
            }

        }

        # Define the LoadIdentifiers function
        function LoadIdentifiers
        {

            Param
            (
                [Parameter(Mandatory=$true)]
                [string] $IdentifierCacheTable,
                [Parameter(Mandatory=$true)]
                [string] $SourceTable,
                [Parameter(Mandatory=$true)]
                [string] $IdentifierColumn,
                [Parameter(Mandatory=$true)]
                [string] $FilterColumn,
                [Parameter(Mandatory=$true)]
                [string] $FilterCacheTable
            )

            try {

                # Truncate the cache table for this specific identifier
                $queryTruncateIdentifierCacheTable = "TRUNCATE TABLE $IdentifierCacheTable"
                $cacheDbConnection.Open()
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryTruncateIdentifierCacheTable, $cacheDbConnection)
                $sqlCommand.ExecuteNonQuery() | Out-Null                        
                $cacheDbConnection.Close()       
                
                $queryCacheIdentifiers = "SELECT $IdentifierColumn FROM $SourceTable WHERE $FilterColumn IN (SELECT ID FROM HixSubsetCache.dbo.$FilterCacheTable) AND $IdentifierColumn <> '';"

                if($DebugMode -eq $true)
                {
                    LogMessage Debug "$queryCacheIdentifiers"
                }

                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryCacheIdentifiers, $srcDbConnection)                
                $srcDbConnection.Open()

                [System.Data.SqlClient.SqlDataReader]$sqlReader = $sqlCommand.ExecuteReader()
                
                # Set bulk copy options
                $sqlBulkCopy = New-Object -TypeName System.Data.SqlClient.SqlBulkCopy($cacheDbConnectionString, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity)
                $sqlBulkCopy.EnableStreaming = $true
                $sqlBulkCopy.DestinationTableName = $IdentifierCacheTable
                $sqlBulkCopy.BatchSize = $BatchSize 
                $sqlBulkCopy.BulkCopyTimeout = $Timeout 
                $sqlBulkCopy.ColumnMappings.Add($IdentifierColumn, "ID") > $null 
                                
                # Perform the bulk copy action
                $sqlBulkCopy.WriteToServer($sqlReader)                                

                return "success"

    
            }
            catch {
                LogMessage Error "Er is een fout opgetreden bij het inladen van identifiers voor de $SourceTable tabel vanuit de brondatabase die gebruikt worden voor de data kopie" -exceptionMessage $_.Exception.Message 
                return "error"
            }
            finally {
                # Close the connection
                $cacheDbConnection.Close()
                $srcDbConnection.Close()
            }

        }

        # Define the CopyFullHixTable function
        function CopyFullHixTable
        {

            Param
            (

                [Parameter(Mandatory=$true)]
                [string] $TableName,                
                [Parameter(Mandatory=$false)]
                [bool] $Timeout = 0,
                [Parameter(Mandatory=$false)]
                [bool]$ContinueOnError = $false,
                [Parameter(Mandatory=$false)]
                [bool]$DebugMode = $false

            )

            try {

                LogMessage Info "|- Start met kopieren volledige tabel $TableName "

                if ($PSCmdlet.ShouldProcess($TableName, "Executing bulk copy")) {                 

                    $timer = [System.Diagnostics.Stopwatch]::StartNew()                

                    # In some cases not all columns of a table are present on the cloned target database.
                    # For that reason we get the column names of the table in the *target database*.
                    # This way we do not get errors because of invalid column mappings
                    $queryGetTableColumns = "SELECT TOP 0 * FROM $TableName ;"
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryGetTableColumns, $targetDbConnection)
                    $srcDbConnection.Open()
                
                    $sqlAdapter = [System.Data.SqlClient.SqlDataAdapter]::new($sqlCommand)
                    $columnTable = New-Object System.Data.DataTable
                
                    $sqlAdapter.Fill($columnTable) | Out-Null
                
                    $srcDbConnection.Close()                   
                                                       
                    # Build the column selection string
                    $columnMappingString = ""

                    foreach ($column in $columnTable.Columns) 
                    { 

                        $columnMappingString = $columnMappingString + '[' + $column + '],'
                    }

                    # Remove the last ,
                    $columnMappingString = $columnMappingString.Substring(0, $columnMappingString.Length - 1)

                    # Check if the target table has an IDENTITY column
                    # If this is true we need to set IDENTITY_INSERT ON before the INSERT and OFF again when completed
                    $checkIdentityTable = "SELECT COUNT(*) AS 'IdentityEnabled' FROM sys.identity_columns WHERE [object_id] = OBJECT_ID('$TableName')"
                    $targetDbConnection.Open()
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($checkIdentityTable, $targetDbConnection)
                    $identityPresent = $sqlCommand.ExecuteScalar();
                    $targetDbConnection.Close() 
                    
                    # Perform the copy command
                    if($identityPresent -eq 0)
                    {
                        $copyFullTableQuery = "INSERT INTO $TargetDatabase.dbo.$TableName ($columnMappingString) SELECT $columnMappingString FROM $SourceDatabase.dbo.$TableName ;"
                    }
                    else 
                    {
                        $copyFullTableQuery = "SET IDENTITY_INSERT $TargetDatabase.dbo.$TableName ON; INSERT INTO $TargetDatabase.dbo.$TableName ($columnMappingString) SELECT $columnMappingString FROM $SourceDatabase.dbo.$TableName ; SET IDENTITY_INSERT $TargetDatabase.dbo.$TableName OFF;"    
                    }
                    
                    if($DebugMode -eq $true)
                    {
                        LogMessage Debug "$copyFullTableQuery"
                    }
                    
                    $targetDbConnection.Open()
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($copyFullTableQuery, $targetDbConnection)
                    $sqlCommand.CommandTimeout = $Timeout
                    $sqlCommand.ExecuteNonQuery() | Out-Null                        
                    $targetDbConnection.Close() 
                   
                    # Get the number of rows inserted
                    $insertedRowCount = "SELECT COUNT(*) FROM $TargetDatabase.dbo.$TableName"
                    $targetDbConnection.Open()
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($insertedRowCount, $targetDbConnection)
                    $rowsCopied = $sqlCommand.ExecuteScalar();
                    $targetDbConnection.Close() 
                
                    LogMessage Success "|- Doel tabel $TableName gevuld! Verwerkt aantal rijen: $rowsCopied, in $([math]::Round($timer.Elapsed.TotalSeconds,0)) seconden."

                }
                
                return $true                
                
            }
            catch {                

                LogMessage Error "|- Er is een fout opgetreden tijdens het vullen van de tabel $TableName" -exceptionMessage $_.Exception.Message                    

                return $false          
                
            }
            finally {
            
                # Stop the timer
                $timer.Stop()
            
            }

        }

        # Define the CopyHixTable function
        function CopyHixTable
        {

            Param
            (

                [Parameter(Mandatory=$true)]
                [string] $TableName,
                [Parameter(Mandatory=$true)]
                [string] $KeyColumn,
                [Parameter(Mandatory=$true)]
                [string] $IdCacheTable,
                [Parameter(Mandatory=$false)]
                [bool] $Timeout = 0,
                [Parameter(Mandatory=$false)]
                [bool]$ContinueOnError = $false,
                [Parameter(Mandatory=$false)]
                [bool]$DebugMode = $false

            )

            try {

                LogMessage Info "|- Start met kopieren patientdata vanuit $TableName "

                if ($PSCmdlet.ShouldProcess($TableName, "Executing bulk copy")) {                 

                    $timer = [System.Diagnostics.Stopwatch]::StartNew()       
                    
                    # In some cases not all columns of a table are present on the cloned target database.
                    # For that reason we get the column names of the table in the *target database*.
                    # This way we do not get errors because of invalid column mappings
                    $queryGetTableColumns = "SELECT TOP 0 * FROM $TableName ;"
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryGetTableColumns, $targetDbConnection)
                    $srcDbConnection.Open()                
                    $sqlAdapter = [System.Data.SqlClient.SqlDataAdapter]::new($sqlCommand)
                    $columnTable = New-Object System.Data.DataTable                
                    $sqlAdapter.Fill($columnTable) | Out-Null                
                    $srcDbConnection.Close()                   
                                                       
                    # Build the column selection string
                    $columnMappingString = ""

                    foreach ($column in $columnTable.Columns) 
                    { 
                        $columnMappingString = $columnMappingString + '[' + $column + '],'
                    }

                    # Remove the last ,
                    $columnMappingString = $columnMappingString.Substring(0, $columnMappingString.Length - 1) 
                    
                     # Check if the target table has an IDENTITY column
                    # If this is true we need to set IDENTITY_INSERT ON before the INSERT and OFF again when completed
                    $checkIdentityTable = "SELECT COUNT(*) AS 'IdentityEnabled' FROM sys.identity_columns WHERE [object_id] = OBJECT_ID('$TableName')"
                    $targetDbConnection.Open()
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($checkIdentityTable, $targetDbConnection)
                    $identityPresent = $sqlCommand.ExecuteScalar();
                    $targetDbConnection.Close()                 

                    # Perform the copy command
                    if($identityPresent -eq 0)
                    {
                        $copyHixTableQuery = "INSERT INTO $TargetDatabase.dbo.$TableName ($columnMappingString) SELECT $columnMappingString FROM $SourceDatabase.dbo.$TableName WHERE $KeyColumn IN (SELECT ID FROM HixSubsetCache.dbo.$IdCacheTable);"
                    }
                    else 
                    {
                        $copyHixTableQuery = "SET IDENTITY_INSERT $TargetDatabase.dbo.$TableName ON; INSERT INTO $TargetDatabase.dbo.$TableName ($columnMappingString) SELECT $columnMappingString FROM $SourceDatabase.dbo.$TableName WHERE $KeyColumn IN (SELECT ID FROM HixSubsetCache.dbo.$IdCacheTable); SET IDENTITY_INSERT $TargetDatabase.dbo.$TableName OFF;"
                    }                                                            

                    if($DebugMode -eq $true)
                    {
                        LogMessage Debug "$copyHixTableQuery"
                    }
                    
                    $targetDbConnection.Open()                                                   
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($copyHixTableQuery, $targetDbConnection)
                    $sqlCommand.CommandTimeout = $Timeout
                    $sqlCommand.ExecuteNonQuery() | Out-Null                        
                    $targetDbConnection.Close() 

                    # Get the number of rows inserted
                    $insertedRowCount = "SELECT COUNT(*) FROM $TargetDatabase.dbo.$TableName"
                    $targetDbConnection.Open()
                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($insertedRowCount, $targetDbConnection)
                    $sqlCommand.CommandTimeout = $Timeout
                    $rowsCopied = $sqlCommand.ExecuteScalar();
                    $targetDbConnection.Close() 
                
                    LogMessage Success "|- Doel tabel $TableName gevuld! Verwerkt aantal rijen: $rowsCopied, in $([math]::Round($timer.Elapsed.TotalSeconds,0)) seconden."

                }
                
                return $true                
                
            }
            catch {                

                LogMessage Error "|- Er is een fout opgetreden tijdens het vullen van de tabel $TableName" -exceptionMessage $_.Exception.Message                    

                return $false          
                
            }
            finally {        

                # Stop the timer
                $timer.Stop()
            
            }

        }        
    }

    process {

        # Clear the screen
        Clear-Host

        # Log the start message
        LogMessage Info "HiX Subset Database script is gestart!"
        LogMessage Info "--------------------------------------"

        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        # Validate some parameters
        if($OnlyUseImportedPatientIds -eq $true -and $ImportPatientIds -eq $false)
        {
            LogMessage Error "OnlyUserImportedPatientIds is enabled maar de optie ImportPatientIds is disabled. ImportPatientIds moet enabled zijn om OnlyUserImportedPatientIds te kunnen gebruiken"
            break;
        }

        if($ImportPatientIds -eq $true -and $PatientIdImportFile -eq "")
        {
            LogMessage Error "ImportPatientIds is enabled maar maar er is geen import file gedefinieerd via de PatientIdImportFile parameter"
            break;
        }

        if($Timerange -le 0)
        {
            LogMessage Error "Ongeldige Timerange opgegevens. Deze waarde moet groter zijn dan 0."
            break;
        }

        if($MaxNumberOfPatients -le 0)
        {
            LogMessage Error "Ongeldige MaxNumberOfPatients opgegevens. Deze waarde moet groter zijn dan 0."
            break;
        }

        # Test the connection to the source database
        try {

            LogMessage Info "Bron database connectie validatie gestart"
                        
            $srcDbConnectionString = "Data Source=$SourceSqlInstance;Integrated Security=SSPI;Initial Catalog=$SourceDatabase;"
            $srcDbConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection $srcDbConnectionString

            if ($PSCmdlet.ShouldProcess($srcDbConnectionString, "Checking connection to source database")) {
            
                # Open the connection to the source
                $srcDbConnection.Open()

            }

            LogMessage Success "Succesvol verbonden met de bron database $SourceDatabase op $SourceSqlInstance"

        }
        catch {
            LogMessage Error "Er is een fout opgetreden tijdens het verbinden naar de bron database" -exceptionMessage $_.Exception.Message
            break
        }
        finally {
            # Close the connection
            $srcDbConnection.Close()
        }

        # Test the connection to the target database
        try {

            LogMessage Info "Doel database connectie validatie gestart"
            
            $targetDbConnectionString = "Data Source=$TargetSqlInstance;Integrated Security=SSPI;Initial Catalog=$TargetDatabase;"
            $targetDbConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection $targetDbConnectionString

            if ($PSCmdlet.ShouldProcess($targetDbConnectionString, "Checking connection to target database")) {

                # Open the connection to the source
                $targetDbConnection.Open()

            }

            LogMessage Success "Succesvol verbonden met de doel database $TargetDatabase op $TargetSqlInstance"

        }
        catch {
            LogMessage Error "Er is een fout opgetreden tijdens het verbinden naar de doel database" -exceptionMessage $_.Exception.Message    
            break
        }
        finally {
            # Close the connection
            $targetDbConnection.Close()
        }

        # Test the connection to the subset cache database
        try {

            LogMessage Info "Subset Cache database connectie validatie gestart"
                        
            $cacheDbConnectionString = "Data Source=$SourceSqlInstance;Integrated Security=SSPI;Initial Catalog=HixSubsetCache;"
            $cacheDbConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection $cacheDbConnectionString

            if ($PSCmdlet.ShouldProcess($cacheDbConnectionString, "Checking connection to subset cache database")) {
            
                # Open the connection to the source
                $cacheDbConnection.Open()

            }

            LogMessage Success "Succesvol verbonden met de subset cache database HixSubsetCache op $SourceSqlInstance"

        }
        catch {
            LogMessage Error "Er is een fout opgetreden tijdens het verbinden naar de subset cache database" -exceptionMessage $_.Exception.Message
            break
        }
        finally {
            # Close the connection
            $cacheDbConnection.Close()
        }



        # Import the table_list.json file that contains the tables we are going to process
        LogMessage Info "Laad het clone input bestand"

        try {

            if ($PSCmdlet.ShouldProcess($CloneInputFile, "Importing table input file")) {
            
                $tableList = Get-Content $CloneInputFile | ConvertFrom-Json

                # Filter out the the tables we do not need to process
                $tablesToProcess = $tableList | Where-Object enabled -eq $true
                $tableMeasure = $tablesToProcess | Measure
                $tableCount = $tableMeasure.Count 

                LogMessage Info "$tableCount tabellen worden geimporteerd"

                LogMessage Success "Clone input bestand ($CloneInputFile) succesvol geimporteerd!"

            }

        }
        catch {
            LogMessage Error "Er is een fout opgetreden bij het importeren van het clone input bestand" -exceptionMessage $_.Exception.Message
            break
        }

         # If TruncateBeforeLoad is set to true we truncate all the target tables first
         if($TruncateBeforeLoad -eq $true) {

            try {

                if ($PSCmdlet.ShouldProcess("Truncate tables", "Truncating tables")) {

                    $uniqueTables = $tablesToProcess | Select-Object -Unique -Property table_name
    
                    LogMessage Info "TruncateBeforeLoad is enabled. Start het legen van de doel tabellen"
    
                    foreach($truncateTable in $uniqueTables) {  
    
                        $truncateTableName = $truncateTable.table_name
    
                        $queryTruncateTargetTable = "TRUNCATE TABLE $truncateTableName ;"
    
                        $targetDbConnection.Open()
                        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryTruncateTargetTable, $targetDbConnection)
                        $sqlCommand.ExecuteNonQuery() | Out-Null                        
                        $targetDbConnection.Close()

                        LogMessage Success "|- Truncate op $truncateTableName uitgevoerd."                        
    
                    }
    
                }
                
            }
            catch {
                LogMessage Error "Er is een fout opgetreden bij het legen van de doel tabellen" -exceptionMessage $_.Exception.Message
                break
                
            }

        }

        # Step 1a: Perform the selection of patient ID's which we use to populate our tables
        # This step *always* has to happen first since most tables are build on the patientids
        # we gather in this step.
        # An exception is when we supply the OnlyUserImportedPatientIds parameter. In that case
        # only the patient id's that are supplied in the PatientIdImportFile are used for data selection.

        # Define our datatable to hold our patient id's
        $patientIdTable = New-Object System.Data.DataTable
        $idColumn = New-Object System.Data.DataColumn "PATIENTNR",([string])
        $patientIdTable.Columns.Add($idColumn) | Out-Null

        try {

            # Truncate the subsetPatientIds table
            $queryTruncatePatIdentifierCache = "TRUNCATE TABLE subsetPatientIds"
            $cacheDbConnection.Open()
            $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryTruncatePatIdentifierCache, $cacheDbConnection)
            $sqlCommand.ExecuteNonQuery() | Out-Null                        
            $cacheDbConnection.Close()
            
        }
        catch {
            LogMessage Error "Er is een fout opgetreden bij het opschonen van de patientID cache tabel" -exceptionMessage $_.Exception.Message
            break
        }
        

        # If OnlyUseImportedPatientIds is set to $false it means we have to grab patient id's from the
        # database itself using the parameters supplied
        if($OnlyUseImportedPatientIds -eq $false)
        {

            LogMessage Info "Start met het dynamisch ophalen van patient nummers met een timerange van $Timerange en een maximum aantal van $MaxNumberOfPatients"

            try {                        
                
                $queryGetPatientIds = ";WITH cte AS (SELECT DISTINCT(PATIENTNR) FROM AGENDA_AFSPRAAK WHERE DATEDIFF(DAY, GETDATE(), DATUM) BETWEEN -$Timerange AND $Timerange UNION SELECT DISTINCT(PATIENTNR) FROM OPNAME_OPNAME WHERE DATEDIFF(DAY, GETDATE(), OPNDAT) BETWEEN -$Timerange AND $Timerange) SELECT TOP $MaxNumberOfPatients * FROM cte ORDER BY NEWID();"

                if ($PSCmdlet.ShouldProcess($queryGetPatientIds, "Loading patient ID's for which we are copying the data")) {

                    $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryGetPatientIds, $srcDbConnection)
                    $srcDbConnection.Open()

                    $sqlAdapter = [System.Data.SqlClient.SqlDataAdapter]::new($sqlCommand)                    

                    $sqlAdapter.Fill($patientIdTable) | Out-Null    

                    LogMessage Success "Dynamische patient nummers succesvol geimporteerd!"
                    
                }

            }
            catch {
                LogMessage Error "Er is een fout opgetreden bij het inladen van patient nummers vanuit de brondatabase die gebruikt worden voor de data kopie" -exceptionMessage $_.Exception.Message
                break
            }
            finally {
                # Close the connection
                $srcDbConnection.Close()
            }

        }

        # Step 1b: Import manually supplied patientIds from the specified import file if ImportPatientIds is set to $true
        if($ImportPatientIds -eq $true)
        {

            try {
                
                LogMessage Info "Start laden patientId import bestand"

                if ($PSCmdlet.ShouldProcess($PatientIdImportFile, "Loading patientId import file")) {

                    $importPatients = Get-Content $PatientIdImportFile                    

                    foreach($patientImportId in $importPatients)
                    {
                        $patientRow = $patientIdTable.NewRow()
                        $patientRow["PATIENTNR"] = $patientImportId
                        $patientIdTable.Rows.Add($patientRow)                        
                    }

                    LogMessage Success "PatientId import bestand ($PatientIdImportFile) succesvol geimporteerd!"

                }

            }
            catch {                    
                LogMessage Error "Er is een fout opgetreden bij het laden van het patientId import file" -exceptionMessage $_.Exception.Message
                break                    
            }

        }

        # Step 1c: Write the patientId's to a table in the subset cache database  
        try {
            
            foreach($patientId in $patientIdTable)
            {      

                $patientIdValue = $patientId.PATIENTNR                

                $queryCachePatientId = "INSERT INTO subsetPatientIds (ID) VALUES ($patientIdValue)"

                $cacheDbConnection.Open()
                $sqlCommand = New-Object System.Data.SqlClient.SqlCommand($queryCachePatientId, $cacheDbConnection)
                $sqlCommand.ExecuteNonQuery() | Out-Null                        
                $cacheDbConnection.Close()                
            }            

        }
        catch { 
            LogMessage Error "Er is een fout opgetreden bij opbouwen van de patientId selectie" -exceptionMessage $_.Exception.Message
            break  
        }

        # Return how many patient id's we've imported in total
        $dynamicPatientIdsLoaded = $patientIdTable.Rows.Count;      
        LogMessage Success "Patientnummers zijn succesvol ingeladen. Er zijn $dynamicPatientIdsLoaded patientnummers geladen"


        # Step 2: Load the identifiers of the secondary tables
        # a. DocumentIds
        if ($PSCmdlet.ShouldProcess("Document IDs", "Loading secondary identifiers")) {
            
            $documentIdString = LoadIdentifiers -IdentifierCacheTable "subsetDocumentIds" -SourceTable "WI_DOCUMENT" -IdentifierColumn "ID" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($documentIdString -eq "error")
            {
                break
            }
        }
        
        # b. AfspraakIds
        if ($PSCmdlet.ShouldProcess("Appointment IDs", "Loading secondary identifiers")) {

            $afspraakIdString = LoadIdentifiers -IdentifierCacheTable "subsetAfspraakIds" -SourceTable "AGENDA_AFSPRAAK" -IdentifierColumn "AFSPRAAKNR" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($afspraakIdString -eq "error")
            {
                break
            }

        }

        # c. MicrobiologieIds
        if ($PSCmdlet.ShouldProcess("Microbiology IDs", "Loading secondary identifiers")) {

            $mbIdString = LoadIdentifiers -IdentifierCacheTable "subsetMmbIds" -SourceTable "BACLAB_PA_OND" -IdentifierColumn "ONDERZNR" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($mbIdString -eq "error")
            {
                break
            }

        }

        # d. LabIds
        if ($PSCmdlet.ShouldProcess("Lab IDs", "Loading secondary identifiers")) {

            $labIdString = LoadIdentifiers -IdentifierCacheTable "subsetLabIds" -SourceTable "LAB_L_AANVRG" -IdentifierColumn "AANVRAAGNR" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($labIdString -eq "error")
            {
                break
            }

        }

        # e. DocumentBlobIds
        if ($PSCmdlet.ShouldProcess("Document BLOB IDs", "Loading secondary identifiers")) {

            $documentBlobIdString = LoadIdentifiers -IdentifierCacheTable "subsetDocBlobIds" -SourceTable "WI_DOCUMENT" -IdentifierColumn "BLOBID" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($documentBlobIdString -eq "error")
            {
                break
            }

        }

        # f. MultimediaBlobIds
        if ($PSCmdlet.ShouldProcess("Multimedia BLOB IDs", "Loading secondary identifiers")) {

            $multimediaBlobIdString = LoadIdentifiers -IdentifierCacheTable "subsetMMBlobIds" -SourceTable "MULTIMED_MULTMDOC" -IdentifierColumn "BLOBID" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($multimediaBlobIdString -eq "error")
            {
                break
            }

        }

        # g. OpnamePlanIds
        if ($PSCmdlet.ShouldProcess("Admission IDs", "Loading secondary identifiers")) {

            $opnamePlanIdString = LoadIdentifiers -IdentifierCacheTable "subsetOpnameIds" -SourceTable "OPNAME_OPNAME" -IdentifierColumn "PLANNR" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($opnamePlanIdString -eq "error")
            {
                break
            }

        }

        # h. OrderIds
        if ($PSCmdlet.ShouldProcess("Order IDs", "Loading secondary identifiers")) {

            $orderIdString = LoadIdentifiers -IdentifierCacheTable "subsetOrderIds" -SourceTable "ORDERCOM_ORDER" -IdentifierColumn "ORDERNR" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($orderIdString -eq "error")
            {
                break
            }

        }

        # i. PathologieIds
        if ($PSCmdlet.ShouldProcess("Pathology IDs", "Loading secondary identifiers")) {

            $pathoIdString = LoadIdentifiers -IdentifierCacheTable "subsetPathoIds" -SourceTable "PATHO_PA_OND" -IdentifierColumn "ONDERZNR" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($pathoIdString -eq "error")
            {
                break
            }

        }    
        
        # j. OperatieIds
        if ($PSCmdlet.ShouldProcess("Operation IDs", "Loading secondary identifiers")) {

            $operatieIdString = LoadIdentifiers -IdentifierCacheTable "subsetOkIds" -SourceTable "OK_OKINFO" -IdentifierColumn "OPERATIENR" -FilterColumn "OPNAMENR" -FilterCacheTable "subsetOpnameIds"

            if($operatieIdString -eq "error")
            {
                break
            }

        }  

        # k. SehIds
        if ($PSCmdlet.ShouldProcess("SEH IDs", "Loading secondary identifiers")) {

            $sehIdString = LoadIdentifiers -IdentifierCacheTable "subsetSehIds" -SourceTable "SEH_SEHREG" -IdentifierColumn "SEHID" -FilterColumn "PATIENTNR" -FilterCacheTable "subsetPatientIds"

            if($sehIdString -eq "error")
            {
                break
            }

        }  

        # Now that we have all the data we need we can start with the copying of the data 
        # we can start with the copying of the data between the source and target
        LogMessage Info "Start met het kopieren van patient data"

        # Set a counter to keep track how far we are in the process
        $tableCurrentCounter = 1
        $errorCounter = 0

        # For each table that is set to enabled in the table_list
        foreach($table in $tablesToProcess) {     

            $tableName = $table.table_name
            $tableKeyColumn = $table.key_column
            $tableColumnClass = $table.key_column_class            
            
            # Calculate the current progress based on the number of tables we have to process
            $currentProgress = [math]::Round(($tableCurrentCounter / $tableCount * 100), 0)        
            
            # Show the progress
            Write-Progress -Activity "Kopieren patient data: $tableName" -Status "$currentProgress% Complete: " -PercentComplete $currentProgress
        
            # Start the CopyHixTable function
            # Depending on the tableColumnClass we provide a different set of Id's which are generated based the primary table
            switch($tableColumnClass)
            {

                "patientnr"
                {
                    # Load the tables that are based on the patient id as identifier       
                    if($patientIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetPatientIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode                                
                    }
                    
                }

                "documentid"
                {
                    # Load the tables that are based on the document id as identifier
                    if($documentIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetDocumentIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "afspraakid"
                {
                    # Load the tables that are based on the afspraak id as identifier
                    if($afspraakIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetAfspraakIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "mbid"
                {
                    # Load the tables that are based on the microbiology id as identifier
                    if($mbIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetMmbIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "pathoid"
                {
                    # Load the tables that are based on the pathology id as identifier
                    if($pathoIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetPathoIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "labid"
                {
                    # Load the tables that are based on the lab id as identifier
                    if($labIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetLabIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "documentblobid"
                {
                    # Load the tables that are based on the document blob id as identifier
                    if($documentBlobIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetDocBlobIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "multimediablobid"
                {
                    # Load the tables that are based on the multimedia blob id as identifier
                    if($multimediaBlobIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetMMBlobIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "opnameplanid"
                {
                    # Load the tables that are based on the opnameplan id as identifier
                    if($opnamePlanIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetOpnameIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }

                "orderid"
                {
                    # Load the tables that are based on the patientid as identifier                     
                    if($orderIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetOrderIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }    
                
                "operatieid"
                {
                    # Load the tables that are based on the order id as identifier
                    if($operatieIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetOkIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode            
                    }
                }  
                
                "sehid"
                {
                    # Load the tables that are based on the seh id as identifier
                    if($sehIdString -eq "")
                    {
                        LogMessage Error "Deze kopie actie verwacht identifiers van het type $tableColumnClass maar er zijn geen identifiers voor dit type gevonden in de bron database"
                        $copySuccess = $false
                    }
                    else 
                    {
                        $copySuccess = CopyHixTable -TableName $tableName -KeyColumn $tableKeyColumn -IdCacheTable "subsetSehIds" -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode                
                    }
                    
                }  

                "fulltable"
                {                   
                    # Load the tables that need to be copied in their entirety 
                    $copySuccess = CopyFullHixTable -TableName $tableName -Timeout $Timeout -ContinueOnError $ContinueOnError -DebugMode $DebugMode                
                }

                Default {}
                

            }

            # Wait for a second to avoid timeouts
            Start-Sleep -Seconds 1

            # If we run into an error during the copy add the error to the errorCounter
            if($copySuccess -eq $false) 
            {                      
                $errorCounter++

                # If ContinueOnError is set to false stop the processing of further actions
                if($ContinueOnError -eq $false)
                {
                    break
                }
                
            }

           

            $tableCurrentCounter++
        }       

        # Depending wether or not we ran into errors show the completion message
        if($errorCounter -gt 0)
        {
            # We encountered an error during execution
            LogMessage Error "$errorCounter error(s) is/zijn opgetreden tijdens het uitvoeren van het HiX Subset Database script. Controleer de logging om deze errors in te zien."
        }
        else 
        {
            # Everything has executed successfully
            LogMessage Success "HiX Subset Database script is succesvol uitgevoerd! Runtime $([math]::Round($timer.Elapsed.TotalMinutes,0)) minuten."
        }

        # Stop the timer
        $timer.Stop()

    }

}
