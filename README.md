# Table of contents 
* [Dependencies](#Dependencies)
* [Installing SOMA](#Pipeline)
* [Downloading databases](#Databases)
* [Testing the installation](#test)

## Dependencies <a name="Dependencies"></a>

### Software 
- [Nextflow](https://www.nextflow.io/docs/latest/install.html).
- [Java 11 (or later, up to 22)](http://www.oracle.com/technetwork/java/javase/downloads/index.html) (required for Nextflow).
- A container runtime, currently [Singularity](https://sylabs.io/singularity/) and [Apptainer](https://apptainer.org/docs/admin/main/index.html) are supported.

### Hardware
- A POSIX-compatible system (Linux, macOS, etc) or Windows through [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux).
- At least 16GB of RAM.
- At least 100 GB of storage.
  > ℹ️ Storage requirements
  > - The pipeline installation requires 100 Mb of storage.
  > - Combined the default databases use 120 GB of storage
  > - Containers require a total of 11 GB of storage.
  > - The pipeline generates a variable number/size of input files, depending on input size and quality. Generally this ranges from 30-60 Gb. 
  > - The pipeline output generates ~200 Mb of output files per-sample.

### Databases
- Mandatory: A host reference database (genome assembly and/or Kraken2 database).
- Optional: Up to 14 databases containing relevant reference datasets. 
  > ℹ️ Optional databases
  > - If optional databases are not installed the pipeline will still run without error but the associated stages will be skipped. 
  > - A **[script](https://github.com/ukhsa-collaboration/SOMA/blob/main/bin/get_dbs.py)** is provided which will download any requested databases and update the relevant config files.

  > - It is highly recommended to install the at least one of: Kraken2, Centrifuger and/or Slyph databases, as this is required for read-based taxonomic assignment. 
  > - It is highly recommended to install the Genome Taxonomy Database (GTDB) as this is required to add taxonomic assignments to metagenome-assembled genomes.
  > - It is highly recommended to install geNomad and Skani databases as these are required for contig classification. 

## Installing SOMA <a name="Pipeline"></a>
### 1). Download SOMA
Clone the repository (if you have git on your system):
```
git clone https://github.com/ukhsa-collaboration/SOMA.git
```
Alternatively, download the [latest release]():
```
# PENDING
```
### 2). Install Nextflow

**a).** Check which version of Java is installed (must be Java 11 or later) with the following:
```
java -version
```
_If Java is not installed, follow the instructions [here](https://www.nextflow.io/docs/latest/install.html)._

**b).** Then install Nextflow and make it executable:
```
curl -s https://get.nextflow.io | bash

chmod +x nextflow
```
**c).** Either move it to an executible path (if you have sudo access), or add the location to your bashrc. 
```
sudo mv nextflow /usr/local/bin
```
**d).** Test the installation:
```
nextflow info
```
### 3). Installing a container runtime

#### Option a). Installing Singularity
Instructions to install Singularity can be found [here](https://docs.sylabs.io/guides/3.0/user-guide/installation.html).

#### Option b). Installing Apptainer
Instructions to install Apptainer can be found [here](https://apptainer.org/docs/admin/main/installation.html).

# Downloading databases <a name="Databases"></a>

Relevant databases need to be downloaded and the relevant rows of the [config/params.config](https://github.com/ukhsa-collaboration/SOMA/blob/main/conf/params.config) updated. Doing this manually is possible 

Steps for manual database installation are provided immediately below, however, [automated database installation](#auto_DB) is possible an high recommended as it will download the databases and update [config/params.config](https://github.com/ukhsa-collaboration/SOMA/blob/main/conf/params.config). 

## Manual database installation

Each database is described below along with:
 - A link to an exemplar file/folder/download.
 - The relevant parameter to update in [config/params.config](https://github.com/ukhsa-collaboration/SOMA/blob/main/conf/params.config). 
   - This should be formatted as: _parameter = "DATABASE LOCATION"_
 - Any relevant code to prepare the database.

**SOMA can use the following databases.**
- **Mandatory (either or both can be provided):**
  - A host reference genome assembly, FASTA format. 
    - _Example: [human-t2t-hla-argos985.fa.gz](https://objectstorage.uk-london-1.oraclecloud.com/n/lrbvkel2wjot/b/human-genome-bucket/o/)_ [Size: 1 GB].
    - _Parameter: READ_DECONTAMINATION.host_assembly = "PATH/TO/human-t2t-hla-argos985.fa.gz"_
    - Additional steps:
        ```
        wget https://objectstorage.uk-london-1.oraclecloud.com/n/lrbvkel2wjot/b/human-genome-bucket/o/human-t2t-hla-argos985.fa.gz
        ```
  - A host reference [Kraken2](https://github.com/DerrickWood/kraken2) database for taxonomic assignment.
    - _Example: [k2_HPRC_20230810](https://zenodo.org/records/8339732)_ [Size: 5 GB]. 
    - _Parameter: READ_DECONTAMINATION.host_krakendb = "PATH/TO/k2_HPRC_20230810/"_
    - Additional steps:
        ```
        # Get database (gzipped tarball)
        wget https://zenodo.org/records/8339732/files/k2_HPRC_20230810.tar.gz

        # Decompress
        tar xvf k2_HPRC_20230810.tar.gz

        # Delete files
        rm k2_HPRC_20230810.tar.gz
        ```
- **Optional:**
  - A reference [Kraken2](https://github.com/DerrickWood/kraken2) database for taxonomic assignment.
    - _Example: [k2_standard_16gb_20240605](https://benlangmead.github.io/aws-indexes/k2)_ [Size: 16 GB]
    - _Parameter: TAXONOMIC_PROFILING.krakendb = "PATH/TO/k2_pluspf_16gb_20240605/"_
    - Additional steps:
        ```
        # Get database (gzipped tarball)
        wget https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16gb_20240605.tar.gz

        # Decompress
        tar xvf k2_pluspf_16gb_20240605.tar.gz

        # Delete files
        rm k2_pluspf_16gb_20240605.tar.gz
        ```
  - A reference [Centrifuger](https://github.com/mourisl/centrifuger) database for taxonomic assignment.
    - _Example: [cfr_hpv+gbsarscov2.*.cfr](https://zenodo.org/records/10023239)_. [Size: 45 GB]
    - _Parameter: TAXONOMIC_PROFILING.centrifugerdb = "PATH/TO/centrifuger_db/"_
        ```
        # Make and enter directory
        mkdir centrifuger_db ; cd centrifuger_db

        # Download database
        wget https://zenodo.org/records/10023239/files/cfr_hpv+gbsarscov2.1.cfr
        wget https://zenodo.org/records/10023239/files/cfr_hpv+gbsarscov2.2.cfr
        wget https://zenodo.org/records/10023239/files/cfr_hpv+gbsarscov2.3.cfr
        ```
  - A reference [Sylph](https://github.com/bluenote-1577/sylph) database for taxonomic assignment.
    - _Example: [gtdb-r220-c200-dbv1.syldb](http://faust.compbio.cs.cmu.edu/sylph-stuff/gtdb-r220-c200-dbv1.syldb)_ [Size: 13.1 GB].
    - _Parameter: TAXONOMIC_PROFILING.sylphdb = "PATH/TO/gtdb-r220-c200-dbv1.syldb"_
    - Additional steps:
        ```
        wget http://faust.compbio.cs.cmu.edu/sylph-stuff/gtdb-r220-c200-dbv1.syldb
        ```
  - Taxonomy files for [taxpasta](https://taxpasta.readthedocs.io/en/latest/) (nodes.dmp and names.dmp).
    - _Example: [taxdump/*.dmp](https://taxpasta.readthedocs.io/en/latest/how-tos/how-to-add-names/)_ [Size: 0.5 GB].
    - _Parameter: TAXONOMIC_PROFILING.dbdir = "PATH/TO/taxdump/"_
    - Additional steps:
        ```
        # Get database (gzipped tarball)
        wget ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz

        # Decompress
        tar xvf taxdump.tar.gz

        # Delete files
        rm taxdump.tar.gz
        ```
  - The [Genome Taxonomy Database](https://gtdb.ecogenomic.org/downloads) (GTDB) for taxonomic assignment of metagenome assembled genomes.
    - Note: at present it must be release220.
    - _Example: [gtdbtk_r220_data](https://data.gtdb.ecogenomic.org/releases/release220/220.0/auxillary_files/gtdbtk_package/full_package/gtdbtk_r220_data.tar.gz)_.
    - _Parameter: GTDBTK_CLASSIFYWF.gtdb_db = "PATH/TO/release220/"_
    - Additional steps:
        ```
        # Get database (gzipped tarball)
        wget https://data.gtdb.ecogenomic.org/releases/release220/220.0/auxillary_files/gtdbtk_package/full_package/gtdbtk_r220_data.tar.gz

        # Decompress
        tar xvf gtdbtk_r220_data.tar.gz

        # Delete files
        rm gtdbtk_r220_data.tar.gz
        ```
  - A Mash database, build from GTDB (above) for taxonomic assignment of metagenome assembled genomes. 
    - _Example: []()_.
    - _Parameter: GTDBTK_CLASSIFYWF.mash_db = "/PATH/TO/r220.msh"_
    - Additional steps:
        ```
        # Download the prebuilt database
        wget https://zenodo.org/records/13731176/files/r220.msh
        ```
  - A [skani](https://github.com/bluenote-1577/skani) database, build from GTDB for rapid taxonomic assignment of contigs.
    - _Example: []()_.
    - _Parameter: SKANI_SEARCH.db = "/PATH/TO/gtdb_skani_database_ani/"_
    - Additional steps:
        ```
        # Navigate to the directory where you downloaded GTDB

        # Pull a skani container 
        singularity pull docker://quay.io/biocontainers/skani:0.2.1--h4ac6f70_0

        # Collect all genomes locations
        find gtdbtk_r220_data/ | grep .fna > gtdb_file_names.txt

        # Construct the database
        singularity exec ../skani:0.2.1--h4ac6f70_0.sif skani sketch -l gtdb_file_names.txt -o gtdb_skani_database_ani -t 4
        ```
  - [CheckM](https://github.com/Ecogenomics/CheckM) database, for metagenome assembled genome quality control.
    - _Example: []()_.
    - _Parameter: CHECKM_LINEAGEWF.db = "/PATH/TO/checkm_database/"_
    - Additional steps:
        ```
        # Make a directory for the CheckM database
        mkdir checkm_database ; checkm_database

        # Get database (gzipped tarball)
        wget https://zenodo.org/records/7401545/files/checkm_data_2015_01_16.tar.gz

        # Decompress
        tar xvf checkm_data_2015_01_16.tar.gz

        # Delete files
        rm checkm_data_2015_01_16.tar.gz
        ```
  - [geNomad](https://github.com/apcamargo/genomad) database, for identification of mobile genetic elements.
    - _Example: [](https://zenodo.org/records/10594875/files/)_ [Size: 2.2 GB].
    - _Parameter: GENOMAD_ENDTOEND.db = "/PATH/TO/genomad_database/"_
    - Additional steps:
        ```
        # Make a directory for the CheckM database
        mkdir genomad_database ; genomad_database

        # Get database (gzipped tarball)
        wget https://zenodo.org/records/10594875/files/genomad_db_v1.7.tar.gz

        # Decompress
        tar xvf genomad_db_v1.7.tar.gz

        # Delete files
        rm genomad_db_v1.7.tar.gz
        ```
  - [ResFinder](http://genepi.food.dtu.dk/resfinder) database, for identification of antimicrobial resistance (AMR) factors.
    - _Example: [resfinder_db](https://bitbucket.org/genomicepidemiology/resfinder_db/)_.
    - _Parameter: RESFINDER.db = "/PATH/TO/resfinder_db/"_
    - Additional steps:
        ```
        # Pull a container with the dependencies to build ResFinder
        singularity pull docker://quay.io/biocontainers/virulencefinder:2.0.4--hdfd78af_0

        # Clone the ResFinder repo
        git clone https://bitbucket.org/genomicepidemiology/resfinder_db/

        # Enter the database folder
        cd resfinder_db

        # Build the database
        singularity exec ../virulencefinder_2.0.4--hdfd78af_0.sif python INSTALL.py /usr/local/bin/kma
        ```
  - [PointFinder](https://bitbucket.org/genomicepidemiology/pointfinder) database, for identification of AMR factors.
    - _Example: [pointfinder_db](https://bitbucket.org/genomicepidemiology/pointfinder_db/)_.
    - _Parameter: POINTFINDERFINDER.db = "/PATH/TO/resfinder_db/"_
    - Additional steps:
        ```
        # Pull a container with the dependencies to build PointFinder (If not already downloaded)
        singularity pull docker://quay.io/biocontainers/virulencefinder:2.0.4--hdfd78af_0

        # Clone the PointFinder repo
        git clone https://bitbucket.org/genomicepidemiology/pointfinder_db/

        # Enter the database folder
        cd pointfinder_db

        # Build the database
        singularity exec ../virulencefinder_2.0.4--hdfd78af_0.sif python INSTALL.py /usr/local/bin/kma
        ```
  - [VirulenceFinder](https://bitbucket.org/genomicepidemiology/virulencefinder) database, for identification of virulence factors. 
    - _Example: [virulencefinder_db](https://bitbucket.org/genomicepidemiology/virulencefinder_db/)_.
    - _Parameter: VIRULENCEFINDERFINDER.db = "/PATH/TO/virulencefinder_db/"_
    - Additional steps:
        ```
        # Pull a container with the dependencies to build VirulenceFinder (If not already downloaded)
        singularity pull docker://quay.io/biocontainers/virulencefinder:2.0.4--hdfd78af_0

        # Clone the ResFinder repo
        git clone https://bitbucket.org/genomicepidemiology/virulencefinder_db/

        # Enter the database folder
        cd virulencefinder_db

        # Build the database
        singularity exec ../virulencefinder_2.0.4--hdfd78af_0.sif python INSTALL.py /usr/local/bin/kma
        ```


## Automated database installation <a name="auto_DB"></a>
- To run all stages of the pipeline, SOMA requires a number of databases to be downloaded. To make this easier, a python script is included which will fetch the required databases and update the parameters file with the relevant locations of all databases. The script take the conf/params.config and a directory where you want the database to be installed as mandatory input. Then the user can specify which databases they want to download and (optionally) the URL of each database (if it differs from the defaults provided). For example:

```
get_dbs.py --config_file <soma/conf/params.config> --db_dir </PATH/TO/DB/DIRECTORY/> --genomad --host_assembly
```
- This would download a human reference genome (for host read removal) and the geNomad (for identification of mobile genetic elements) into the location specified by '--db_dir'. It would then update the 'params.config' file with the new locations. 
```

usage: get_dbs.py [-h] --config_file CONFIG_FILE --db_dir DB_DIR [--genomad] [--genomad_url GENOMAD_URL] [--host_assembly] [--host_assembly_url HOST_ASSEMBLY_URL] [--host_kraken2db]
                  [--host_kraken2db_url HOST_KRAKEN2DB_URL] [--kraken2db] [--kraken2db_url KRAKEN2DB_URL] [--sylphdb] [--sylphdb_url SYLPHDB_URL] [--checkmdb] [--checkmdb_URL CHECKMDB_URL]
                  [--virulencefinderdb] [--virulencefinderdb_URL VIRULENCEFINDERDB_URL] [--pointfinderdb] [--pointfinderdb_URL POINTFINDERDB_URL] [--resfinderdb] [--resfinderdb_URL RESFINDERDB_URL]
                  [--centrifugerdb] [--centrifugerdb_URL CENTRIFUGERDB_URL]

options:
  --config_file CONFIG_FILE                          Config file
  --db_dir DB_DIR                                    Database directory

  --genomad                                          Get geNomad database
  --genomad_url GENOMAD_URL                          geNomad database URL

  --host_assembly                                    Get host reference assembly
  --host_assembly_url HOST_ASSEMBLY_URL              URL of host assembly database URL

  --host_kraken2db                                   Get Host Kraken2 database
  --host_kraken2db_url HOST_KRAKEN2DB_URL            URL of host Kraken2 database

  --kraken2db                                        Get Kraken2 database for taxonomic assignment of reads
  --kraken2db_url KRAKEN2DB_URL                      URL of Kraken2 database for taxonomic assignment of reads

  --sylphdb                                          Get Sylph database for taxonomic assignment of reads
  --sylphdb_url SYLPHDB_URL                          URL of Sylph database

  --checkmdb                                         Get CheckM database
  --checkmdb_URL CHECKMDB_URL                        URL of CheckM database

  --virulencefinderdb                                Get VirulenceFinder database
  --virulencefinderdb_URL VIRULENCEFINDERDB_URL      URL of VirulenceFinder database

  --pointfinderdb                                    Get PointFinder database
  --pointfinderdb_URL POINTFINDERDB_URL              URL of PointFinder database

  --resfinderdb                                      Get ResFinder database
  --resfinderdb_URL RESFINDERDB_URL                  URL of ResFinder database

  --centrifugerdb                                    Get Centrifuger database
  --centrifugerdb_URL CENTRIFUGERDB_URL              URL of Centrifuger database

```
It is also possible to install some/all databases manually, this can be achieved by manually downloading each database and then specifying the database location in the conf/params.config file. The matching parameter for each database is listed in the comments next to the relevant parameters. There is also an example params.config file here.

## User supplied databases and metadata

### a). Guide metadata


Certain modules that have taxa-specific functions require those genera/species to be defined during execution. To make this as simple as possible, we have included a metadata table: [data/taxonomy_guide_gtdbr220.tsv](https://github.com/ukhsa-collaboration/SOMA/blob/main/data/taxonomy_guide_gtdbr220.tsv), which takes GTDB taxonomic assignments and converts them to the relevant parameter inputs. 

**Column definitions**:\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Original_ID**: Full GTDB designation.\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**MS_ID**: Most specific GTDB definition it was possible to assign.\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Clean_ID**: Most specific GTDB definition it was possible to assign with the alphabetical suffix removed.\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Target**: Should a metagenome-assembled genomes be processed with taxa specific subworkflow? (set as 'Y' to allow).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**AMRFINDER**: Designation for the AMRFinderPlus '--organism' option, more information can be found [here](https://github.com/ncbi/amr/wiki/Running-AMRFinderPlus#--organism-option).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**RESFINDER**: Designation for the ResFinder '--species' option, more information can be found [here](https://bitbucket.org/genomicepidemiology/resfinder/src/master/).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**MLST**: Designation for the MLST '--scheme' option, more information can be found [here](https://github.com/tseemann/mlst).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**KROCUS**: Designation for the Krocus '--species' option, more information can be found [here](https://github.com/andrewjpage/krocus).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**gene_DB**: Name of folder (not full path) containing the relevant gene database (more information below)


A subset of [data/taxonomy_guide_gtdbr220.tsv](https://github.com/ukhsa-collaboration/SOMA/blob/main/data/taxonomy_guide_gtdbr220.tsv) is shown below: 

[<img src="https://github.com/ukhsa-collaboration/SOMA/blob/main/docs/images/soma_taxonomy_guide_example.png"/>](https://github.com/ukhsa-collaboration/SOMA/blob/main/docs/images/soma_taxonomy_guide_example.png)
<br>

The table above shows examples of various species and their matching database/parameter definitions. For example, it was necessary to define the MLST and Krocus schemes for *E. coli* as there are multiple schemes for that species available. 





### b). Target taxa

The summary output HTML reports the results of read-based taxonomic classfication, as both the full list of taxa and a subset reported only taxa of interest. These taxa are defined in [data/target_species.tsv](https://github.com/ukhsa-collaboration/SOMA/blob/main/data/target_species.tsv). 

Which is formatted as follows:

**Column definitions**:\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Column 1**: Taxa name.\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Column 2**: [NCBI taxonomy ID](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Column 3**: Domain (Bacteria, Eukarya, Archaea).\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;**Column 4**: Rank of the taxa defintion (species, genus, family, order, class, phylum, kingdom, domain).\

A subset of [data/target_species.tsv](https://github.com/ukhsa-collaboration/SOMA/blob/main/data/target_species.tsv) is shown below: 

[<img src="https://github.com/ukhsa-collaboration/SOMA/blob/main/docs/images/soma_target_species.png" width="35%" />](https://github.com/ukhsa-collaboration/SOMA/blob/main/docs/images/soma_target_species.png)

### c). Clonal complex/eBURST group definitions

Sequence types (STs) will be determine for the subset of metagenome-assembled genomes for which schemes exist. Many of these schemes also have clonal complex (or eBURST group) defintions, where 1 or more STs are grouped into clusters. For SOMA, these are defined in [data/clonal_complex_designations.json](https://github.com/ukhsa-collaboration/SOMA/blob/main/data/clonal_complex_designations.json), a subset is shown below: 

```
{
"st_ebg_lookup":
    {
     "saureus": {
            "('9',)": "CC9"
      },
      "salmonella": {
            "('19','35',)": "1"
      },
      "yersinia": {
            "('3',)": "CC3",
            "('98',)": "CC98"
    }
}
```
**Format definition**: ST's are nested within each scheme name (e.g. 'salmonella') and individual ST's (keys) are listed within parentheses (e.g. "'('19','35',)'") with the clonal complex/eBURST group listed at the end of each line (values). 

### d). Target genes

Current not enabled will be added later. 






