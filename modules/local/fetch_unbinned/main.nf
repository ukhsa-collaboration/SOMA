process FETCH_UNBINNED {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqkit:2.4.0--h9ee0642_0':
        'biocontainers/seqkit:2.4.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(original_assembly), path(bins)

    output:
    tuple val(meta), path("*.unbinned.fa"), emit: unbinned
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mv $original_assembly original_assembly.fasta.gz
    cat *.fa | awk 'sub(/^>/, "")' > assigned_contigs.txt

    seqkit \\
        grep \\
        $args \\
        --threads $task.cpus \\
        -v \\
        -f assigned_contigs.txt \\
        -o ${prefix}.unbinned.fa \\
        original_assembly.fasta.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$( seqkit | sed '3!d; s/Version: //' )
    END_VERSIONS

    """
}
