version 1.0

workflow subset_pop {
    input {
        File pgen
        File psam
        File pvar
        String pop
    }

    call subset_pop_indiv {
         input: pgen = pgen,
                psam = psam,
                pvar = pvar,
                pop = pop
    }

    output {
        File out_pgen = subset_pop_indiv.out_pgen
        File out_psam = subset_pop_indiv.out_psam
        File out_pvar = subset_pop_indiv.out_pvar
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task subset_pop_indiv {
    input {
        File pgen
        File psam
        File pvar
        String pop
    }

    String pfile = basename(pgen, ".pgen")

    command <<<
        ln -s ~{pgen} ~{pfile}.pgen
        ln -s ~{psam} ~{pfile}.psam
        ln -s ~{pvar} ~{pfile}.pvar
        admix subset-pop-indiv \
            --pfile ~{pfile} \
            --pop ~{pop} \
            --out ~{pop}.indiv
        plink2 --pfile ~{pfile} \
            --keep ~{pop}.indiv \
            --make-pgen \
            --out ~{pfile}_~{pop}
    >>>

    output {
        File out_pgen = "~{pfile}_~{pop}.pgen"
        File out_psam = "~{pfile}_~{pop}.psam"
        File out_pvar = "~{pfile}_~{pop}.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.1"
        memory: "4GB"
    }
}
