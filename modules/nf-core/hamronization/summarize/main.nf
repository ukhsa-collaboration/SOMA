process HAMRONIZATION_SUMMARIZE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/hamronization:1.1.4--pyhdfd78af_0' :
        'https://depot.galaxyproject.org/singularity/hamronization:1.1.4--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reports)
    each format

    output:
    path("*.hamronization_combined_report.json"), optional: true, emit: json
    path("*.hamronization_combined_report.tsv") , optional: true, emit: tsv
    path("*.hamronization_combined_report.html"), optional: true, emit: html
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def outformat = format == 'interactive' ? 'html' : format
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    hamronize \\
        summarize \\
        ${reports} \\
        -t ${format} \\
        $args \\
        -o ${prefix}.hamronization_combined_report.${outformat}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hamronization: \$(echo \$(hamronize --version 2>&1) | cut -f 2 -d ' ' )
    END_VERSIONS
    """

    stub:
    def outformat = format == 'interactive' ? 'html' : format
    """
    touch hamronization_combined_report.${outformat}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hamronization: \$(echo \$(hamronize --version 2>&1) | cut -f 2 -d ' ' )
    END_VERSIONS
    """
}
