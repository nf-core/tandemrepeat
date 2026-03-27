process TRF {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::trf=4.09.1"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trf:4.09.1--h031d066_3' :
        'biocontainers/trf:4.09.1--h031d066_3' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.dat"), emit: dat
    tuple val(meta), path("*.txt"), emit: txt, optional: true
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '2 7 7 80 10 24 500 -d -h'
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    trf \
        $fasta \
        $args \
        -l 1 \
        | tee ${prefix}.trf.log

    # Rename output files to match expected pattern
    if [ -f "*.dat" ]; then
        mv *.dat ${prefix}.trf.dat
    fi
    if [ -f "*.txt" ]; then
        mv *.txt ${prefix}.trf.txt
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trf: \$(trf 2>&1 | head -n 1 | sed 's/Tandem Repeats Finder, Version //; s/ Copyright.*//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.trf.dat
    touch ${prefix}.trf.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trf: 4.09.1
    END_VERSIONS
    """
}
