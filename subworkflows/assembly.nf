include { MEGAHIT } from '../modules/nf-core/megahit/main'                                                                                                                                                        
include { BWAMEM2_MEM as BWAMEM2_MEM_MAG_S1 } from '../modules/local/bwamem2/mem/main'
include { BWAMEM2_INDEX as BWAMEM2_INDEX_MAG_S1 } from '../modules/local/bwamem2/index/main'                                                                                                                                            
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_MAG_S1 } from '../modules/nf-core/samtools/index/main'                                                                                                                                          
include { SEQTK_RENAME } from '../modules/nf-core/seqtk/rename/main'                                                                                                                                              

workflow ASSEMBLY {

    take:
    postqc_reads

    main:
    ch_versions = Channel.empty()

    MEGAHIT(postqc_reads)
    ch_versions = ch_versions.mix(MEGAHIT.out.versions)

    SEQTK_RENAME(MEGAHIT.out.contigs)
    ch_versions = ch_versions.mix(SEQTK_RENAME.out.versions)

    BWAMEM2_INDEX_MAG_S1(SEQTK_RENAME.out.sequences)
    ch_versions = ch_versions.mix(BWAMEM2_INDEX_MAG_S1.out.versions)

    ch_merged_reads_index = postqc_reads.join(BWAMEM2_INDEX_MAG_S1.out.index, by: [0])

    BWAMEM2_MEM_MAG_S1(ch_merged_reads_index, true)
    ch_versions = ch_versions.mix(BWAMEM2_MEM_MAG_S1.out.versions)

    SAMTOOLS_INDEX_MAG_S1(BWAMEM2_MEM_MAG_S1.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX_MAG_S1.out.versions)

    ch_mapped_assembly_1 = SEQTK_RENAME.out.sequences.join(BWAMEM2_MEM_MAG_S1.out.bam, by: [0])
    ch_mapped_assembly_2 = ch_mapped_assembly_1.join(postqc_reads, by: [0])
    ch_mapped_assembly_3 = ch_mapped_assembly_2.join(SAMTOOLS_INDEX_MAG_S1.out.bai, by: [0])

    emit:
    ch_mapped_assembly_3
    versions = ch_versions
}
