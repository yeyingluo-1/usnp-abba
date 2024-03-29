library(stringr)
library(dplyr)
library(ape)
library(phylotools)

#判断属于哪种拓扑
abba <- function(x){
  if(!any(grepl("[N-]", x))){
    if(length(unique(x))==2){
      if(x[1]==x[2] & x[3]==x[4]){
        return("BBAA")
      }else if(x[1]==x[3] & x[2]==x[4]){
        return("BABA")
      }else if(x[1]==x[4] & x[2]==x[3]){
        return("ABBA")
      }else{
        return("N")
      }
    }else{
      return("N")
    }
  }else{
    return("N")
  }
}

#判断生成单个位点的四个碱基，并执行abba
run_abba <- function(r){
  dna_4 <- as.character(sapply(seq_4$seq.text,function(x){str_sub(x,r,r)}))
  return(abba(dna_4))
}

#统计三种拓扑的数量
abba_num <- function(x){
  return(c(length(which(x=="BBAA")),length(which(x=="ABBA")),length(which(x=="BABA"))))
}



usnp_D_statistic <- function(output_path,sptree_path,tip_path,information_locus_path,num){
  #模拟多少次
  #num <- num
  
  dir.create(output_path)
  sptree <- read.tree(sptree_path)
  tip <- readLines(tip_path)
  outgroup <- tip[length(tip)]
  ingroup <- tip[1:(length(tip)-1)]
  tritaxa <- t(combn(ingroup,3)) #triplets
  seq_files <- dir(information_locus_path)
  #统计些指标
  std_rep <- c()
  BBAA_mean <- c()
  ABBA_mean <- c()
  BABA_mean <- c()
  D_statistic_summary <- c()
  S1 <- c()
  S2 <- c()
  S3 <- c()
  for (cob in 1:nrow(tritaxa)) {
    single_tri <- c()
    four_species <- c(as.character(tritaxa[cob,]),outgroup)
    sptree_4 <- keep.tip(sptree,four_species)
    p12 <- sptree_4$tip.label[sptree_4$edge[,2][sptree_4$edge[,1]==7]]
    p1 <- p12[1]
    p2 <- p12[2]
    p3 <- setdiff(as.character(tritaxa[cob,]),p12)
    seq_name <- data.frame(seq.name=c(p1,p2,p3,outgroup))
    for(n in 1:length(seq_files)){
      #生成单个loci的四物种组合序列
      seq <- phylotools::read.phylip(file.path(information_locus_path,seq_files[n]))
      seq_4 <- left_join(seq_name,seq,by="seq.name")
      if(!any(is.na(seq_4))){
        local <- sample(nchar(seq_4$seq.text[1]),num,replace = T)
        loci_rep <- sapply(local,run_abba) %>% as.character
      }else{
        loci_rep <- rep(NA,num)
      }
      single_tri <- cbind(single_tri,loci_rep)
    }
    single_loci_abba_rep <- apply(single_tri,1,abba_num)
    D <- (single_loci_abba_rep[2,] - single_loci_abba_rep[3,]) / ((single_loci_abba_rep[2,] + single_loci_abba_rep[3,]))
    single_loci_abba_rep <- rbind(single_loci_abba_rep,D)
    rownames(single_loci_abba_rep) <- c("BBAA","ABBA","BABA","D-statistic")
    colnames(single_loci_abba_rep) <- paste("rep",1:ncol(single_loci_abba_rep),sep = "")
    #将没有两种不一致拓扑的D值计为0
    single_loci_abba_rep[is.na(single_loci_abba_rep)] <- 0
    write.csv(single_loci_abba_rep,paste0(output_path,"/",cob,".csv"))
    
    #综合输出
    S1 <- append(S1,p1)
    S2 <- append(S2,p2)
    S3 <- append(S3,p3)
    BBAA_mean <- append(BBAA_mean,mean(single_loci_abba_rep[1,]))
    ABBA_mean <- append(ABBA_mean,mean(single_loci_abba_rep[2,]))
    BABA_mean <- append(BABA_mean,mean(single_loci_abba_rep[3,]))
    D_statistic_summary <- append(D_statistic_summary,mean(single_loci_abba_rep[4,]))
    std <- single_loci_abba_rep[4,] %>% as.numeric() %>% sd()
    std_err <- std / sqrt(num)
    std_rep <- append(std_rep,std_err)
  }
  Z <- abs(D_statistic_summary)/std_rep
  D_summary <- data.frame(p1=S1,p2=S2,p3=S3,outgroup=rep(outgroup,length(S1)),BBAA_mean,
                          ABBA_mean,BABA_mean,D_statistic_summary,std_err=std_rep,Z)
  write.csv(D_summary,paste0(output_path,"/D_summary.csv"),row.names = F)
}



output_path <- "/home/Adisk/chenghao/example/result"
sptree_path <- "/home/Adisk/chenghao/example/clade1.tre"
tip_path <- "/home/Adisk/chenghao/example/tip.txt"
information_locus_path <- "/home/Adisk/chenghao/example/info_locus"
num <- 100
usnp_D_statistic(output_path,sptree_path,tip_path,information_locus_path,num)
  







