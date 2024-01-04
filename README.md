# ndp
This nextflow pipeline will demultiplex 16S amplicon reads based on two custom barcode sequences and identify the reads using a 16S database. 
Consider the corresponding publication (DOI-XXX) for further details. 
Here's an overview of the individual processes taking place in the pipline:

* Read filtering via [Nanofilt](https://github.com/wdecoster/nanofilt)
* QC via [FastQC](https://github.com/s-andrews/FastQC) and [MultiQC](https://multiqc.info/)
* Demultiplexing and trimming via [seqkit](https://github.com/shenwei356/seqkit) and custom python scripts
* Annotation of reads via [Emu](https://gitlab.com/treangenlab/emu)

The pipeline will output the following files in the designated output folder:
* /OUTPUT_FOLDER/01_filtered_reads/f_{filename}.fastq: Filtered reads (fastq) after applying Nanofilt.
* /OUTPUT_FOLDER/02_quality_control/multiqc_report.html: MultiQC report for all fastq files.
* /OUTPUT_FOLDER/03_bed_files/f_{filename}.bed: BED files after alignment to barcode sequences.
* /OUTPUT_FOLDER/04_split_bed_files/f_{filename}_bar_BARCODE.bed: Separated BED files for each barcode.
* /OUTPUT_FOLDER/05_final_fastqs/f_{filename}_bar_BARCODE_extracted.fastq: Demultiplexed and trimmed fastq files for each barcode.
* /OUTPUT_FOLDER/06_emu_abundance: Contains output of amu annotation in sample subfolders.

## Setup

1) Install [nextflow(~=23.04)](https://github.com/nextflow-io/nextflow) and [singularity(~=3.8)](https://github.com/sylabs/singularity).
2) Pull the repository as such:

```
git clone https://github.com/dommju/ndp.git
```
3) Install the necessary singularity containers in a new directory PATH/TO/ndp/0_singularity_containers/ as such:

```
cd PATH/TO/ndp
mkdir 0_singularity_containers
cd  0_singularity_containers
singularity pull --name nanofilt2.8.0.sif https://depot.galaxyproject.org/singularity/nanofilt:2.8.0--py_0
singularity pull --name fastqc0.11.8.sif https://depot.galaxyproject.org/singularity/fastqc:0.11.8--2
singularity pull --name multiqc:1.9.sif https://depot.galaxyproject.org/singularity/multiqc:1.9--pyh9f0ad1d_0
singularity pull --name seqkit2.6.1.sif https://depot.galaxyproject.org/singularity/seqkit:2.6.1--h9ee0642_0
singularity pull --name python3.10.4.sif https://depot.galaxyproject.org/singularity/python:3.10.4
singularity pull --name biopython1.78.sif https://depot.galaxyproject.org/singularity/biopython:1.78
singularity pull --name emu3.4.5.sif https://depot.galaxyproject.org/singularity/emu:3.4.5--hdfd78af_0
```

## Primer sequences

### <a name="classic"></a>A Classic primer sequences
As published in DOI-XXX, we recommend to use these primers in your experimental setup to identify single bacterial isolates.
The pipeline can either detect one primer sequence (forward only) or both (forward and reverse).

| Primer    | Primer Sequence                                |
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

### <a name="degenerate"></a>A Degenerate primer sequences
As published in DOI-XXX, we recommend to use these primers in your experimental setup for microbiome characterization.
The pipeline can either detect one primer sequence ([forward only](#1bc)) or both ([forward and reverse](#1bc)).

| Primer    | Primer Sequence                                |
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


## Usage

It is recommended to use this pipeline on a cluster! 
We recommend to demultiplex on the MinION using real-time Guppy during the sequencing run and basecall resulting POD5 files using [Dorado](https://github.com/nanoporetech/dorado). 
Basecalled input files must be in fastq format!

### <a name="1bc"></a>A Running ndp to detect 1 PCR barcode
###running-ndp-to-detect-1-pcr-barcode

1) Create a new INPUT_FOLDER and OUTPUT_FOLDER directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
2) Modify the nextflow script (ndp.nf) by adjusting the working directory WD, INPUT_FOLDER directory and OUTPUT_FOLDER directory.

3) Transfer the fastq files to the INPUT_FOLDER directory

4) Execute the [classic primer](#classic) pipeline using:

```
nextflow run ndp.nf
```

To allow ndp to detect a [degenerate primer](#degenerate) (microbiome characterization), run the following command instead:

```
nextflow run ndp_degenerate.nf
```

### <a name="2bc"></a>A Running ndp to detect 2 PCR barcodes
###running-ndp-to-detect-2-pcr-barcodes

1) Create a new INPUT_FOLDER and OUTPUT_FOLDER directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
2) Modify the nextflow script (ndp.nf) by adjusting the working directory WD, INPUT_FOLDER directory and OUTPUT_FOLDER directory.

3) Transfer your fastq files to the INPUT_FOLDER directory

4) Execute the [classic primer](#classic) pipeline using:

```
nextflow run ndp2bc.nf
```

To allow ndp to detect a [degenerate primer](#degenerate) pair (microbiome characterization), run the following command instead:

```
nextflow run ndp2bc_degenerate.nf
```

## Support
We do not plan to adapt this pipeline any futher. It could however be modified to fit other applications, as:

* ...the primer sequences in the files PATH/TO/ndp/0_scripts may be changed to other primer sequences.
* ...the  pipeline may be adapted to other target organisms by using other Emu databases or creating custom Emu databases. For more info, please visit the [Emu GitLab](https://gitlab.com/treangenlab/emu) page.

## Citations
If this pipeline is used for your research purposes, please cite DOI-XXX.

## Credits
This pipeline relies on a few great pieces of software, namely:

* [Nextflow](https://github.com/nextflow-io/nextflow)
* [Singularity CE](https://github.com/sylabs/singularity)
* [Nanofilt](https://github.com/wdecoster/nanofilt)
* [FastQC](https://github.com/s-andrews/FastQC)
* [MultiQC](https://multiqc.info/)
* [seqkit](https://github.com/shenwei356/seqkit)
* [Emu](https://gitlab.com/treangenlab/emu)

## License

The project is licensed under the [MIT license](LICENSE).

## Contact

You can reach us at: 
* <mailto:pierre.schneeberger@swisstph.ch>
* <mailto:julian.dommann@swisstph.ch>

## ToDo
* add primers / flexibility
* generate directory tree of final setup
* Explain the rustic nature of pipeline; open for contributors