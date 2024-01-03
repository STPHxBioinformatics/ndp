import argparse
from Bio import SeqIO
import os
import glob

def process_bed_entry(entry, fastq_records):
    read_id, start, end = entry
    start, end = int(start), int(end)  # Convert start and end to integers
    record = fastq_records.get(read_id)
    if record:
        sequence = record.seq[start:end]
        quality_string = record.format("fastq").split('\n')[3][start:end]
        return f"@{record.id}_{start}_{end}\n{sequence}\n+\n{quality_string}\n"

def extract_quality_from_bed_sequential(fastq_folder, bed_pattern, output_dir):
    # Create a dictionary to store FASTQ records indexed by the part of the FASTQ filename before ".fastq"
    fastq_records_dict = {}
    for fastq_file in glob.glob(os.path.join(fastq_folder, '*.fastq')):
        base_name = os.path.splitext(os.path.basename(fastq_file))[0]
        prefix = base_name.split('.')[0]
        record = SeqIO.to_dict(SeqIO.parse(fastq_file, 'fastq'))
        fastq_records_dict[prefix] = record

    # Print the prefixes present in the FASTQ files
    print(f"Prefixes found in FASTQ files: {', '.join(fastq_records_dict.keys())}")

    # Iterate over matching BED files
    bed_files = glob.glob(bed_pattern)
    for bed_file in bed_files:
        base_name = os.path.splitext(os.path.basename(bed_file))[0]
        prefix = base_name.split('_bar_')[0]

        # Check if the prefix exists in the dictionary
        if prefix not in fastq_records_dict:
            print(f"Warning: No FASTQ record found for prefix {prefix} in BED file {bed_file}")
            continue

        # Generate output file name based on BED file name
        output_file_name = base_name + '_extracted.fastq'

        # Join output directory and file name
        output_file = None  # Initialize output_file to None
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
            output_file = os.path.join(output_dir, output_file_name)
        else:
            output_file = output_file_name

        print(f"Processing BED file: {bed_file}")
        with open(bed_file, 'r') as bed, open(output_file, 'w') as output:
            bed_entries = [line.strip().split('\t')[:3] for line in bed]
            for entry in bed_entries:
                result = process_bed_entry(entry, fastq_records_dict[prefix])
                if result:
                    output.write(result)
        
        print(f"Quality information extracted and saved to: {output_file}")

def main():
    parser = argparse.ArgumentParser(description='Extract quality information from FASTQ files based on BED file regions.')
    parser.add_argument('fastq_folder', help='Input folder containing FASTQ files')
    parser.add_argument('bed_pattern', help='Input BED file pattern (e.g., *_bar_*.bed)')
    parser.add_argument('-o', '--output_dir', help='Output directory for extracted quality information')
    args = parser.parse_args()

    extract_quality_from_bed_sequential(args.fastq_folder, args.bed_pattern, args.output_dir)

if __name__ == "__main__":
    main()