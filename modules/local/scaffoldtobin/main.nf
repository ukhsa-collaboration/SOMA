process SCAFFOLD_TO_BIN {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(assembly)

    output:
    tuple val(meta), path(bam), path(assembly), path("*.stb"), optional:true, emit: stb

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """

    scaffolds_to_bin.py \\
    --input $assembly \\
    $args

    """
}
