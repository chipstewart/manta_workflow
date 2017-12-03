task manta {

    #Inputs and constants defined here
    String pair_id
    File normal_bam
    File normal_bai
    File tumor_bam
    File tumor_bai
    File genome
    File genome_dict
    File genome_index

    String output_disk_gb
    String boot_disk_gb = "10"
    String ram_gb = "32"
    String cpu_cores = "16"

    command {
python_cmd="
import subprocess,os
def run(cmd):
    subprocess.check_call(cmd,shell=True)

run('ln -sT `pwd` /opt/execution')
run('ln -sT `pwd`/../inputs /opt/inputs')
run('/opt/src/algutil/monitor_start.py')

# start task-specific calls
##########################

run('ln -vs ${genome} ')
run('ln -vs ${genome_dict} ')
run('ln -vs ${genome_index} ')
REFERENCE = os.path.abspath(os.path.basename('${genome}'))   

run('ln -vs ${tumor_bam} tumor.bam')
run('ln -vs ${tumor_bai} tumor.bai')
run('ln -vs ${normal_bam} normal.bam')
run('ln -vs ${normal_bai} normal.bai')
#TBAM = os.path.basename('${tumor_bam}')    
#NBAM = os.path.basename('${normal_bam}')    
TBAM = os.path.abspath('tumor.bam')    
NBAM = os.path.abspath('normal.bam')    

run('ls -latrh ')
run('samtools idxstats ' + TBAM)
run('samtools idxstats ' + NBAM)

run('python -V')

run('python /opt/src/manta/manta-1.2.2.centos6_x86_64/bin/configManta.py --normalBam ' + NBAM + ' --tumorBam ' + TBAM  + ' --referenceFasta ' + REFERENCE + ' --runDir .')

run('python runWorkflow.py  --mode local --jobs ${cpu_cores}')

run('tar cvfz ${pair_id}.manta.stats.tar.gz results/stats/*.tsv')

run('tar cvfz ${pair_id}.manta.variants.tar.gz results/variants/*.*')

run('cp results/variants/somaticSV.vcf.gz .')
run('gunzip somaticSV.vcf.gz')
run('mv somaticSV.vcf ${pair_id}.manta.somaticSV.vcf')


#########################
# end task-specific calls
run('/opt/src/algutil/monitor_stop.py')
"
        echo "$python_cmd"
        python -c "$python_cmd"

    }

    output {
        File manta_stats_tarball="${pair_id}.manta.stats.tar.gz"
        File manta_variants_tarball="${pair_id}.manta.variants.tar.gz"
        File manta_somatic_sv_vcf="${pair_id}.manta.somaticSV.vcf"
    }

    runtime {
        docker : "docker.io/chipstewart/manta:1"
        memory: "${ram_gb}GB"
        cpu: "${cpu_cores}"
        disks: "local-disk ${output_disk_gb} HDD"
        bootDiskSizeGb: "${boot_disk_gb}"
        preemptible: 3
    }


    meta {
        author : "Chip Stewart"
        email : "stewart@broadinstitute.org"
    }

}

workflow manta_workflow {
    call manta
}
