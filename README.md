# ndp
A nextflow demultiplexing pipeline for PCR-barcoded 16S nanopore reads.

## Project status
We do not plan to adapt this pipeline any futher. It could however be modified, as:

* ...the barcode sequences in the files barcodes.txt and barcodes2.txt can be changed to other barcode sequences to fit other applications.
* ...the whole pipeline could be adapted to other target organisms by using other Emu databases or creating custom Emu databases. For more info, please visit the [Emu GitLab](https://gitlab.com/treangenlab/emu) page.

## Description

This nextflow pipeline will demultiplex 16S amplicon reads based on two custom barcode sequences and identify the reads using a 16S database. Consider the corresponding publication (DOI) for further details. Here's an overview of the individual processes taking place within the pipline:

* Read filtering via [Nanofilt](https://github.com/wdecoster/nanofilt)
* QC via [FastQC](https://github.com/s-andrews/FastQC) and [MultiQC](https://multiqc.info/)
* Demultiplexing and trimming via [seqkit](https://github.com/shenwei356/seqkit) and custom python scripts
* Annotation of reads via [Emu](https://gitlab.com/treangenlab/emu)

The pipeline will output the following files in the designated output folder:
* /OUTPUT_FOLDER/01_filtered_reads/f_{filename}.fastq: Filtered reads (fastq) after applying Nanofilt.
* /OUTPUT_FOLDER/02_quality_control/multiqc_report.html: MultiQC report for all fastq files.
* /OUTPUT_FOLDER/03_bed_files/f_{filename}.bed: BED files after alignment to barcode sequences.
* /OUTPUT_FOLDER/04_split_bed_files/f_{filename}_bar_BARCODE.bed: Separated BED files for each barcode.
* /OUTPUT_FOLDER/05_final_fastqs/f_{filename}_bar_BARCODE_extracted.fastq: Separated fastq files for each barcode.
* /OUTPUT_FOLDER/06_emu_abundance: Contains output of amu annotation in sample subfolders.

## Setup

1) Install [nextflow(v.23.04.1)](https://github.com/nextflow-io/nextflow) and [singularity(v.3.8.5)](https://github.com/sylabs/singularity).
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
singularity pull --name multiqc1.11.sif https://depot.galaxyproject.org/singularity/multiqc:1.11--pyhdfd78af_0
singularity pull --name seqkit2.6.1.sif https://depot.galaxyproject.org/singularity/seqkit:2.6.1--h9ee0642_0
singularity pull --name python3.10.4.sif https://depot.galaxyproject.org/singularity/python:3.10.4
singularity pull --name biopython1.78.sif https://depot.galaxyproject.org/singularity/biopython:1.78
singularity pull --name emu3.4.5.sif https://depot.galaxyproject.org/singularity/emu:3.4.5--hdfd78af_0
```

## Usage

It is recommended to use this pipeline on a cluster! 
We recommend to demultiplex on the MinION using real-time Guppy during the sequencing run and basecall resulting POD5 files using [Dorado](https://github.com/nanoporetech/dorado). 
Basecalled input files must be in fastq format!

1) Create a new INPUT and OUTPUT directory for each run (parent directory: /PATH/TO/ndp).

```
cd PATH/TO/ndp
mkdir INPUT_FOLDER
mkdir OUTPUT_FOLDER
```
3) Modify the nextflow script (ndp.nf) by adjusting the working directory WD, INPUT directory and OUTPUT directory.

4) Drop the fastq files into the input directory and execute the pipeline using:

```
nextflow run ndp.nf
```

## Support
In case of issues with the pipeline please contact pierre.schneeberger@swisstph.ch or julian.dommann@swisstph.ch.

## Authors and acknowledgment
Huge thanks go out to Jakob Kerbl-Knapp and Matthias Wurm, who greatly supported the development of the python demultiplexing script "demultiplexing.py".

## Citations
If this pipeline is used for your research purposes, please cite DOI-XXX.

## Credits
This pipline relies on a few great pieces of software, namely:

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
* add degen usage
* add 2bc usage
* generate directory tree of final setup