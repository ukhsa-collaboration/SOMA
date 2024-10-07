//include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_MERGE } from '../modules/local/minimap2/align/main.nf'
include { GENOMAD_ENDTOEND } from '../modules/nf-core/genomad/endtoend/main'
include { SKANI_SEARCH } from '../modules/local/skani/search/main.nf'
include { SEQKIT_FX2TAB } from '../modules/nf-core/seqkit/fx2tab/main'                                                                                                                                            
include { SAMTOOLS_COVERAGE } from '../modules/nf-core/samtools/coverage/main'                                                                                                                                    

include { BWAMEM2_MEM as BWAMEM2_MEM_MAG_S2 } from '../modules/local/bwamem2/mem/main'
include { BWAMEM2_INDEX as BWAMEM2_INDEX_MAG_S2 } from '../modules/local/bwamem2/index/main'                                                                                                                                            
include { SAMTOOLS_INDEX as SAMTOOLS_INDEX_MAG_S2 } from '../modules/nf-core/samtools/index/main'                                                                                                                                          

include { INSTRAIN_PROFILE } from '../modules/nf-core/instrain/profile/main'                                                                                                                                      
include { SCAFFOLD_TO_BIN } from '../modules/local/scaffoldtobin/main'

workflow CONTIG_QC {

    take:
    ch_complete_assembly
    cleaned_reads

    main:
    ch_versions = Channel.empty()

    BWAMEM2_INDEX_MAG_S2(ch_complete_assembly)
    ch_index_reads = cleaned_reads.join(BWAMEM2_INDEX_MAG_S2.out.index, by: [0])

    BWAMEM2_MEM_MAG_S2(ch_index_reads, true)
    ch_versions = ch_versions.mix(BWAMEM2_MEM_MAG_S2.out.versions)

    SEQKIT_FX2TAB(ch_complete_assembly)
    ch_versions = ch_versions.mix(SEQKIT_FX2TAB.out.versions)

    SAMTOOLS_COVERAGE(BWAMEM2_MEM_MAG_S2.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_COVERAGE.out.versions)

    BWAMEM2_MEM_MAG_S2.out.bam.join(ch_complete_assembly, by: [0]).set{ch_t1}

    if (params.GENOMAD_ENDTOEND.db) {
        GENOMAD_ENDTOEND(ch_complete_assembly, params.GENOMAD_ENDTOEND.db)
        ch_versions = ch_versions.mix(GENOMAD_ENDTOEND.out.versions)
    }

    if (params.SKANI_SEARCH.db) {    
        SKANI_SEARCH(ch_complete_assembly, params.SKANI_SEARCH.db)
        ch_versions = ch_versions.mix(SKANI_SEARCH.out.versions)
    }

//    SCAFFOLD_TO_BIN(ch_t1)

//    INSTRAIN_PROFILE(SCAFFOLD_TO_BIN.out.stb)
//    ch_versions = ch_versions.mix(INSTRAIN_PROFILE.out.versions)

    if (params.GENOMAD_ENDTOEND.db) {
        if (params.SKANI_SEARCH.db) {
            ch_p1_1 = SAMTOOLS_COVERAGE.out.coverage.join(SEQKIT_FX2TAB.out.text, by:[0])
            ch_p1_2 = ch_p1_1.join(SKANI_SEARCH.out.summary, by:[0])
            ch_plt_p1 = ch_p1_2.join(GENOMAD_ENDTOEND.out.plasmid_summary, by:[0])
        }
    }
    else (ch_plt_p1 = Channel.empty())

    emit:
    complete_assembly_bam = BWAMEM2_MEM_MAG_S2.out.bam
    ch_plt_p1
    versions = ch_versions

}


