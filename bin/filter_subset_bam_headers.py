#!/usr/bin/env python

# Removes contigs names in BAM file headers, when they're not found in an associated BAM file.
# Note: this is normally not a good idea, but it is required input for COMEBin (to avoid remapping to a subset BAM), and will make the BAM file incompatible with various tools (e.g. Samtools)

__version__ = '0.1'
__date__ = '03-07-2024'
__author__ = 'D.J.BERGER'


###### Imports

import pysam
from Bio import SeqIO
import argparse

###### Functions

# Get the relevant contigs, filter the BAM file
def filter_bam_header(bam_path, subset_fasta_path, output_bam_path):
	relevant_contigs = set()
	with open(subset_fasta_path, "r") as fasta_file:
		for record in SeqIO.parse(fasta_file, "fasta"):
			relevant_contigs.add(record.id)

	with pysam.AlignmentFile(bam_path, "rb") as bam_file:
		header = bam_file.header.to_dict()

	header['SQ'] = [sq for sq in header.get('SQ', []) if sq['SN'] in relevant_contigs]

	ref_name_to_id = {sq['SN']: idx for idx, sq in enumerate(header['SQ'])}

	with pysam.AlignmentFile(output_bam_path, "wb", header=header) as output_bam, pysam.AlignmentFile(bam_path, "rb") as bam_file:
		for read in bam_file.fetch(until_eof=True):
			if read.reference_name in relevant_contigs:
				read.reference_id = ref_name_to_id[read.reference_name]
				output_bam.write(read)


# Parse arguments from the command line
def parse_args():
	description = 'Calculates assembly statistics for each assembled genome in a directory. Version: %s, Date: %s, Author: %s' % (__version__, __date__, __author__)
	parser = argparse.ArgumentParser(description=description)
	parser.add_argument("--bam", required=True, help="Path to the input BAM file")
	parser.add_argument("--fasta", required=True, help="Path to the subset FASTA file with relevant contigs")
	parser.add_argument("--output", required=True, help="Path to save the filtered BAM file")
	parser.add_argument("--version", action="version", version='Version: %s' % (__version__))

	return parser.parse_args()


###### Main
def main():
	args = parse_args()

	filter_bam_header(args.bam, args.fasta, args.output)


if __name__ == "__main__":
	main()
