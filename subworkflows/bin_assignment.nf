/*
 * Identify prokaryotic and archael contigs and assign them to individual genomes (bins)
 * Rename binned and unbinned contigs and output metagenome assembled genomes (MAGs) and complete assemblies (MAGs and unbinned contigs)
 */

include { METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS } from '../modules/nf-core/metabat2/jgisummarizebamcontigdepths/main'                                                                                              
include { METABAT2_METABAT2 } from '../modules/nf-core/metabat2/metabat2/main'                                                                                                                                    
include { DASTOOL_DASTOOL } from '../modules/nf-core/dastool/dastool/main'                                                                                                                                        
include { SEMIBIN_SINGLEEASYBIN } from '../modules/nf-core/semibin/singleeasybin/main'                                                                                                                            
include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2 } from '../modules/nf-core/dastool/fastatocontig2bin/main'                                                                                                                    
include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_METABAT2 } from '../modules/nf-core/dastool/fastatocontig2bin/main'
include { FETCH_UNBINNED } from '../modules/local/fetch_unbinned/main'  
include { RENAME_CONTIGS } from '../modules/local/rename_contigs/main'
include { TIARA_TIARA } from '../modules/nf-core/tiara/tiara/main'                                                                                                                                                
include { FILTER_CONTIGS } from '../modules/local/filter_contigs/main'
include { FILTER_BAM_HEADER } from '../modules/local/filter_bam_header/main'
include { COMEBIN } from '../modules/local/comebin/main'

workflow BIN_ASSIGNMENT {

    take:
    assembly_output   // [ val(meta), path(assembly), path(bam), path(reads), path(bam_index) ]

    main:
    ch_versions = Channel.empty()
    ch_bins_mixed = Channel.empty()

    assembly_output.map { meta -> meta = [meta[0], meta[2], meta[4]]}.set{ ch_indexed_bam }
    assembly_output.map { meta -> meta = [meta[0], meta[1]]}.set{ ch_fasta }
    assembly_output.map { meta -> meta = [meta[0], meta[1], meta[2], meta[4]]}.set{ ch_fasta_bam_index }

    TIARA_TIARA(ch_fasta)
    ch_versions = ch_versions.mix(TIARA_TIARA.out.versions)

    ch_tiara_fasta_bam_index = TIARA_TIARA.out.prokaryote_tiara.join(ch_fasta_bam_index, by: [0])

    FILTER_CONTIGS(ch_tiara_fasta_bam_index)
    FILTER_CONTIGS.out.filt_ref_bam.map { meta -> meta = [meta[0], meta[2], meta[3]]}.set{ ch_filter_bam_index }
    FILTER_CONTIGS.out.filt_ref_bam.map { meta -> meta = [meta[0], meta[2]]}.set{ ch_filter_bam }
    FILTER_CONTIGS.out.filt_ref_bam.map { meta -> meta = [meta[0], meta[1], meta[2]]}.set{ ch_filter_fasta_bam }
    FILTER_CONTIGS.out.filt_ref_bam.map { meta -> meta = [meta[0], meta[1]]}.set{ ch_filter_fasta }

    METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS(ch_filter_bam_index)
    ch_versions = ch_versions.mix(METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.versions)

    ch_metabat_depth = ch_filter_fasta.join(METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS.out.depth, by: [0])

    METABAT2_METABAT2(ch_metabat_depth)
    ch_versions = ch_versions.mix(METABAT2_METABAT2.out.versions)

    FILTER_BAM_HEADER(ch_filter_fasta_bam)
    ch_versions = ch_versions.mix(FILTER_BAM_HEADER.out.versions)

    COMEBIN(FILTER_BAM_HEADER.out.reheader_fasta_bam)
    ch_versions = ch_versions.mix(COMEBIN.out.versions)

    SEMIBIN_SINGLEEASYBIN(ch_filter_fasta_bam)
    ch_versions = ch_versions.mix(SEMIBIN_SINGLEEASYBIN.out.versions)

    DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2(SEMIBIN_SINGLEEASYBIN.out.binned_fastas, "fa")
    DASTOOL_FASTATOCONTIG2BIN_METABAT2(METABAT2_METABAT2.out.fasta, "fa")

    ch_bins_mixed = ch_bins_mixed.mix(DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2.out.fastatocontig2bin)
    ch_bins_mixed = ch_bins_mixed.mix(DASTOOL_FASTATOCONTIG2BIN_METABAT2.out.fastatocontig2bin)
    ch_bins_mixed = ch_bins_mixed.mix(COMEBIN.out.fastatocontig2bin)

    ch_dastool_input_0 = ch_bins_mixed.groupTuple(by: [0])

    ch_dastool_input_1 = ch_fasta.join(ch_dastool_input_0, by: [0])

    DASTOOL_DASTOOL(ch_dastool_input_1, [], [])
    ch_versions = ch_versions.mix(DASTOOL_DASTOOL.out.versions)

    DASTOOL_DASTOOL.out.bins.map({meta -> meta = [meta[0], meta[1]]}).filter(meta -> !meta[1].toString().contains(',')).set{ ch_single_bin }

    ch_ls_assembly = DASTOOL_DASTOOL.out.bins.concat(ch_single_bin).unique()

    ch_fasta_bins = ch_fasta.join(ch_ls_assembly, by: [0])

    FETCH_UNBINNED(ch_fasta_bins)
    ch_versions = ch_versions.mix(FETCH_UNBINNED.out.versions)

    ch_split_assembly = ch_ls_assembly.join(FETCH_UNBINNED.out.unbinned, by: [0])

    RENAME_CONTIGS(ch_split_assembly)

    emit:

    assembled_bins = RENAME_CONTIGS.out.assembled_bins
    complete_assembly = RENAME_CONTIGS.out.complete_assembly
    bin_bam = ch_filter_bam
    versions = ch_versions

}
