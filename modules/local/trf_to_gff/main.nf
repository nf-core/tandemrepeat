process TRF_TO_GFF {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.12.0"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.12' :
        'python:3.12' }"

    input:
    tuple val(meta), path(dat)

    output:
    tuple val(meta), path("*.gff"), emit: gff
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    trf_to_gff.py \
        --input $dat \
        --output ${prefix}.gff \
        --sample ${meta.id}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //')
    END_VERSIONS
    """

    stub:
    """
    touch ${prefix}.gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: 3.12
    END_VERSIONS
    """
}
