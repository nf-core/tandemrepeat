/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: Input validation and preparation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsHelp; paramsSummaryLog; paramsSummaryMap; validateParameters; samplesheetToList } from 'plugin/nf-schema'

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    help              // boolean: Display help message and exit
    validate_params   // boolean: Validate parameters
    monochrome_logs   // boolean: Disable coloured logging output
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    input             //  string: Path to input samplesheet
    fasta             //  string: Path to reference fasta

    main:

    ch_versions = Channel.empty()

    //
    // Print help message if needed
    //
    if (params.help || params.help_full) {
        def String command = "nextflow run ${workflow.manifest.name} --input samplesheet.csv --fasta genome.fa -profile docker"
        log.info paramsHelp(command)
        System.exit(0)
    }

    //
    // Print version number and exit
    //
    if (params.version) {
        log.info "${workflow.manifest.name} ${workflow.manifest.version}"
        System.exit(0)
    }

    //
    // Validate parameters
    //
    if (validate_params) {
        validateParameters()
    }

    //
    // Create channel from input file provided through params.input
    //
    Channel
        .fromList(samplesheetToList(params.input, "assets/schema_input.json"))
        .map {
            meta, fasta ->
                return [ meta, file(fasta) ]
        }
        .groupTuple()
        .map {
            meta, fasta ->
                return [ meta, fasta[0] ]
        }
        .set { ch_samplesheet }

    //
    // Create channel from fasta file provided through params.fasta
    //
    ch_fasta = Channel.fromPath(params.fasta, checkIfExists: true)

    emit:
    samplesheet = ch_samplesheet
    fasta       = ch_fasta
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: Completion tasks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {

    take:
    email           //  string: email address for completion notification
    email_on_fail   //  string: email address for failure notification
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir          //    path: Path to output directory
    monochrome_logs // boolean: Disable coloured logging output
    hook_url        //  string: Incoming webhook URL for notification
    multiqc_report  //  string: Path to MultiQC report

    main:

    //
    // Completion email and summary
    //
    // PLACEHOLDER: Email notification can be added here
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Generate methods description for MultiQC
//
def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named nextflow variable
    meta = [:]
    meta.workflow = [:]
    meta.workflow.name    = workflow.manifest.name
    meta.workflow.version = workflow.manifest.version

    // Get schema parameters
    def String command  = "nextflow run ${workflow.manifest.name} -r ${workflow.manifest.version}"
    meta.workflow.command = command + ' ' + workflow.commandLine.split(' ')[2..-1].join(' ')

    // Get summary for methods description
    meta.workflow.profile = workflow.profile

    def methods_text = mqc_methods_yaml.text

    def engine = new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}
