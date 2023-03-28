version 1.0

workflow get_ref {
    input {
        String build
    }

    call get_1kg_ref {
         input: build = build
    }

    output {
        File out_pgen = get_1kg_ref.out_pgen
        File out_psam = get_1kg_ref.out_psam
        File out_pvar = get_1kg_ref.out_pvar
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
