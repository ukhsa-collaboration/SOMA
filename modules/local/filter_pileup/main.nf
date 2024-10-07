process FILTER_PILEUP {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(coverage)

    output:
    tuple val(meta), path('*.abundance.txt')                 , emit: abundance

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    awk '{print \$1"\t"\$2}' $coverage | grep -v '^#' > ${prefix}.abundance.txt

    """
}





