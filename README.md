# Static-Storage

The purpose of this repository is to bundle every data source into a singular repository, as well as include anything else used for generating such data. The repository also includes github actions to run scripts to update eligible data files.

Here you can find a breakdown of the three main parts of the repository:

## Generators
Generators include everything that is needed for data processing to create usable data files. Generators that collect data from APIs, or other automated sources, are ran by Github Actions to keep data up-to-date. These data can be found in the directory **Reference**.

## Data-Storage
Data-Storage includes data files that can be/are used by the [Artemis](https://github.com/Wynntils/Artemis) or other projects, but are not automatically updated/processed. It may also include raw data that is further processed, but not automatically.

## Reference
Reference includes all data files that are automatically generated, usually by scripts in the Generators folder.