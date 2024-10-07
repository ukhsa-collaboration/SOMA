#!/usr/bin/env python

# 
# 

__version__ = '0.1'
__date__ = '03-03-2024'
__author__ = 'D.J.BERGER'


###### Dependencies
# X
# X
# X


###### Imports

import argparse

###### Functions

def parse_fasta(fasta_file, keep_unbinned=False):
    parsed_data = []
    with open(fasta_file, 'r') as f:
        for line in f:
            if line.startswith('>'):
                header = line.strip()[1:]
                sample_id, bin_id, contig_id = header.split('.')
                if bin_id != "unbinned" or keep_unbinned:
                    parsed_data.append((header, bin_id))
    return parsed_data

def write_output(parsed_data, output_file):
    with open(output_file, 'w') as f:
        for header, bin_id in parsed_data:
            f.write(f"{header}\t{bin_id}\n")

def main():
    parser = argparse.ArgumentParser(description='Parse fasta file and produce 2-column output.')
    parser.add_argument('--input', type=str, help='Input fasta file path', required=True)
    parser.add_argument('--keep_unbinned', action='store_true', help='Include rows with binid "unbinned"')
    args = parser.parse_args()

    input_file = args.input
    keep_unbinned = args.keep_unbinned

    parsed_data = parse_fasta(input_file, keep_unbinned)

    output_file = "scaffolds.stb"
    write_output(parsed_data, output_file)

if __name__ == "__main__":
    main()
