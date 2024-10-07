process SUMMARIZE_GENEFINDING {
    tag "$meta.id"
    label 'process_single'

    input:
    tuple val(meta), path(blastn), path(genefinder), path(virulencefinder)

    output:
    tuple val(meta), path("*.gene_hits.tsv"), emit: merged_results
    tuple val(meta), path("*.gene_hits.summary.tsv"), emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def opt = virulencefinder.toString().matches("") ? "" : "--virulencefinder $virulencefinder"
    def opt2 = genefinder.toString().matches("") ? "" : "--genefinder $genefinder"


    """
    summarize_gene_hits.py \\
       $opt \\
       --bin ${meta.bin} \\
       --blastn $blastn \\
       $opt2 \\
       --output ${prefix} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        summarize_gene_hits.py: \$(summarize_gene_hits.py --version 2>&1 | tail -1 | cut -f2 -d " ")
    END_VERSIONS

    """
}
