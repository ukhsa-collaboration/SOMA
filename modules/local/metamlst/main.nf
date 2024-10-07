process METAMLST {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/metamlst:1.2.3--hdfd78af_0' :
        'quay.io/biocontainers/metamlst:1.2.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val(meta), path('*.classified{.,_}*')     , optional:true, emit: classified_reads_fastq
    tuple val(meta), path("*.metamlst_report.tsv"), optional: true, emit: tsv
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    INDEX=`find -L */ -name "*.rev.1.bt2" | sed 's/\\.rev.1.bt2\$//'`

    bowtie2 -p $task.cpus --very-sensitive-local -a --no-unal -x \$INDEX -1 ${reads[0]} -2 ${reads[1]} | samtools view -bS - > ${meta.id}.metamlst.bam
    metamlst.py -d $db/*/*.db -o ./${meta.id}.metamlst ${meta.id}.metamlst.bam    
    metamlst-merge.py -d $db/*/*.db ./${meta.id}.metamlst

    awk '{print FILENAME,\$1,\$2,\$3}' OFS="," ${meta.id}.metamlst/*/*_report.txt | grep -v ST | awk -F'/' '{print \$(NF)}' | sed 's/_report.txt//g' > ${prefix}.metamlst_report.tsv

    find . -type f -empty -print -delete

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamlst: \$(echo \$(metamlst.py --version | head -1 | cut -f2))
    END_VERSIONS
    """
}
