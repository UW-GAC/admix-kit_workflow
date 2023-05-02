version 1.0

import "run_data_model.wdl" as tasks
import "https://raw.githubusercontent.com/UW-GAC/primed-file-checks/main/validate_genotype_model.wdl" as validate

workflow sim_admixed {
    input {
        Map[String, Map[String, Map[String, File]]] pgen
        Array[String] chrom
        Array[String] pop
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
        String source_data
        String model_url
        String workspace_name
        String workspace_namespace
        Boolean overwrite = false
        Boolean import_tables = false
    }

    scatter(c in chrom) {
        scatter (p in pop) {
            call hapgen2 {
                input: pgen = pgen[c][p],
                       chrom = c,
                       build = build,
                       n_indiv = n_indiv
            }
        }

        call admix_simu {
            input: pgen = hapgen2.out_pgen,
                   psam = hapgen2.out_psam,
                   pvar = hapgen2.out_pvar,
                   admix_prop = admix_prop,
                   build = build,
                   n_indiv = n_indiv,
                   n_gen = n_gen
        }
    }

    call tasks.sim_data_model {
        input: pgen = admix_simu.out_pgen,
               psam = admix_simu.out_pgen[1]["psam"],
               lanc = admix_simu.out_lanc,
               chrom = chrom,
               pop = pop,
               admix_prop = admix_prop,
               build = build,
               n_indiv = n_indiv,
               n_gen = n_gen,
               source_data = source_data
    }

    call validate.results {
        input: table_files = sim_data_model.table_files,
               model_url = model_url,
               workspace_name = workspace_name,
               workspace_namespace = workspace_namespace,
               overwrite = overwrite,
               import_tables = import_tables
    }

    output {
        Array[Map[String, File]] out_pgen = admix_simu.out_pgen
        Array[File] out_lanc = admix_simu.out_lanc
        Map[String, File] table_files = sim_data_model.table_files
        File validation_report = results.validation_report
        Array[File]? tables = results.tables
    }
    
    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task hapgen2 {
    input {
        Map[String, File] pgen
        String chrom
        String build
        Int n_indiv
    }

    String pfile = basename(pgen["pgen"], ".pgen")

    command <<<
        ln -s ~{pgen["pgen"]} ~{pfile}.pgen
        ln -s ~{pgen["psam"]} ~{pfile}.psam
        ln -s ~{pgen["pvar"]} ~{pfile}.pvar
        admix hapgen2 \
            --pfile ~{pfile} \
            --n-indiv ~{n_indiv} \
            --out ~{pfile}_hapgen2 \
            --build ~{build} \
            --chrom ~{chrom}
    >>>

    output {
        File out_pgen = "~{pfile}_hapgen2.pgen"
        File out_psam = "~{pfile}_hapgen2.psam"
        File out_pvar = "~{pfile}_hapgen2.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "4GB"
    }
}


task admix_simu {
    input {
        Array[File] pgen
        Array[File] psam
        Array[File] pvar
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
    }

    command <<<
        admix admix-simu \
            --pfile-list "['~{sep="','" pgen}']" \
            --admix-prop "[~{sep=',' admix_prop}]" \
            --n-indiv ~{n_indiv} \
            --n-gen ~{n_gen} \
            --build ~{build} \
            --out admix
    >>>

    output {
        Map[String, File] out_pgen = {
            "pgen": "admix.pgen", 
            "psam": "admix.psam", 
            "pvar": "admix.pvar"
        }
        File out_lanc = "admix.lanc"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "16GB"
    }
}
