#!/usr/bin/env python3

import argparse

def split_bed_file(input_file, output_prefix):
    data_dict = {}

    with open(input_file, 'r') as infile:
        for line in infile:
            fields = line.strip().split('\t')
            value_in_column_4 = fields[3]
            if value_in_column_4 not in data_dict:
                data_dict[value_in_column_4] = []
            data_dict[value_in_column_4].append(line)

    for value, lines in data_dict.items():
        output_file = f"{output_prefix}_{value}.bed"
        with open(output_file, 'w') as outfile:
            outfile.writelines(lines)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split BED file based on column 4")
    parser.add_argument("input_file", help="Input BED file")
    parser.add_argument("output_prefix", help="Prefix for output files")

    args = parser.parse_args()
    split_bed_file(args.input_file, args.output_prefix)
