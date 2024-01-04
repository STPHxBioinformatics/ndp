// Hey there!
// Welcome to our custom demultiplexing pipeline built to filter, quality control, demultiplex and annotate
// single or double barcoded 16srRNA amplicons sequenced on the ONT MinION platform (singlex or duplex reads).

// Before you start the pipeline please make sure you check the following things:
// 1) Make sure you follow the laboratory procedure as described in DOI-XXX
// 2) Basecall your POD5 files using Dorado (singlex/duplex) and then demultiplex via the outer ONT barcodes using 'guppy_barcoder' or 'dorado demux'.
// 3) Make sure your input reads are in .fastq format
// 4) Choose a short name for your reads that includes the outer ONT barcode used (for example: 'duplex_25.fastq' or 'singlex_25.fastq').
// 5) Generate an INPUT_FOLDER and OUTPUT_FOLDER for each run under PATH/TO/ndp/
// 6) Adjust your working directory WD, INPUT_FOLDER and OUTPUT_FOLDER directory in this script BEFORE the run (input: params.reads, output: params.outdir)
// 7) Adjust the paths for your stdout and stderr files in your SLURM script!
// 8) Enjoy! :)

nextflow.enable.dsl=2
wd = "/PATH/TO/ndp/"                               //adjust your WD here! The 'wd' must be the parent of 'INPUT_FOLDER' / 'OUTPUT_FOLDER'!
params.reads = "/PATH/TO/ndp/INPUT_FOLDER/*.fastq"        //adjust your INPUT_FOLDER directory here!
params.outdir = "/PATH/TO/ndp/OUTPUT_FOLDER/"             //adjust your OUTPUT_FOLDER directory here!

log.info """\
	
	==========================================
	SWISS-TPH NANOPORE DEMULTIPLEXING PIPELINE
	==========================================
	reads directory: 	${params.reads}
	output directory: 	${params.outdir}
	==========================================
	HAVE FUN :)
	"""
	.stripIndent()

// Filter reads based on quality and length
// Adjust parameters via the '-l', '--maxlength' or the '-q' option
// Check the Nanofilt manual for more details under: https://github.com/wdecoster/nanofilt 

process filtering {

	publishDir "${params.outdir}01_filtered_reads/", mode: 'copy', pattern: '*.fastq'
		
	input:
	path(reads)
	
	output:
	path("f_${reads}")
	
	script:
	"""
	singularity run ${wd}0_singularity_containers/nanofilt2.8.0.sif NanoFilt -l 1300 --maxlength 1800 -q 9 ${reads} > f_${reads}
	"""
}

// Generate FastQC report for each read
// Check the FastQC manual for more details under: https://github.com/s-andrews/FastQC

process fastqc {		
	
	input:
	path(reads)
	
	output:
	file "*_fastqc.{zip,html}"
	
	script:
	"""
	singularity run ${wd}0_singularity_containers/fastqc0.11.8.sif fastqc -q $reads
	"""
}

// Generate combined MultiQC report
// Check the MultiQC manual for more details under: https://github.com/ewels/MultiQC

process multiqc {	

	publishDir "${params.outdir}02_quality_control/", mode: 'copy', pattern: '*.html'	
	
	input:
	file ('fastqc/*')

	output:
	file "multiqc_report.html"
	file "multiqc_data"

	script:
	"""
	singularity run ${wd}0_singularity_containers/multiqc1.9.sif multiqc .
	"""
}

// Generate BED files with all barcode sequence(s) found in the reads
// Trimming based on barcode sequence(s) found in the reads
// Barcode file '2bc.tab' can be adjusted to search different barcode/primer sequences
// Adjust mismatch tolerance for barcode matches here via the option '-m'
// Check the seqkit manual for more details under: https://bioinf.shenwei.me/seqkit/

process bed {

	publishDir "${params.outdir}03_bed_files/", mode: 'copy', pattern: '*.bed'	
	
	input:
	path(reads)
	
	output:
	file "${reads.baseName}.bed"
	
	script:
	"""
	singularity run ${wd}0_singularity_containers/seqkit2.6.1.sif seqkit amplicon -m 1 -p ${wd}0_scripts/1bc.tab -r 32:-21 ${reads} --bed > "${reads.baseName}.bed"
	"""
}

// Split BED files based on barcode sequence(s) found in each read

process split_bed {

	publishDir "${params.outdir}04_split_bed_files/", mode: 'copy', pattern: '*.bed'	
	
	input:
	path(reads)
	
	output:
	file "*.bed"
	
	script:
	"""
	singularity exec ${wd}0_singularity_containers/python3.10.4.sif python3 ${wd}0_scripts/split_bed_files.py ${reads} "${reads.baseName}_bar"

	"""
}

// Extract quality information from original fastq file based on split BED files
// Generating the final demultiplexed fastq files

process generate_fastq {

	publishDir params.outdir, mode: 'copy', pattern: '*/*.fastq'	
	
	input:
	path(reads)
	
	output:
	path ("*/*.fastq")
	
	script:
	"""
	singularity exec ${wd}0_singularity_containers/biopython1.78.sif python3 ${wd}0_scripts/extract_quality.py ${params.outdir}01_filtered_reads/ ${params.outdir}04_split_bed_files/"*_bar_???.bed" -o ./05_final_fastqs
	"""
}

// Taxonomic annotation of the final reads
// Check the seqkit manual for more details under: https://gitlab.com/treangenlab/emu

process emu {	
	
	publishDir params.outdir, mode: 'copy', pattern: '*/*/*.tsv'
	errorStrategy 'ignore'

	input:
	path(reads)
	
	output:
	path ("*/*/*.tsv")
	
	script:
	"""
	export EMU_DATABASE_DIR=${wd}0_emu_db
	singularity run ${wd}0_singularity_containers/emu3.4.5.sif emu abundance ${reads} --min-abundance 0.01 --threads 16 --output-dir ./06_emu_abundance/emu_${reads.baseName} --keep-files --keep-read-assignments --keep-counts
	"""
}


workflow {
	def reads_ch = channel.fromPath(params.reads)
	filtering(reads_ch)
	filtered_reads_ch = filtering.out
	
	fastqc(filtered_reads_ch.collect())
	fastqc_reads_ch = fastqc.out

	multiqc(fastqc_reads_ch.collect())

	bed(filtered_reads_ch)
	bed_reads_ch = bed.out

	split_bed(bed_reads_ch.flatMap())
	split_bed_ch = split_bed.out

	generate_fastq(split_bed_ch.collect())
	generate_fastq_ch = generate_fastq.out

	emu(generate_fastq_ch.flatMap())
	emu_reads_ch = emu.out

}