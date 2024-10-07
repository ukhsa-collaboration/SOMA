include { KRAKEN2_KRAKEN2 as KRAKEN2_HOST } from '../modules/nf-core/kraken2/kraken2/main'
include { BWAMEM2_MEM as BWAMEM_HOST } from '../modules/local/bwamem2/mem/main'
include { FASTQC as FASTQC_POST} from '../modules/nf-core/fastqc/main'
include { SAMTOOLS_BAM2FQ } from '../modules/nf-core/samtools/bam2fq/main'                                                                                                                                        

workflow READ_DECONTAMINATION {

    take:
    reads

    main:
    ch_versions = Channel.empty()

    KRAKEN2_HOST(reads, params.KRAKEN2_HOST.db, params.KRAKEN2_HOST.saveoutfastq, params.KRAKEN2_HOST.savereads)
    ch_versions = ch_versions.mix(KRAKEN2_HOST.out.versions)

    ch_reads_index = KRAKEN2_HOST.out.unclassified_reads_fastq.map { meta -> meta = [meta[0], meta[1], params.BWAMEM_HOST.genome] }

    BWAMEM_HOST(ch_reads_index, false)
    ch_versions = ch_versions.mix(BWAMEM_HOST.out.versions)

    SAMTOOLS_BAM2FQ(BWAMEM_HOST.out.bam, true)
    ch_versions = ch_versions.mix(SAMTOOLS_BAM2FQ.out.versions)

    FASTQC_POST(SAMTOOLS_BAM2FQ.out.reads)
    ch_versions = ch_versions.mix(FASTQC_POST.out.versions)

    emit:
    postqc_reads = SAMTOOLS_BAM2FQ.out.reads
    read_qc_post = FASTQC_POST.out.zip
    versions = ch_versions

}
