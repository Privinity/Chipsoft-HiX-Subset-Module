# Chipsoft HiX Subset Powershell Module
De Chipsoft HiX Subset Module is een Powershell module welke het mogelijk maakt om een gekloonde Chipsoft HiX database te vullen met patiënt gegevens vanuit een - zelf te specificeren - Chipsoft HiX database.

## Ondersteunde Chipsoft versies
Op dit moment is de module ontwikkeld en getest op basis van **Chipsoft HiX 6.3**.
Naar alle waarschijnlijkheid functioneert de module ook op Chipsoft HiX 6.2 maar dit is nog niet getest.

## Installatie

1. Start een nieuwe Powershell sessie / terminal
2. Identificeer de Powershell Module locatie door het volgende commando uit te voeren: `$Env:PSModulePath`
3. Download en kopieer de module bestanden naar een van deze locaties. Indien je wilt dat alle gebruikers op de machine de module kunnen gebruiken gebruik dan het pad **C:\Program Files\WindowsPowerShell\Modules** (Windows) of **/usr/local/microsoft/powershell/7/Modules** (Linux/Mac)
4. Importeer de module via het commando `Import-module -Name SubsetHixDatabase`
5. Vanaf nu kun je de module gebruiken. Een handig commando om snel een overzicht van de verschillende parameters als ook voorbeelden te zien is `Get-Help Subset-HixDatabase -Detailed`

## Gebruik
a

## Licentie
De GNU Affero General Public License Versie 3 (AGPL 3) is van toepassing op dit project.
De inhoud van deze licentie is te vinden in de [license file](https://github.com/Privinity/Chipsoft-HiX-Subset-Module?tab=AGPL-3.0-1-ov-file#readme)
