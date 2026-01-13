# ghgsql
Dockerfile to access EU industrial emission and ETS data via SQL / MariaDB

## see also

* [Errors and Inconsistencies in European Emission Data (Dec 2025, Industry
  Decarbonization Newsletter)](
  https://industrydecarbonization.com/news/errors-and-inconsistencies-in-european-emission-data.html)
* [Greenhouse Gas Emission Data: Public, difficult to access, and not always correct
  (Dec 2025, presentation at 39C3)](
  https://media.ccc.de/v/39c3-greenhouse-gas-emission-data-public-difficult-to-access-and-not-always-correct)

## instructions

> [!NOTE] The database and table schemas are work in progress and may change.

You can build the Docker image with `make` and start it with `make run`.

It will expose a MariaDB (MySQL compatible) server (username `ghg` / no password) and a
phpMyAdmin web interface on localhost.

It currently provides a database `eu` with multiple tables:

* `iep`/`iepraw` contain emission data from the EU's Industrial Emissions Portal.
  `iepraw` contains the data in unmodified form (column names and content like in CSV
  data source), while `iep` contains a simplified version with shorter names (e.g.,
  column name `year` instead of `reportingYear`, pollutant name `CO2` instead of
  `Carbon dioxide (CO2)`) and uninteresting data removed.
* `ets` containts emission data for the European Emission Trading System (ETS).
* `linking` contains data that allows connecting entries from the two tables.

The `examples` subdirectory contains some usage examples in Python.

## data sources

The data sources are not part of this repository. They are fetched while building the
Dockerfile.

The [Industrial Emissions Portal data](
https://sdi.eea.europa.eu/catalogue/srv/eng/catalog.search#/metadata/9405f714-8015-4b5b-a63c-280b82861b3d)
is provided by the European Environmental Agency. We use the latest CSV version of the
air releases.

The [ETS data is provided by the EU's Union Registry](
https://union-registry-data.ec.europa.eu/report/welcome). The latest "Verified
Emissions" are provided as an XLSX (Excel) file.

The linking data has been provided by [Jan Abrell, Mirjam Kosch, and Leonard Stimpfle in
the Cadmus EUI Research Repository](
https://cadmus.eui.eu/entities/publication/d8887cdd-c98c-4ba3-8e91-0710747f4e4e).

All data sources use a [CC BY 4.0 license](
https://creativecommons.org/licenses/by/4.0/).

## who

This repository was created by [Hanno Böck](https://hboeck.de/) as a research tool for
the [Industry Decarbonization Newsletter](https://industrydecarbonization.com/).
