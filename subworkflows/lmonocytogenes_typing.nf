/*
 * Type Listeria monocytogenes genomes
 */

include { LISSERO } from '../modules/nf-core/lissero/main'                                                                                                                                                        

workflow LMONOCYTOGENES_TYPING {

    take:
    ch_lmonocytogenes   // channel: [ val(meta), path(assembly) ]

    main:
    // Runs typing method specific to Listeria monocytogenes

    ch_versions = Channel.empty()

    ch_lmonocytogenes_assembly = ch_lmonocytogenes.map{meta -> meta = [meta[0],meta[1]]}


    // Listeria monocytogenes serotype prediction
    LISSERO(ch_lmonocytogenes_assembly)
    ch_versions = ch_versions.mix(LISSERO.out.versions)

    emit:
    ch_lmonocytogenes_report = LISSERO.out.tsv
    versions = ch_versions
}
