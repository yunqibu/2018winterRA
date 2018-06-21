#$ -S /usr/local/bin/Rscript

args = commandArgs(TRUE)
iter = as.numeric(args[[1]])
corr_S1_W = as.numeric(args[[2]])
crossover_rate_A0Y0 = as.numeric(args[[3]])
crossover_rate_A1 = as.numeric(args[[4]])

library(SuperLearner)
library(mvtnorm)
library(foreach)
library(doParallel) 
library(ks)

load(paste("firstpart", "corr_S1_W:",corr_S1_W,
           "crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".RData", sep="")) 

set.seed(iter)
dat = generate.data(nv=nv, np=np, 
                    corr_S1_W=corr_S1_W, 
                    crossover_rate_A0Y0=crossover_rate_A0Y0, 
                    crossover_rate_A1=crossover_rate_A1)
obs = dat$observed
unobs = dat$unobserved

cl<-makeCluster(1)
registerDoParallel(cl)
out.tmle <- foreach(j = 1:lens, .combine='rbind') %dopar% {
  library(SuperLearner)
  library(mvtnorm)
  library(foreach)
  library(ks)
  library(doParallel)
  estimate(dat=obs, h=hseq[j], s1star=s1[j])
}
row.names(out.tmle) <- s1
 out.tmle
save(out.tmle, file=paste("Resultssecondpart:","corr_S1_W:",corr_S1_W,
                          "crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,"iter:",iter,".RData", sep=""))


