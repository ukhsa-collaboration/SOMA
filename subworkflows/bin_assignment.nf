include { METABAT2_JGISUMMARIZEBAMCONTIGDEPTHS } from '../modules/nf-core/metabat2/jgisummarizebamcontigdepths/main'                                                                                              
include { METABAT2_METABAT2 } from '../modules/nf-core/metabat2/metabat2/main'                                                                                                                                    
include { MAXBIN2 } from '../modules/nf-core/maxbin2/main'                                                                                                                                                        
include { FASTA_BINNING_CONCOCT } from '../subworkflows/nf-core/fasta_binning_concoct/main'                                                                                                                       
include { DASTOOL_DASTOOL } from '../modules/nf-core/dastool/dastool/main'                                                                                                                                        
include { SAMTOOLS_INDEX } from '../modules/nf-core/samtools/index/main'                                                                                                                                          
include { SEMIBIN_SINGLEEASYBIN } from '../modules/nf-core/semibin/singleeasybin/main'                                                                                                                            
include { BBMAP_PILEUP } from '../modules/nf-core/bbmap/pileup/main'                                                                                                                                              
include { FILTER_PILEUP } from '../modules/local/filter_pileup/main'

include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2 } from '../modules/nf-core/dastool/fastatocontig2bin/main'                                                                                                                    
include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_METABAT2 } from '../modules/nf-core/dastool/fastatocontig2bin/main'
include { DASTOOL_FASTATOCONTIG2BIN as DASTOOL_FASTATOCONTIG2BIN_MAXBIN2 } from '../modules/nf-core/dastool/fastatocontig2bin/main'

include { FETCH_UNBINNED } from '../modules/local/fetch_unbinned/main'  
include { RENAME_CONTIGS } from '../modules/local/rename_contigs/main'
include { TIARA_TIARA } from '../modules/nf-core/tiara/tiara/main'                                                                                                                                                
include { FILTER_CONTIGS } from '../modules/local/filter_contigs/main'

//include { DREP_DEREPLICATE } from '../modules/local/drep/dereplicate/main'

workflow BIN_ASSIGNMENT {

    take:
    assembly_output

    main:
    ch_versions = Channel.empty()
    ch_bins_mixed = Channel.empty()

    assembly_output.map { meta -> meta = [meta[0], meta[2], meta[4]]}.set{ ch_indexed_bam }
    assembly_output.map { meta -> meta = [meta[0], meta[1]]}.set{ ch_fasta }
    assembly_output.map { meta -> meta = [meta[0], meta[1], meta[3], []]}.set{ ch_fasta_reads }
    assembly_output.map { meta -> meta = [meta[0], meta[1], meta[2]]}.set{ ch_fasta_bam }
    assembly_output.map { meta -> meta = [meta[0], meta[2]]}.set{ ch_bam }
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

//    FASTA_BINNING_CONCOCT(ch_fasta, ch_indexed_bam)
//    ch_versions = ch_versions.mix(FASTA_BINNING_CONCOCT.out.versions)

    BBMAP_PILEUP(ch_filter_bam)
    ch_versions = ch_versions.mix(BBMAP_PILEUP.out.versions)

    FILTER_PILEUP(BBMAP_PILEUP.out.covstats)

    ch_maxbin_input = ch_filter_fasta.join(FILTER_PILEUP.out.abundance, by: [0]).map {meta -> meta = [meta[0], meta[1],[], meta[2]]}

    MAXBIN2(ch_maxbin_input)
    ch_versions = ch_versions.mix(MAXBIN2.out.versions)

    SEMIBIN_SINGLEEASYBIN(ch_filter_fasta_bam)
    ch_versions = ch_versions.mix(SEMIBIN_SINGLEEASYBIN.out.versions)

    DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2(SEMIBIN_SINGLEEASYBIN.out.binned_fastas, "fa")
    DASTOOL_FASTATOCONTIG2BIN_METABAT2(METABAT2_METABAT2.out.fasta, "fa")
    DASTOOL_FASTATOCONTIG2BIN_MAXBIN2(MAXBIN2.out.binned_fastas, "fasta")

//    ch_dastool_input_0 = DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2.out.fastatocontig2bin.concat( DASTOOL_FASTATOCONTIG2BIN_METABAT2.out.fastatocontig2bin, DASTOOL_FASTATOCONTIG2BIN_MAXBIN2.out.fastatocontig2bin ).groupTuple(by: [0])
    ch_bins_mixed = ch_bins_mixed.mix(DASTOOL_FASTATOCONTIG2BIN_SEMIBIN2.out.fastatocontig2bin)
    ch_bins_mixed = ch_bins_mixed.mix(DASTOOL_FASTATOCONTIG2BIN_METABAT2.out.fastatocontig2bin)
    ch_bins_mixed = ch_bins_mixed.mix(DASTOOL_FASTATOCONTIG2BIN_MAXBIN2.out.fastatocontig2bin)

    ch_dastool_input_0 = ch_bins_mixed.groupTuple(by: [0])

    ch_dastool_input_1 = ch_fasta.join(ch_dastool_input_0, by: [0])

    DASTOOL_DASTOOL(ch_dastool_input_1, [], [])
    ch_versions = ch_versions.mix(DASTOOL_DASTOOL.out.versions)

    DASTOOL_DASTOOL.out.bins.map({meta -> meta = [meta[0], meta[1]]}).filter(meta -> !meta[1].toString().contains(',')).set{ ch_single_bin }
//    DASTOOL_DASTOOL.out.bins.map({meta -> meta = [meta[0], meta[1]]}).filter(meta -> meta[1].toString().contains(',')).set{ ch_multi_bin }

//    if (params.BIN_ASSIGNMENT.drep == true ) {
//       DREP_DEREPLICATE(ch_multi_bin)
//       ch_versions = ch_versions.mix(DREP_DEREPLICATE.out.versions)
//       ch_ls_assembly = DREP_DEREPLICATE.out.dereplicated_bins.concat(ch_single_bin).unique()
//    }
//    else {ch_ls_assembly = DASTOOL_DASTOOL.out.bins.concat(ch_single_bin).unique()}

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
