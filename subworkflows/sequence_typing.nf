/*
 * Perform multilocus sequence typing (MLST) and clonal complex (CC) assignment 
 */

include { MLST } from '../modules/nf-core/mlst/main'
include { CONVERT_MLSTTOCC as CONVERT_MLSTTOCC } from '../modules/local/convert_mlsttocc/main'

workflow SEQUENCE_TYPING {

    take:
    ch_merged // channel: [ val(meta), path(assembly), path(reads) ]

    main:
    // Perform MLST analysis using assembly-based (MLST) tools, assign CC using user provided file.

    ch_versions = Channel.empty()
    ch_mlst = Channel.empty()
    ch_mlst_reports = Channel.empty()

    // Get assemblies
    ch_secondary_b = ch_merged.map{meta -> meta = [meta[0],meta[1]]}

    // Determine sequence type from assembly
    MLST(ch_secondary_b)
    ch_versions = ch_versions.mix(MLST.out.versions)

    ch_mlst_reports = ch_mlst_reports.mix(MLST.out.tsv)

    // If user provides CC definitions file, then add CC to MLST results
    if (params.SEQUENCE_TYPING.cc_definitions) {
        CONVERT_MLSTTOCC(MLST.out.tsv, "mlst", params.SEQUENCE_TYPING.cc_definitions)
        ch_versions = ch_versions.mix(CONVERT_MLSTTOCC.out.versions)

        ch_mlst = CONVERT_MLSTTOCC.out.mlstwithcc
        ch_mlst_reports = ch_mlst_reports.mix(CONVERT_MLSTTOCC.out.mlstwithcc)

    }

    emit:
    // Emit MLST results
    ch_mlst
    ch_mlst_reports

    versions = ch_versions
}
