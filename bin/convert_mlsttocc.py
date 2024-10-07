#!/usr/bin/env python

# Script to assign clonal complex classification to the output of mlst software (https://github.com/tseemann/mlst) or Krocus (https://github.com/andrewjpage/krocus).
# Includes hard coded conversions of six species schemes to matching UKHSA clonal complex schemes (as defined in the clonal_complexes 'json' file).

__version__ = '0.1'
__date__ = '03-03-2024'
__author__ = 'D.J.BERGER'


###### Imports

import json
import pandas as pd
import numpy as np
import argparse


###### Functions

# Process MetaMLST results, assign matching species scheme designation to UKHSA clonal complex scheme names
def process_metamlst(metamlst_results, sample_name):
	metamlst = pd.read_csv(metamlst_results, sep=',', header=None)
	metamlst.columns = ['mlst: Scheme','Sequence type','Confidence','Sample']
	metamlst = metamlst[['mlst: Scheme','Sequence type','Confidence']]
	conditions = [
		(metamlst['mlst: Scheme'] == 'escherichia1'),
		(metamlst['mlst: Scheme'] == 'salmonella'),
		(metamlst['mlst: Scheme'] == 'vibrio'),
		(metamlst['mlst: Scheme'] == 'vparahaemolyticus'),
		(metamlst['mlst: Scheme'] == 'campylobacter')
	]
	values = ['escherichia-coli','salmonella','vibrio','vibrio-parahaemolyticus','campylobacter-jejuni-group']
	metamlst['Internal UKHSA: Scheme'] = np.select(conditions, values)
	metamlst.insert(0, 'Name', sample_name)

	return metamlst



# Subset and rename mlst results, assign matching species scheme designation to UKHSA clonal complex scheme names
def process_mlst(mlst_results, sample_name, bin):
	with open(mlst_results, "r") as infile:
		data = []
		for line in infile:
			columns = line.strip().split('\t')
			name, scheme, ST = columns[:3]
			headers = ["File name", "mlst: Scheme", "Sequence type"] + [col.split('(')[0] for col in columns[3:]]
			values = [name, scheme, ST] + [col.split('(')[1].strip(')') for col in columns[3:]]
			data.append(dict(zip(headers, values)))
			mlst = pd.DataFrame(data)
			conditions = [
				(mlst['mlst: Scheme'] == 'ecoli_achtman_4'),
				(mlst['mlst: Scheme'] == 'senterica_achtman_2'),
				(mlst['mlst: Scheme'] == 'listeria_2'),
				(mlst['mlst: Scheme'] == 'vcholerae'),
				(mlst['mlst: Scheme'] == 'vparahaemolyticus'),
				(mlst['mlst: Scheme'] == 'campylobacter'),
				(mlst['mlst: Scheme'] == 'yersinia_mcnally'),
			]
			values = ['escherichia-coli','salmonella','listeria','vibrio-cholerae','vibrio-parahaemolyticus','campylobacter-jejuni-group','yersinia' ]
			mlst['Internal UKHSA: Scheme'] = np.select(conditions, values)
			mlst.insert(0, 'Sample bin', bin)
			mlst.insert(0, 'Name', sample_name)
			return mlst


# Process Krocus output in the same manner as mlst results (varied to account for output table formats)
def process_krocus(krocus_results, sample_name, bin, scheme):
	with open(krocus_results, "r") as infile:
		data = []
		last_line = infile.readlines()[-1]
		columns = last_line.strip().split('\t')
		name, kmer_cov = columns[:2]
		headers = ["Sequence type", "Kmer coverage"] + [col.split('(')[0] for col in columns[2:]]
		values = [name, kmer_cov] + [col.split('(')[1].strip(')') for col in columns[2:]]
		data.append(dict(zip(headers, values)))
		krocus = pd.DataFrame(data)
		krocus["krocus: Scheme"] = scheme
		conditions = [
			(krocus['krocus: Scheme'] == 'Escherichia coli#1'),
			(krocus['krocus: Scheme'] == 'Salmonella enterica'),
			(krocus['krocus: Scheme'] == 'Listeria monocytogenes'),
			(krocus['krocus: Scheme'] == 'Vibrio cholerae'),
			(krocus['krocus: Scheme'] == 'Vibrio parahaemolyticus'),
			(krocus['krocus: Scheme'] == 'Campylobacter jejuni'),
			(krocus['krocus: Scheme'] == 'Yersinia spp.'),
		]
		values = ['escherichia-coli','salmonella','listeria','vibrio-cholerae','vibrio-parahaemolyticus','campylobacter-jejuni-group','yersinia']
		krocus['Internal UKHSA: Scheme'] = np.select(conditions, values)
		krocus.insert(0, 'Sample bin', bin)
		krocus.insert(0, 'Name', sample_name)
		return krocus


# Process UKHSA clonal complex designations, add clonal complex ID to results table
def extract_json_values(row, cc, mode, output, bin):
	y = json.load(open(cc))
	schemeqq = row['Internal UKHSA: Scheme'].iloc[0]
	ST = "\'" + str(row['Sequence type'].iloc[0]) + "\'"
	row['Internal UKHSA: Clonal complex'] = "NA"
	if 'st_ebg_lookup' in y:
		st_ebg_lookup = y['st_ebg_lookup']
		for key in st_ebg_lookup:
			if schemeqq in key:
				scheme_data = st_ebg_lookup[key]
				for st,val in scheme_data.items():
					if ST in st:
						result = val
						row['Internal UKHSA: Clonal complex'] = result

	outstringtab = output + bin + '.' + mode + '_cc.tsv' # Define output name
	row.to_csv(outstringtab, encoding='utf-8', index=False, sep='\t') # Write to file


def extract_json_values_multi(input, cc, mode, output, bin):
	y = json.load(open(cc))

	if bin == "X":
		outstringtab = output + '.' + mode + '_cc.tsv'
	else:
		outstringtab = output + '.' + bin + '.' + mode + '_cc.tsv' # Define output name

	for index, row in input.iterrows():
		schemeqq = row['Internal UKHSA: Scheme']
		ST = "\'" + str(row['Sequence type']) + "\'"
		row['Internal UKHSA: Clonal complex'] = "NA"
		if 'st_ebg_lookup' in y:
			st_ebg_lookup = y['st_ebg_lookup']
			for key in st_ebg_lookup:
				if schemeqq in key:
					scheme_data = st_ebg_lookup[key]
					for st,val in scheme_data.items():
						if ST in st:
							result = val
							row['Internal UKHSA: Clonal complex'] = result
		df2 = row.to_frame().T
		with open(outstringtab, 'a') as f:
			df2.to_csv(f, mode='a',encoding='utf-8', index=False, sep='\t', header=f.tell()==0)


# Parse arguments from the command line.
def parse_args():
	description = 'Filter and extract data from mlst and Krocus results files. Version: %s, Date: %s, Author: %s' % (__version__, __date__, __author__)
	parser = argparse.ArgumentParser(description=description)
	parser.add_argument('--profile', required=True, help="Results from mlst or krocus")
	parser.add_argument('--clonal_complexes', required=True, help=".json file of clonal complex designations")
	parser.add_argument('--sample', required=True, help="Sample ID")
	parser.add_argument('--bin', required=False, help="Assigned bin")
	parser.add_argument('--output', required=True, help="Output TSV prefix")
	parser.add_argument('--mode', required=True, help="input file type [mlst|krocus|metamlst]")
	parser.add_argument('--krocus_scheme', required=False, help="krocus scheme")
	parser.add_argument("--version", action="version", version='Version: %s' % (__version__))

	return parser.parse_args()

###### Main
def main():
	args = parse_args()

	if args.mode == "mlst":
		mlst = process_mlst(args.profile, args.sample, args.bin)
		extract_json_values(mlst, args.clonal_complexes, args.mode, args.output, args.bin)

	elif args.mode == "krocus":
		krocus = process_krocus(args.profile, args.sample, args.bin, args.krocus_scheme)
		extract_json_values(krocus, args.clonal_complexes, args.mode, args.output, args.bin)

	elif args.mode == "metamlst":
		metamlst = process_metamlst(args.profile, args.sample)
		extract_json_values_multi(metamlst, args.clonal_complexes, args.mode, args.output, "X")

	else:
		print("Incorrect input for parameter --mode , it should be either 'mlst' or 'krocus'")
		exit

if __name__ == "__main__":
	main()

