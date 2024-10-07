include { FASTQC as FASTQC_PRE} from '../modules/nf-core/fastqc/main'
include { FASTP } from '../modules/nf-core/fastp/main'                                                                                                                                                            

workflow READ_QC {

    take:
    reads

    main:
    ch_versions = Channel.empty()

    FASTQC_PRE(reads)
    ch_versions = ch_versions.mix(FASTQC_PRE.out.versions)

    FASTP(reads, [], params.FASTP.savetrimmedfail, params.FASTP.savemerged)
    ch_versions = ch_versions.mix(FASTP.out.versions)

    emit:
    reads = FASTP.out.reads
    read_qc_pre = FASTQC_PRE.out.zip
    ch_read_counts_pre = FASTP.out.json
    versions = ch_versions

}
