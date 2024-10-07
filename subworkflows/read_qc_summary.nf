include { MULTIQC } from '../modules/nf-core/multiqc/main'                                                                                                                                                        

workflow READ_QC_SUMMARY {

    take:
    fastqc_pre
    fastqc_post

    main:
    ch_versions = Channel.empty()
    
    fastqc_pre.mix(fastqc_post).transpose().groupTuple(by: [0], remainder: false).set{ merged_fastqc_reports }

    MULTIQC(merged_fastqc_reports, [], [], [])
    ch_versions = ch_versions.mix(MULTIQC.out.versions)

    emit:
    ch_mqc_reports = MULTIQC.out.data
    versions = ch_versions

}
