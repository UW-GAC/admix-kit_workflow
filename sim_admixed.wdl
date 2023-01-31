version 1.0

workflow sim_admixed {
    input {
        Array[String] pops
        Array[Float] admix_prop
        String build
        Array[Int] chroms
        Int n_indiv
        Int n_gen
    }

    call get_1kg_ref {
         input: build = build
    }

    scatter(c in chroms) {
        call subset_hapmap3 {
            input: pgen = get_1kg_ref.out_pgen,
                   psam = get_1kg_ref.out_psam,
                   pvar = get_1kg_ref.out_pvar,
                   build = build,
                   chrom = c
        }

        scatter (p in pops) {
            call subset_pop_indiv {
                input: pgen = subset_hapmap3.out_pgen,
                       psam = subset_hapmap3.out_psam,
                       pvar = subset_hapmap3.out_pvar,
                       pop = p
            }
            call hapgen2 {
                input: pgen = subset_pop_indiv.out_pgen,
                       psam = subset_pop_indiv.out_psam,
                       pvar = subset_pop_indiv.out_pvar,
                       build = build,
                       chrom = c,
                       n_indiv = n_indiv
            }
        }

        call admix_simu {
            input: pgen = hapgen2.out_pgen,
                   psam = hapgen2.out_psam,
                   pvar = hapgen2.out_pvar,
                   admix_prop = admix_prop,
                   build = build,
                   chrom = c,
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


task get_1kg_ref {
    input {
        String build
    }

    command <<<
        admix get-1kg-ref --dir 1kg-ref-~{build} --build ~{build}
    >>>

    output {
        File out_pgen = "1kg-ref-~{build}/pgen/all_chr.pgen"
        File out_psam = "1kg-ref-~{build}/pgen/all_chr.psam"
        File out_pvar = "1kg-ref-~{build}/pgen/all_chr.pvar"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.1"
        memory: "16GB"
        disks: "local-disk 32 SSD"
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


task hapgen2 {
    input {
        File pgen
        File psam
        File pvar
        String build
        Int chrom
        Int n_indiv
    }

    String pfile = basename(pgen, ".pgen")

    command <<<
        ln -s ~{pgen} ~{pfile}.pgen
        ln -s ~{psam} ~{pfile}.psam
        ln -s ~{pvar} ~{pfile}.pvar
        admix hapgen2 \
            --pfile ~{pfile} \
            --chrom ~{chrom} \
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
        docker: "uwgac/admix-kit:0.1.1"
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
        Int chrom
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
            --out admix_chr~{chrom}
    >>>

    output {
        File out_pgen = "admix_chr~{chrom}.pgen"
        File out_psam = "admix_chr~{chrom}.psam"
        File out_pvar = "admix_chr~{chrom}.pvar"
        File out_lanc = "admix_chr~{chrom}.lanc"
    }

    runtime {
        docker: "uwgac/admix-kit:0.1.1"
        memory: "16GB"
    }
}
