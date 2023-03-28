version 1.0

workflow subset_ref {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int chrom
    }

    call subset_hapmap3 {
         input: pgen = pgen,
                psam = psam,
                pvar = pvar,
                build = build,
                chrom = chrom
    }

    output {
        File out_pgen = subset_hapmap3.out_pgen
        File out_psam = subset_hapmap3.out_psam
        File out_pvar = subset_hapmap3.out_pvar
    }

    meta {
        author: "Stephanie Gogarten"
        email: "sdmorris@uw.edu"
    }
}


task subset_hapmap3 {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int chrom
    }

    String pfile = basename(pgen, ".pgen")

    command <<<
        ln -s ~{pgen} ~{pfile}.pgen
        ln -s ~{psam} ~{pfile}.psam
        ln -s ~{pvar} ~{pfile}.pvar
        admix subset-hapmap3 \
            --pfile ~{pfile} \
            --build ~{build} \
            --chrom ~{chrom} \
            --out_pfile hm3_chr~{chrom}
    >>>

    output {
        File out_pgen = "hm3_chr~{chrom}.pgen"
        File out_psam = "hm3_chr~{chrom}.psam"
        File out_pvar = "hm3_chr~{chrom}.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.1"
        memory: "32GB"
        disks: "local-disk 32 SSD"
    }
}
