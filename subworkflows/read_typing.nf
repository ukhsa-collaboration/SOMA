include { METAMLST } from '../modules/local/metamlst/main'
include { CONVERT_MLSTTOCC as CONVERT_METAMLSTTOCC } from '../modules/local/convert_mlsttocc/main'

workflow READ_TYPING {

    take:
    cleaned_reads

    main:

    // Perform MLST analysis using assembly-based (MLST) tools, assign CC using user provided file.

    ch_versions = Channel.empty()
    ch_metamlst_report = Channel.empty()
    
    METAMLST(cleaned_reads, params.METAMLST.db)
    ch_versions = ch_versions.mix(METAMLST.out.versions)

    // If user provides CC definitions file, then add CC to MLST results
    if (params.SEQUENCE_TYPING.cc_definitions) {
        CONVERT_METAMLSTTOCC(METAMLST.out.tsv, "metamlst", params.SEQUENCE_TYPING.cc_definitions)
        ch_versions = ch_versions.mix(CONVERT_METAMLSTTOCC.out.versions)

        ch_metamlst_report = ch_metamlst_report.mix(CONVERT_METAMLSTTOCC.out.mlstwithcc)

    }

//    DEEPARG_SR(cleaned_reads, "/data/PROJECTS/DB_ONT_PIPELINE_TEST/soma_v0.2/data/deeparg/database")
//  GROOT()


    emit:
    versions = ch_versions
    ch_metamlst_report

}
