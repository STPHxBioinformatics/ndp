# ndp
This nextflow pipeline will demultiplex 16S amplicon reads based on two custom barcode sequences and identify the reads using a 16S database. 
Consider the corresponding publication (DOI-XXX) for further details. 
Here's an overview of the individual processes taking place in the pipline:

* Read filtering via [Nanofilt](https://github.com/wdecoster/nanofilt)
* Demultiplexing and trimming via [seqkit](https://github.com/shenwei356/seqkit) and custom python scripts
* Annotation of reads via [Emu](https://gitlab.com/treangenlab/emu)

The pipeline will output the following files in the designated output folder:
* /OUTPUT_FOLDER/01_filtered_reads/f_{filename}.fastq: Filtered reads (fastq) after applying Nanofilt.
* /OUTPUT_FOLDER/02_bed_files/f_{filename}.bed: BED files after alignment to barcode sequences.
* /OUTPUT_FOLDER/03_split_bed_files/f_{filename}_bar_BARCODE.bed: Separated BED files for each barcode.
* /OUTPUT_FOLDER/04_final_fastqs/f_{filename}_bar_BARCODE_extracted.fastq: Demultiplexed and trimmed fastq files for each barcode.
* /OUTPUT_FOLDER/05_emu_abundance: Contains output of Emu annotation in sample subfolders.

## Citations
If this pipeline is used for your research purposes, please cite DOI-XXX.

## Package structure overview
After completing the [setup](#setup) and following the [usage guide](#usage), your folder structure should look like this:

```
ndp/                            # This is your working directory (WD)
├── 0_emu_db/
│   ├── species_taxid.fasta 
│   └── taxonomy.tsv
│
├── 0_scripts/
│   ├── 1bc.tab 
│   ├── 1bc_degen.tab 
│   ├── 2bc.tab 
│   ├── 2bc_degen.tab 
│   ├── extract_quality.py 
│   └── split_bed_files.py
│
├── 0_singularity_containers/   # Must be created during setup!
│   ├── nanofilt2.8.0.sif 
│   ├── seqkit_2.6.1.sif 
│   ├── python_3.10.4.sif
│   ├── biopython_1.78.sif
│   └── emu_3.4.5.sif
│
├── INPUT_FOLDER/
│   ├── input_file1.fastq       # INPUT_FOLDER must be created for each run!
│   └── input_file2.fastq
├── INPUT_FOLDER2/
│   ├── input_file3.fastq       
│   └── input_file4.fastq
│
├── OUTPUT_FOLDER               # OUTPUT_FOLDER must be created for each run!
├── OUTPUT_FOLDER2              
│
├── ndp.nf                      # Specify WD, INPUT_FOLDER and OUTPUT_FOLDER in this script!
├── ndp_degenerate.nf           # Specify WD, INPUT_FOLDER and OUTPUT_FOLDER in this script!
├── ndp2bc.nf                   # Specify WD, INPUT_FOLDER and OUTPUT_FOLDER in this script!
└── ndp2bc_degenerate.nf        # Specify WD, INPUT_FOLDER and OUTPUT_FOLDER in this script!
```

## <a name="setup"></a>Setup
We tested our pipeline on CentOS (7.9) and Ubuntu (22.04).

1) Install [nextflow(~=23.04)](https://github.com/nextflow-io/nextflow) and [singularity(~=3.8)](https://docs.sylabs.io/guides/3.8/admin-guide/installation.html#before-you-begin).
2) Pull the repository as such:

```
git clone https://github.com/STPHxBioinformatics/ndp.git
```
3) Install the necessary singularity containers in a new directory PATH/TO/ndp/0_singularity_containers/ as such:

```
cd PATH/TO/ndp
mkdir 0_singularity_containers
cd  0_singularity_containers
singularity pull --name nanofilt2.8.0.sif https://depot.galaxyproject.org/singularity/nanofilt:2.8.0--py_0
singularity pull --name seqkit2.6.1.sif https://depot.galaxyproject.org/singularity/seqkit:2.6.1--h9ee0642_0
singularity pull --name python3.10.4.sif https://depot.galaxyproject.org/singularity/python:3.10.4
singularity pull --name biopython1.78.sif https://depot.galaxyproject.org/singularity/biopython:1.78
singularity pull --name emu3.4.5.sif https://depot.galaxyproject.org/singularity/emu:3.4.5--hdfd78af_0
```

## Primer sequences

### <a name="classic"></a>A - Classic primer sequences
* We recommend to use these primers in your experimental setup to identify single bacterial isolates.
* The pipeline can either detect one primer sequence ([FWD only](#1bc)) or both ([FWD and REV](#2bc)).
* These primer sequences are enconded in the files 1bc.tab (FWD only) and 2bc.tab (FWD and REV), respectively

| Primer    | Primer Sequence (barcode in **bold**)          |
| --------- | ---------------------------------------------- |
| P01-FWD   | **GAGCCCGTTCCG**AGAGTTTGATCMTGGCTCAG          |
| P02-FWD   | **TGGCACCGATTA**AGAGTTTGATCMTGGCTCAG          |
| P03-FWD   | **GACATACAATGA**AGAGTTTGATCMTGGCTCAG          |
| P04-FWD   | **ATGGTCTACTAC**AGAGTTTGATCMTGGCTCAG          |
| P05-FWD   | **CCACTTGGATAG**AGAGTTTGATCMTGGCTCAG          |
| P06-FWD   | **CGATTATGGCAC**AGAGTTTGATCMTGGCTCAG          |
| P07-FWD   | **CTTACGAGGCAT**AGAGTTTGATCMTGGCTCAG          |
| P08-FWD   | **GTCCACCCTGGG**AGAGTTTGATCMTGGCTCAG          |
| P01-REV   | **GAGCCCGTTCCG**CGGTTACCTTGTTACGACTT          |
| P02-REV   | **TGGCACCGATTA**CGGTTACCTTGTTACGACTT          |
| P03-REV   | **GACATACAATGA**CGGTTACCTTGTTACGACTT          |
| P04-REV   | **ATGGTCTACTAC**CGGTTACCTTGTTACGACTT          |
| P05-REV   | **CCACTTGGATAG**CGGTTACCTTGTTACGACTT          |
| P06-REV   | **CGATTATGGCAC**CGGTTACCTTGTTACGACTT          |
| P07-REV   | **CTTACGAGGCAT**CGGTTACCTTGTTACGACTT          |
| P08-REV   | **GTCCACCCTGGG**CGGTTACCTTGTTACGACTT          |

### <a name="degenerate"></a>B - Degenerate primer sequences
* We recommend to use these primers in your experimental setup for microbiome characterization.
* The pipeline can either detect one primer sequence ([FWD only](#1bc)) or both ([FWD and REV](#2bc)).
* These primer sequences are enconded in the files 1bc_degen.tab (FWD only) and 2bc_degen.tab (FWD and REV), respectively

| Primer    | Primer Sequence (barcode in **bold**)          |
| --------- | ---------------------------------------------- |
| P01-FWD   | **GAGCCCGTTCCG**AGRGTTYGATYMTGGCTCAG          |
| P02-FWD   | **TGGCACCGATTA**AGRGTTYGATYMTGGCTCAG          |
| P03-FWD   | **GACATACAATGA**AGRGTTYGATYMTGGCTCAG          |
| P04-FWD   | **ATGGTCTACTAC**AGRGTTYGATYMTGGCTCAG          |
| P05-FWD   | **CCACTTGGATAG**AGRGTTYGATYMTGGCTCAG          |
| P06-FWD   | **CGATTATGGCAC**AGRGTTYGATYMTGGCTCAG          |
| P07-FWD   | **CTTACGAGGCAT**AGRGTTYGATYMTGGCTCAG          |
| P08-FWD   | **GTCCACCCTGGG**AGRGTTYGATYMTGGCTCAG          |
| P01-REV   | **GAGCCCGTTCCG**CGGYTACCTTGTTACGACTT          |
| P02-REV   | **TGGCACCGATTA**CGGYTACCTTGTTACGACTT          |
| P03-REV   | **GACATACAATGA**CGGYTACCTTGTTACGACTT          |
| P04-REV   | **ATGGTCTACTAC**CGGYTACCTTGTTACGACTT          |
| P05-REV   | **CCACTTGGATAG**CGGYTACCTTGTTACGACTT          |
| P06-REV   | **CGATTATGGCAC**CGGYTACCTTGTTACGACTT          |
| P07-REV   | **CTTACGAGGCAT**CGGYTACCTTGTTACGACTT          |
| P08-REV   | **GTCCACCCTGGG**CGGYTACCTTGTTACGACTT          |


## <a name="usage"></a>Usage

* It is recommended to use this pipeline on a cluster! 
* We recommend to demultiplex on the MinION using real-time Guppy during the sequencing run and basecall resulting POD5 files using [Dorado](https://github.com/nanoporetech/dorado). 
* Basecalled input files must be in fastq format!

### <a name="1bc"></a>A - Running ndp to detect 1 classic FWD primer (FWD only)

1) Create a new INPUT_FOLDER and OUTPUT_FOLDER directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
2) Modify the nextflow script (**ndp.nf**) by adjusting the working directory WD, INPUT_FOLDER directory and OUTPUT_FOLDER directory.

3) Transfer the fastq files to the INPUT_FOLDER directory

4) Execute the [classic primer](#classic) pipeline using:

```
nextflow run ndp.nf
```

### <a name="1bc-degen"></a>B - Running ndp to detect 1 degenerate FWD primer (FWD only)

1) Create a new INPUT_FOLDER and OUTPUT_FOLDER directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
2) Modify the nextflow script (**ndp_degenerate.nf**) by adjusting the working directory WD, INPUT_FOLDER directory and OUTPUT_FOLDER directory.

3) Transfer the fastq files to the INPUT_FOLDER directory

4) Execute the [degenerate primer](#degenerate) pipeline using:

```
nextflow run ndp_degenerate.nf
```

### <a name="2bc"></a>A - Running ndp to detect 2 classic primers (FWD and REV)

1) Create a new INPUT_FOLDER and OUTPUT_FOLDER directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
2) Modify the nextflow script (**ndp2bc.nf**) by adjusting the working directory WD, INPUT_FOLDER directory and OUTPUT_FOLDER directory.

3) Transfer your fastq files to the INPUT_FOLDER directory

4) Execute the [classic primer](#classic) pipeline using:

```
nextflow run ndp2bc.nf
```


### <a name="2bc-degen"></a>B - Running ndp to detect 2 degenerate primers (FWD and REV)

1) Create a new INPUT_FOLDER and OUTPUT_FOLDER directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
2) Modify the nextflow script (**ndp2bc_degenerate.nf**) by adjusting the working directory WD, INPUT_FOLDER directory and OUTPUT_FOLDER directory.

3) Transfer your fastq files to the INPUT_FOLDER directory

4) Execute the [degenerate primer](#degenerate) pipeline using:

```
nextflow run ndp2bc_degenerate.nf
```

## Pipeline modifications

* Primer sequences in the files 1bc.tab, 2bc.tab, 1bc_degen.tab or 2bc_degen.tab may be changed to fit other experimental setups.
* The  pipeline may be adapted to other target organisms by using [custom Emu databases](https://gitlab.com/treangenlab/emu#build-custom-database).

## License

The project is licensed under the [MIT license](LICENSE).

## Credit
This pipeline relies on a few great pieces of software, namely:

* [Nextflow](https://github.com/nextflow-io/nextflow)
* [Singularity CE](https://github.com/sylabs/singularity)
* [Nanofilt](https://github.com/wdecoster/nanofilt)
* [seqkit](https://github.com/shenwei356/seqkit)
* [Emu](https://gitlab.com/treangenlab/emu)
