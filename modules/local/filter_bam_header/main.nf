process FILTER_BAM_HEADER {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/djberger/soma_pysam:latest' :
        'quay.io/djberger/soma_pysam:latest' }"

    input:
    tuple val(meta), path(fasta), path(bam)

    output:
    tuple val(meta), path(fasta), path("*.reheader.bam"), emit: reheader_fasta_bam
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filter_subset_bam_headers.py \\
       $args \\
       --bam $bam \\
       --fasta $fasta \\
       --output ${prefix}.reheader.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filter_subset_bam_headers.py: \$(filter_subset_bam_headers.py --version 2>&1 | cut -f2 -d " ")
    END_VERSIONS

    """
}
