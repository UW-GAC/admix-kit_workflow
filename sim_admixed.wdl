version 1.0

workflow sim_admixed {
    input {
        Array[Array[Map[String, File]]] pgen
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
    }

    scatter(chrom in pgen) {
        scatter (pop in chrom) {
            call hapgen2 {
                input: pgen = pop["pgen"],
                       psam = pop["psam"],
                       pvar = pop["pvar"],
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

    output {
        Array[File] out_pgen = admix_simu.out_pgen
        Array[File] out_psam = admix_simu.out_psam
        Array[File] out_pvar = admix_simu.out_pvar
        Array[File] out_lanc = admix_simu.out_lanc
    }
    
    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task hapgen2 {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int n_indiv
    }

    String pfile = basename(pgen, ".pgen")

    command <<<
        ln -s ~{pgen} ~{pfile}.pgen
        ln -s ~{psam} ~{pfile}.psam
        ln -s ~{pvar} ~{pfile}.pvar
        admix hapgen2 \
            --pfile ~{pfile} \
            --n-indiv ~{n_indiv} \
            --out ~{pfile}_hapgen2 \
            --build ~{build}
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
        File out_pgen = "admix.pgen"
        File out_psam = "admix.psam"
        File out_pvar = "admix.pvar"
        File out_lanc = "admix.lanc"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "16GB"
    }
}
