/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { READ_QC } from '../subworkflows/read_qc.nf'
include { READ_DECONTAMINATION } from '../subworkflows/read_decontamination.nf'
include { READ_QC_SUMMARY } from '../subworkflows/read_qc_summary.nf'
include { ASSEMBLY } from '../subworkflows/assembly.nf'
include { BIN_ASSIGNMENT } from '../subworkflows/bin_assignment.nf'
include { READ_TYPING } from '../subworkflows/read_typing.nf'
include { TAXONOMIC_PROFILING } from '../subworkflows/taxonomic_profiling.nf'
include { BIN_QC } from '../subworkflows/bin_qc.nf'
include { CONTIG_QC } from '../subworkflows/contig_qc.nf'
include { BIN_TAXONOMY } from '../subworkflows/bin_taxonomy.nf'
include { BACTERIAL_TYPING } from '../subworkflows/bacterial_typing.nf'

include { CREATE_REPORT } from '../subworkflows/create_report.nf'

include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SOMA {

    ch_versions = Channel.empty()
//    ch_multiqc_files = Channel.empty()
    ch_final_report = Channel.empty()

    Channel
     .fromPath(params.input, checkIfExists: true)
     .splitCsv(header:true)
     .ifEmpty{ throw new IllegalArgumentException("No input rows in file: $params.input") }
     .filter { row -> if (row.sample_id == null || row.sample_id == "") {throw new IllegalArgumentException("Missing or null value of 'sample_id' for input: \n\nsample_id:\t\t$row.sample_id\nrow_id:\t\t\t$row.run_id\nsample_type:\t\t$row.sample_type\ngroup:\t\t\t$row.group\nread1:\t\t\t$row.read1\nread2:\t\t\t$row.read2\n")} else {return true} }
     .filter { row -> if (row.run_id == null || row.run_id == "") {throw new IllegalArgumentException("Missing or null value of 'run_id' for input: \n\nsample_id:\t\t$row.sample_id\nrow_id:\t\t\t$row.run_id\nsample_type:\t\t$row.sample_type\ngroup:\t\t\t$row.group\nread1:\t\t\t$row.read1\nread2:\t\t\t$row.read2\n")} else {return true} }
     .filter { row -> if (row.read1 == null || row.read1 == "" ) {throw new IllegalArgumentException("Missing or null value of 'read1' for input: \n\nsample_id:\t\t$row.sample_id\nrow_id:\t\t\t$row.run_id\nsample_type:\t\t$row.sample_type\ngroup:\t\t\t$row.group\nread1:\t\t\t$row.read1\nread2:\t\t\t$row.read2\n")} else {return true} }
     .filter { row -> if (row.read2 == null || row.read2 == "") {throw new IllegalArgumentException("Missing or null value of 'read2' for input: \n\nsample_id:\t\t$row.sample_id\nrow_id:\t\t\t$row.run_id\nsample_type:\t\t$row.sample_type\ngroup:\t\t\t$row.group\nread1:\t\t\t$row.read1\nread2:\t\t\t$row.read2\n")} else {return true} }
     .map { row -> meta = [[id: row.sample_id.replaceAll('\\.','_'), run_id: row.run_id.replaceAll('\\.','_'), barcode: (row.barcode ?: 'NA'), target: (row.sample_type ?: 'NA'), group: (row.group ?: 'NA') ], [file(row.read1, checkIfExists: true), file(row.read2, checkIfExists: true)]]}
     .set {ch_reads}

    READ_QC(ch_reads)
    ch_versions = ch_versions.mix(READ_QC.out.versions)

    ch_final_report = ch_final_report.mix(READ_QC.out.ch_read_counts_pre)

    READ_DECONTAMINATION(READ_QC.out.reads)
    ch_versions = ch_versions.mix(READ_DECONTAMINATION.out.versions)

    READ_QC_SUMMARY(READ_QC.out.read_qc_pre, READ_DECONTAMINATION.out.read_qc_post)
    ch_versions = ch_versions.mix(READ_QC_SUMMARY.out.versions)

    ch_final_report = ch_final_report.mix(READ_QC_SUMMARY.out.ch_mqc_reports)

    READ_TYPING(READ_DECONTAMINATION.out.postqc_reads)
    ch_versions = ch_versions.mix(READ_TYPING.out.versions)

    ch_final_report = ch_final_report.mix(READ_TYPING.out.ch_metamlst_report)

    if (!params.skip_taxonomic_profiling ) {
        TAXONOMIC_PROFILING(READ_DECONTAMINATION.out.postqc_reads)
        ch_versions = ch_versions.mix(TAXONOMIC_PROFILING.out.versions)

        ch_final_report = ch_final_report.mix(TAXONOMIC_PROFILING.out.ch_taxreports)
        }

    if (!params.skip_assembly ) {
        ASSEMBLY(READ_DECONTAMINATION.out.postqc_reads)
        ch_versions = ch_versions.mix(ASSEMBLY.out.versions)

        BIN_ASSIGNMENT(ASSEMBLY.out.ch_mapped_assembly_3)
        ch_versions = ch_versions.mix(BIN_ASSIGNMENT.out.versions)

        CONTIG_QC(BIN_ASSIGNMENT.out.complete_assembly, READ_DECONTAMINATION.out.postqc_reads)
        ch_versions = ch_versions.mix(CONTIG_QC.out.versions)

        BIN_QC(BIN_ASSIGNMENT.out.assembled_bins, CONTIG_QC.out.ch_plt_p1)
        ch_versions = ch_versions.mix(BIN_QC.out.versions)

        ch_final_report = ch_final_report.mix(BIN_QC.out.ch_binreports)

        BIN_TAXONOMY(BIN_QC.out.ch_bin_taxonomy, CONTIG_QC.out.complete_assembly_bam)
        ch_versions = ch_versions.mix(BIN_TAXONOMY.out.versions)

        if (!params.skip_bacterial_typing ) {
            BACTERIAL_TYPING(BIN_TAXONOMY.out.ch_prokarya_reads)
            ch_versions = ch_versions.mix(BACTERIAL_TYPING.out.versions)

            ch_final_report = ch_final_report.mix(BACTERIAL_TYPING.out.ch_amr_reports)
            ch_final_report = ch_final_report.mix(BACTERIAL_TYPING.out.ch_ecoli_report)
            ch_final_report = ch_final_report.mix(BACTERIAL_TYPING.out.ch_salmonella_report)
            ch_final_report = ch_final_report.mix(BACTERIAL_TYPING.out.ch_lmonocytogenes_report)
            ch_final_report = ch_final_report.mix(BACTERIAL_TYPING.out.ch_targetedtyping_reports)
            ch_final_report = ch_final_report.mix(BACTERIAL_TYPING.out.ch_sequencetyping_reports)

        }
    }

    CREATE_REPORT(ch_final_report)
    ch_versions = ch_versions.mix(CREATE_REPORT.out.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS (ch_versions.unique().collectFile(name: 'collated_versions.yml'))
    

}
