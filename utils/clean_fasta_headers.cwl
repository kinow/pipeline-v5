#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: Replaces problematic characters from FASTA headers with dashes

requirements:
  ResourceRequirement:
    coresMax: 1
    ramMin: 1024  # just a default, could be lowered
  InlineJavascriptRequirement: {}

inputs:
  sequences:
    type: File
    # streamable: true
    # <<doesn't support by cwltoil>> format: [ edam:format_1929, edam:format_1930]  # FASTA or FASTQ

stdin: $(inputs.sequences.path)

baseCommand: [ tr, '" /|<_;#"', '-------' ]

stdout: $(inputs.sequences.nameroot).unfiltered_fasta

outputs:
  sequences_with_cleaned_headers:
    type: stdout

hints:
  - class: DockerRequirement
    dockerPull: debian:stable-slim

$namespaces:
 edam: http://edamontology.org/
 s: http://schema.org/
$schemas:
 - http://edamontology.org/EDAM_1.16.owl
 - https://schema.org/version/latest/schemaorg-current-http.rdf

s:license: "https://www.apache.org/licenses/LICENSE-2.0"
s:copyrightHolder:
    - name: "EMBL - European Bioinformatics Institute"
    - url: "https://www.ebi.ac.uk/"