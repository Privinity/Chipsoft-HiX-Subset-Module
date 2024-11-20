# Chipsoft HiX Subset Powershell Module
De Chipsoft HiX Subset Module is een Powershell module welke het mogelijk maakt om een gekloonde Chipsoft HiX database te vullen met patiënt gegevens vanuit een - zelf te specificeren - Chipsoft HiX database.

## Ondersteunde Chipsoft versies
Op dit moment is de module ontwikkeld en getest op basis van **Chipsoft HiX 6.3**.
Naar alle waarschijnlijkheid functioneert de module ook op Chipsoft HiX 6.2 maar dit is nog niet getest.

## Installatie

1. Start een nieuwe Powershell sessie / terminal.
2. Identificeer de Powershell Module locatie door het volgende commando uit te voeren: `$Env:PSModulePath`.
3. Download en kopieer de module bestanden naar een van deze locaties. Indien je wilt dat alle gebruikers op de machine de module kunnen gebruiken gebruik dan het pad **C:\Program Files\WindowsPowerShell\Modules** (Windows) of **/usr/local/microsoft/powershell/7/Modules** (Linux/Mac).
4. Importeer de module via het commando `Import-module -Name SubsetHixDatabase`.
5. Vanaf nu kun je de module gebruiken. Een handig commando om snel een overzicht van de verschillende parameters, als ook voorbeelden te zien, is `Get-Help Subset-HixDatabase -Detailed`.

## Benodigdheden voor uitvoeren module
De module is gericht om patiënt gegevens uit een gevulde Chipsoft HiX database in te laden naar een gekloonde Chipsoft HiX omgeving. Deze module richt zich *alleen* op patiënt gegevens en niet op het importeren van inrichtingen, rechten, etc.

Om de inrichting, rechten, etc in een lege Chipsoft HiX database te laden, adviseren we je om gebruik te maken van de Chipsoft Clone Content tool. Deze tool wordt meegeleverd met de Database Updater software en de documentatie is op te vragen bij Chipsoft.

De Chipsoft Clone Content tool vult een een lege database met alle inrichtingstabellen en is dus een ideale manier om een Chipsoft HiX omgeving aan te maken die technisch functioneert maar nog geen patiëntgegevens bevat.

Nadat je de Chipsoft Clone Content tool en de Database Updater uitgevoert hebt om een nieuwe, lege, Chipsoft HiX omgeving aan te maken kun je vervolgens deze module gebruiken om deze lege omgeving te vullen met specifieke patiënt gegevens.

## Hoe de module functioneert


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

### PatientIDs import bestand
Het PatientIDs import bestand is een .txt bestand welke het mogelijk maakt om de patiënt ID's van specifieke patiënten te configureren die - afhankelijk van de parameter `ImportPatientIds` - meegenomen worden bij het importeren van de data van deze patiënten. Een use-cases hiervoor is om ervoor te zorgen dat de data van testpatiënten altijd ingeladen worden in de gekloonde Chipsoft HiX database. In dit geval zorg je ervoor dat de patiënt ID's van je testpatiënten in het PatientIDs import bestand staan.

De module verwacht op elke regelen in het PatientIDs import bestand één uniek patiëntnummer. Bijvoorbeeld:

```
12345678
87654321
```

## Voorbeeld commando's
a

## Licentie
De GNU Affero General Public License Versie 3 (AGPL 3) is van toepassing op dit project.
De inhoud van deze licentie is te vinden in de [license file](https://github.com/Privinity/Chipsoft-HiX-Subset-Module?tab=AGPL-3.0-1-ov-file#readme).
