process MAXBIN2 {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/maxbin2:2.2.7--he1b5a44_2' :
        'https://depot.galaxyproject.org/singularity/maxbin2:2.2.7--he1b5a44_2' }"

    input:
    tuple val(meta), path(contigs), path(reads), path(abund)

    output:
    tuple val(meta), path("*.fasta.gz")   , optional: true, emit: binned_fastas
    tuple val(meta), path("*.summary")    , optional: true, emit: summary
    tuple val(meta), path("*.log.gz")     , optional: true, emit: log
    tuple val(meta), path("*.marker.gz")  , optional: true, emit: marker_counts
    tuple val(meta), path("*.noclass.gz") , optional: true, emit: unbinned_fasta
    tuple val(meta), path("*.tooshort.gz"), optional: true, emit: tooshort_fasta
    tuple val(meta), path("*_bin.tar.gz") , optional: true, emit: marker_bins
    tuple val(meta), path("*_gene.tar.gz"), optional: true, emit: marker_genes
    path "versions.yml"                   , optional: true, emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def associate_files = reads ? "-reads $reads" : "-abund $abund"
    """
    mkdir input/ && mv $contigs input/
    run_MaxBin.pl \\
        -contig input/$contigs \\
        $associate_files \\
        -thread $task.cpus \\
        $args \\
        -out $prefix 2>/dev/null || echo ""

    gzip *.fasta *.noclass *.tooshort *log *.marker 2>/dev/null || echo ""

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        maxbin2: \$( run_MaxBin.pl -v | head -n 1 | sed 's/MaxBin //' )
    END_VERSIONS
    """
}
