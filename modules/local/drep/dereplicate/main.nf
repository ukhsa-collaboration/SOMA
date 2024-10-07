process DREP_DEREPLICATE {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/drep:3.5.0--pyhdfd78af_0':
        'quay.io/biocontainers/drep:3.5.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path("bins/*")

    output:
    tuple val(meta), path("out/dereplicated_genomes/*.fa"), optional: true, emit: dereplicated_bins
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir out/

    dRep \\
      dereplicate \\
      out \\
      -comp 50 \\
      -p $task.cpus \\
      -g bins/* \\
      $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dRep: \$(echo \$(dRep | grep "::" | cut -f19 -d " " | sed 's/v//g'))
    END_VERSIONS
    """
}
