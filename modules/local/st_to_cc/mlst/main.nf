process MLST_TO_CC {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(mlst)
    path(gastro_cc_db)
    val(mode)

    output:
    tuple val(meta), path("*.mlst_cc.tsv"), emit: mlst

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mode_param = mode.matches("MLST") ? "--mode mlst" : "--mode krocus --krocus_scheme ${meta.krocus_scheme}"

    """
    python $baseDir/scripts/mlst_cc.py --profile $mlst --clonal_complexes $gastro_cc_db --output ${meta.id} --sample ${meta.id} --bin ${meta.bin} $mode_param

    """
}
