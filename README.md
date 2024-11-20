# Chipsoft HiX Subset Powershell Module
De Chipsoft HiX Subset Module is een Powershell module welke het mogelijk maakt om een gekloonde Chipsoft HiX database te vullen met patiënt gegevens vanuit een - zelf te specificeren - Chipsoft HiX database. Zo kun je makkelijk en snel verkleinde Chipsoft HiX omgevingen aanmaken zonder dat je hiervoor vele terabytes aan ruimte per omgeving nodig hebt 🚀!

## Ondersteunde Chipsoft versies
Op dit moment is de module ontwikkeld en getest op basis van **Chipsoft HiX 6.3**.
Naar alle waarschijnlijkheid functioneert de module ook op Chipsoft HiX 6.2 maar dit is nog niet getest.

## Installatie

1. Start een nieuwe Powershell sessie / terminal.
2. Identificeer de Powershell Module locatie door het volgende commando uit te voeren: `$Env:PSModulePath`.
3. Download en kopieer de gehele **SubsetHixDatabase** map naar een van deze locaties. Indien je wilt dat alle gebruikers op de machine de module kunnen gebruiken gebruik dan het pad **C:\Program Files\WindowsPowerShell\Modules** (Windows) of **/usr/local/microsoft/powershell/7/Modules** (Linux/Mac).
4. Importeer de module via het commando `Import-module -Name SubsetHixDatabase`.
5. Vanaf nu kun je de module gebruiken. Een handig commando om snel een overzicht van de verschillende parameters, als ook voorbeelden te zien, is `Get-Help Start-SubsetHixDatabase -Detailed`.

## Benodigdheden voor uitvoeren module
De module is gericht om patiënt gegevens uit een gevulde Chipsoft HiX database in te laden naar een gekloonde Chipsoft HiX omgeving. Deze module richt zich *alleen* op patiënt gegevens en niet op het importeren van inrichtingen, rechten, etc.

Om de inrichting, rechten, etc in een lege Chipsoft HiX database te laden, adviseren we je om gebruik te maken van de Chipsoft Clone Content tool. Deze tool wordt meegeleverd met de Database Updater software en de documentatie is op te vragen bij Chipsoft.

De Chipsoft Clone Content tool vult een een lege database met alle inrichtingstabellen en is dus een ideale manier om een Chipsoft HiX omgeving aan te maken die technisch functioneert maar nog geen patiëntgegevens bevat.

Nadat je de Chipsoft Clone Content tool en de Database Updater uitgevoert hebt om een nieuwe, lege, Chipsoft HiX omgeving aan te maken kun je vervolgens deze module gebruiken om deze lege omgeving te vullen met specifieke patiënt gegevens.

De module maakt gebruik van de SQL Server Bulk Copy functionaliteit. Om die reden moeten de SQL Server client tools geïnstalleerd zijn op de machine waarop de module uitgevoerd wordt. Normaal gesproken worden de benodigde binaries geïnstalleerd samen met SQL Server Management Studio.


## Hoe de module functioneert
Bij het uitvoeren van de module wordt er een verbinding opgezet naar de bron database (waarin de patiënt data staat) en naar de doel database (waarin de patiënt data ingeladen moet worden.) Via SQL Bulk Copy commando's wordt vervolgens de data van de bron naar de doel database geladen. 

De data die standaard ingeladen wordt, wordt bepaald aan de hand van twee parameters: `$Timerange` en `$MaxNumberOfPatients`. De `$Timerange` parameter bepaald hoe recent de data van een patiënt moet zijn (in dagen) om geselecteerd te worden voor de inlaad actie. Bijvoorbeeld: een `$Timerange` waarde van **14** selecteert alle unieke patiënt nummers die in de afgelopen 14 dagen, of 14 dagen in de toekomst, een afspraak of opname hebben (gehad). Via de `$MaxNumberOfPatients` parameter kun je vervolgens het aantal patiënten beperken tot een maximum, bijvoorbeeld **100**. Met deze voorbeeld instellingen worden 100 willekeurige patiënten geselecteerd die in de afgelopen 14 dagen, of 14 dagen in de toekomst, een afspraak of opname hebben (gehad). Voor deze patiënten wordt vervolgens de data vanuit de tabellen die in het table import bestand staan ingeladen.

De selectie van patiënten kan uitgebreid worden door gebruik te maken van het PatientIds import bestand. Hierin kun je patiënt nummers plaatsen die additioneel toegevoegd worden aan de selectie van patiënten. Dit is bijvoorbeeld handig als je ook altijd alle gegevens van testpatiënten wil inladen.

## Configuratie mogelijkheden
Voor het gebruik van de module worden er twee aparte bestanden gebruikt die als input dienen voor de uitvoering van het subsetten. Een hiervan is verplicht (het tabel import bestand), een andere optioneel (import bestand met een vaste lijst aan patiëntnummers).

### Tabel import bestand
Het table import bestand (standaard **table_list.json**) bevat alle tabellen en sleutelkolommen die door de module ingeladen worden bij het uitvoeren van de module. Deze zijn vastgelegd in het volgende formaat:

```
{
    "table_name": "AGENDA_AFSPRAAK",
    "hix_module": "AGENDA",
    "key_column": "PATIENTNR",
    "key_column_class": "patientnr",    
    "enabled": false
}
```

- Het **table_name** element is de naam van de tabel die ingeladen gaat worden.
- Het **hix_module** element geeft de naam van de Chipsoft HiX module aan waar de tabel onder valt.
- Het **key_column** element is de sleutelkolom van de tabel waarop gegevens gefilterd worden.
- Het **key_column_class** element geeft aan wat voor soort sleutel er gebruikt moet worden om filter uit te voeren.
- Het **enabled** element geeft aan of deze tabel ingeladen moet worden bij het uitvoeren van het commando. Een waarde van `true` zorgt ervoor dat de tabel ingeladen wordt, `false` dat deze niet ingeladen gaat worden.

Je kan zelf tabellen toevoegen en verwijderen in het table import bestand. Deze worden dan meegenomen op het moment dat je de module uitvoert. Hierbij is het wel van belang dat je weet wat de sleutelwaarde van de tabel is die je wil importeren. Aan de hand hiervan wordt namelijk de selectie gemaakt van gegevens die geimporteerd worden.

### Meer over de key_column en key_column_class elementen
In veel Chipsoft HiX tabellen is het patiëntnummer het sleutelveld waarop gegevens geimporteerd worden richting de gekloonde database. In veel tabellen heet deze kolom **PATIENTNR** en dat is dus ook vaak de waarde van de **key_column** element in het table import bestand. Indien een patiëntnummer het sleutelveld van een tabel is dan hoort daar een **key_column_class** van **patientnr** bij. Door deze elementen zo te configuren weet de module dat deze gegevens in de brontabel moet selecteren op basis van patiëntnummers die gebruikt worden in de filter op de **PATIENTNR** kolom. 

Niet alle tabellen in een Chipsoft HiX database hebben echter het patiëntnummer als sleutelveld. Een voorbeeld hiervan is de **WI_DOCASCII** tabel welke een platte tekst voorbeeld van een document bevat. Deze tabel heeft als sleutelveld een ID van een document. Om ook deze gegevens te kunnen importeren maken we gebruik van een andere **key_column** en **key_column_class** waarde zodat de module weet dat hier andere waarden dan het patiëntnummer gebruikt moeten worden om de gegevens te filteren. 
Het onderstaande voorbeeld is hoe de configuratie er voor de **WI_DOCASCII** eruit ziet in het table import bestand:

```
{
    "table_name": "WI_DOCASCII",
    "hix_module": "DOCUMENT",
    "key_column": "DOCID",
    "key_column_class": "documentid",    
    "enabled": true
}
```

In dit geval wordt dus de kolom **DOCID** gebruikt om documenten te selecteren die geimporteerd worden naar de gekloonde omgeving. Door als **key_column_class** de waarde **document_id** te gebruiken weet de module dat hier de ID's van documenten gebruikt moeten worden om rijen in de **WI_DOCASCII** tabel te filteren.

Het ophalen van de ID's voor deze sleutelkolom typen is hard-coded in de module en op dit moment worden de volgende ID typen ondersteund:

- Patiënt ID's (`patientnr`)
- Document ID's (`documentid`)
- Afspraak ID's (`afspraakid`)
- Microbiologie ID's (`mbid`)
- Pathologie ID's (`pathoid`)
- Lab ID's (`labid`)
- Order ID's (`orderid`)
- Document BLOB ID's (`documentblobid`)
- Multimedia BLOB ID's (`multimediablobid`)
- Opname Plan ID's (`opnameplanid`)
- Operatie ID's (`operatieid`)
- SEH ID's (`sehid`)

### PatientIDs import bestand
Het PatientIDs import bestand is een .txt bestand welke het mogelijk maakt om de patiënt ID's van specifieke patiënten te configureren die - afhankelijk van de parameter `ImportPatientIds` - meegenomen worden bij het importeren van de data van deze patiënten. Een use-cases hiervoor is om ervoor te zorgen dat de data van testpatiënten altijd ingeladen worden in de gekloonde Chipsoft HiX database. In dit geval zorg je ervoor dat de patiënt ID's van je testpatiënten in het PatientIDs import bestand staan.

De module verwacht op elke regelen in het PatientIDs import bestand één uniek patiëntnummer. Bijvoorbeeld:

```
12345678
87654321
```

### Parameters

- `$SourceSqlInstance`: Bron SQL Server Instance. De connectie naar de SQL Server Instance wordt opgezet doormiddel van Integrated Security, oftewel, de account waaronder deze functie gestart wordt.

- `$SourceDatabase`: Bron database waaruit de patient gegevens geladen worden.

- `$TargetSqlInstance`: Doel SQL Server Instance. De connectie naar de SQL Server Instance wordt opgezet doormiddel van Integrated Security, oftewel, de account waaronder deze functie gestart wordt.

- `$TargetDatabase`: Doel database waarin de patient gegevens geimporteerd worden.

- `$CloneInputFile`: Een JSON bestand welke de tabellen en de benodigde informatie bevat die gebruikt wordt op het inladen uit te voeren.

- `$Timerange`: Het aantal dagen voor, of na, de huidige datum waarop een patient een afspraak of opname heeft gehad. Uit deze range van datums worden de dynamische patient nummers geselecteerd van welke de data gekopieerd wordt naar de doel database.

- `$MaxNumberOfPatients`: Het maximaal aantal dynamische patient nummers die geselecteerd worden uit de datum range die bepaald is door de Timerange parameter. De selectie van deze patient nummers gebeurt willekeurig indien er meer patienten in de gespecificeerde Timerange aanwezig zijn dan er via de MaxNumberOfPatients parameter ingesteld zijn.

- `$TruncateBeforeLoad`:  Optionele parameter (standaard *false* welke ervoor zorgt dat de doel tabel voor het inladen van de patient data geleegd wordt.

- `$ImportPatientIds`: Optionele parameter (standaard *false* Door deze parameter op *true* te zetten worden zelf gespecificeerde patient nummers toegevoegd aan de lijst van patient nummers van welke de data gekopieerd wordt naar de doel database. Op het moment dat deze parameter op *true* ingesteld staat dient ook de **PatientIdImportFile** parameter gebruikt te worden.

- `$PatientIdImportFile`: Optionele parameter. Geeft de locatie aan van het patient nummer import bestand. Elk patient nummer wat voorkomt in dit import bestand wordt toegevoegd aan de lijst van patient nummers van welke de data gekopieerd wordt naar de doel database. Elke regel in het patient nummer import bestand dient een uniek patien nummer te zijn.

- `$OnlyUseImportedPatientIds`: Optionele parameter (standaard *false* Door deze parameter op *true* te zetten worden er geen dynamisch geselecteerde patient nummers geimporteerd en alleen de patient nummers die in het patient nummer import bestand staan gebruikt voor het inladen van gegevens naar de doel database. Op het moment dat deze parameter op *true* staat moeten ook de **ImportPatientIds** op *true* gezet zijn en de **PatientIdImportFile** parameter gevuld zijn.

- `$BatchSize`: Optionele paramater (standaard 10000) welke de grote van de kopie batch aangeeft.

- `$Timeout`:  Optionele parameter (standaard 60) welke de timeout in seconden aangeeft van elke batch van het kopieer commando. Indien de batch meer tijd dan de timeout in beslag neemt wordt deze automatisch afgebroken. Door de Timeout op 0 te zetten wordt er geen timeout gebruikt.

- `$ContinueOnError`: Optionele parameter (standaard *false*). Door deze parameter op *true* te zetten gaat het script bij sommige errors - zoals het inladen van data in de doel database - door naar de volgende actie in plaats van af te breken.

- `$DebugMode`: Optionele parameter (standaard *false*). De DebugMode parameter retourneerd een aantal additionele gegevens naar de commandline die bruikbaar kunnen zijn voor het troubleshooten van eventuele fouten.

## Voorbeeld commando's

### Volledige omschrijving van alle parameters
Toont alle informatie, inclusief parameter omschrijvingen en voorbeelden, over de Chipsoft HiX Subset module.

`Get-Help Start-SubsetHixDatabase -Detailed`

### Subset actie uitvoeren met dynamisch geselecteerde patiënten
Kopieert de patientgegevens voor de gespecificeerde tabellen in het clone input bestand (C:\table_list.json) van de HIX_BRON database op de SQL-BRON01 server naar de HIX_CLONE database op de SQL-DOEL01 server. Hierbij wordt de data van maximaal 100 patienten gebruikt die 14 dagen voor, of 14 dagen na, het uitvoeren van dit commando een afspraak of opname hebben gehad.

`Start-SubsetHixDatabase -SourceSqlInstance "SQL-BRON01" -SourceDatabase "HIX_BRON" -TargetSqlInstance "SQL-DOEL01" -TargetDatabase "HIX_CLONE" -CloneInputFile "C:\table_list.json" -Timerange 14 -MaxNumberOfPatients 100`

### Subset actie uitvoeren met dynamisch geselecteerde en vooraf gedefinieerde patiënten
Kopieert de patientgegevens voor de gespecificeerde tabellen in het clone input bestand (C:\table_list.json) van de HIX_BRON database op de SQL-BRON01 server naar de HIX_CLONE database op de SQL-DOEL01 server. Hierbij wordt de data van maximaal 100 patienten gebruikt die 14 dagen voor, of 14 dagen na, het uitvoeren van dit commando een afspraak of opname hebben gehad. Daarnaast wordt voor alle patientnummers die in het PatientIdImportFile bestand staan alle gegevens additioneel gekopieerd.

`Start-SubsetHixDatabase -SourceSqlInstance "SQL-BRON01" -SourceDatabase "HIX_BRON" -TargetSqlInstance "SQL-DOEL01" -TargetDatabase "HIX_CLONE" -CloneInputFile "C:\table_list.json" -Timerange 14 -MaxNumberOfPatients 100 -ImportPatientIds $true -PatientIdImportFile "C:\patientIds.txt"`

### Subset actie uitvoeren met alleen vooraf gedefinieerde patiënten
Kopieert de patientgegevens voor de gespecificeerde tabellen in het clone input bestand (C:\table_list.json) van de HIX_BRON database op de SQL-BRON01 server naar de HIX_CLONE database op de SQL-DOEL01 server. Door het instellen van de **-OnlyUseImportedPatientIds** parameter op *$true* worden alleen patientgegevens voor de patientnummers die in het PatientIdImportFile bestand staan gekopieerd.

`Start-SubsetHixDatabase -SourceSqlInstance "SQL-BRON01" -SourceDatabase "HIX_BRON" -TargetSqlInstance "SQL-DOEL01" -TargetDatabase "HIX_CLONE" -CloneInputFile "C:\table_list.json" -Timerange 14 -MaxNumberOfPatients 100 -ImportPatientIds $true -PatientIdImportFile "C:\patientIds.txt" -OnlyUseImportedPatientIds $true`

## Ondersteuning
De Chipsoft HiX Subset Module is een opensource initatief wat we met veel zorg hebben geprobeerd te ontwikkelen en te testen. Toch kan er uiteraard een bug in de code sluipen of een functionaliteit ontbreken. Meld deze vooral aan via de **Issues** optie op deze GitHub pagina. We proberen dan zo snel mogelijk te reageren.

Mocht je na het gebruik van de Chipsoft HiX Subset Module erachter komen dat er nog gegevens gebruiken en weten in welke tabellen deze te vinden zijn? Maak ook dan een issue aan en dan voegen we de tabellen toe aan de het tabel import bestand!

## Disclaimer
De Chipsoft HiX Subset Module is een oplossing die ontwikkeld is om een antwoord de geven op de vraag vanuit ziekenhuizen om met een kleinere set van data meerdere Chipsoft HiX omgevingen te kunnen uitrollen en gebruiken voor ontwikkel- en testdoeleinden. De module is niet door Chipsoft ontwikkeld en draagt puur de naam Chipsoft en HiX om duidelijk aan te geven op welk product deze oplossing van toepassing is. 

Al het gebruik van de Chipsoft HiX Subset Module is op eigen risico. Zowel Privinity als de originele auteur van de code kan niet aansprakelijk worden gesteld voor enige schade die onstaat uit het gebruik van de module.

## Licentie
De GNU Affero General Public License Versie 3 (AGPL 3) is van toepassing op dit project.
De inhoud van deze licentie is te vinden in de [license file](https://github.com/Privinity/Chipsoft-HiX-Subset-Module?tab=AGPL-3.0-1-ov-file#readme).
