version 1.0

workflow sim_admixed {
    input {
        Map[String, Map[String, Map[String, File]]] pgen
        Array[Float] admix_prop
        String build
        Int n_indiv
        Int n_gen
    }

    scatter(pair1 in pgen) {
        String chrom = pair1.left
        File pop_map = pair1.right
        scatter (pair2 in pop_map) {
            call hapgen2 {
                input: pgen = pop_map,
                       build = build,
                       n_indiv = n_indiv
            }
        }

        call admix_simu {
            input: pgen = hapgen2.out_pgen,
                   psam = hapgen2.out_psam,
                   pvar = hapgen2.out_pvar,
                   admix_prop = admix_prop,
                   chrom = chrom,
                   build = build,
                   n_indiv = n_indiv,
                   n_gen = n_gen
        }
    }

    output {
        Array[Map[String, File]] out_pgen = admix_simu.out_pgen
        Array[File] out_lanc = admix_simu.out_lanc
        Array[File] out_chrom = admix_simu.out_chrom
    }
    
    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task hapgen2 {
    input {
        Map[String, File] pgen
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
        String? chrom
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
        String? out_chrom = chrom
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "16GB"
    }
}
