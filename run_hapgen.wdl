version 1.0

#import "sim_admixed.wdl" as tasks

workflow run_hapgen {
    input {
        Map[String, File] pgen
        String build
        Int n_indiv
    }

    call hapgen2 {
         input: pgen = pgen,
                build = build,
                n_indiv = n_indiv
    }

    output {
        Map[String, File] out_pgen = hapgen2.out_pgen
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
        Map[String, File] out_pgen = {
            "pgen": "~{pfile}_hapgen2.pgen", 
            "psam": "~{pfile}_hapgen2.psam", 
            "pvar": "~{pfile}_hapgen2.pvar"
        }
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.2"
        memory: "4GB"
    }
}
