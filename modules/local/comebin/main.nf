process COMEBIN {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/comebin:1.0.4--hdfd78af_0' :
        'https://depot.galaxyproject.org/singularity/comebin:1.0.4--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta), path(bam)

    output:
    tuple val(meta), path("*.comebin.tsv"), emit: fastatocontig2bin, optional: true
    path "versions.yml"                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args             = task.ext.args   ?: ''
    def prefix           = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}_comebin_results
    mkdir bam_temp

    mv *.bam bam_temp/

    run_comebin.sh \\
       $args \\
       -a $fasta \\
       -p bam_temp/ \\
       -o ${prefix}_comebin_results \\
       -t $task.cpus  2>/dev/null || echo ""

    cat *_comebin_results/comebin_res/comebin_res.tsv | awk '\$2!="group0"' | awk '{print \$1,"${meta.id}"".comebin."\$2}' OFS='\t' > ${prefix}.comebin.tsv 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        COMEbin: \$( run_comebin.sh | grep "COMEBin version" | cut -f2 -d":" | sed 's/^ //g' )
    END_VERSIONS
    """
}
