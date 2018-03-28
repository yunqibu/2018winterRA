#$ -S /usr/local/bin/Rscript

args = commandArgs(TRUE)
iter = as.numeric(args[[1]])
corr_S1_W = as.numeric(args[[2]])
crossover_rate = as.numeric(args[[3]])


library(SuperLearner)
library(mvtnorm)
library(foreach)
library(doParallel)

load(paste("firstpart","corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".RData", sep="")) 
#result <- matrix( ncol=10,nrow=lens)
dat = generate.data(nv=nv, np=np,  corr_S1_W = corr_S1_W)
obs = dat$observed
unobs = dat$unobserved

cl<-makeCluster(1)
registerDoParallel(cl)
out.tmle <- foreach(j = 1:lens, .combine='rbind') %dopar% {
  library(SuperLearner)
  library(mvtnorm)
  library(foreach)
  library(doParallel)
  estimate(dat=obs, h=h, s1star=s1[j])
}
row.names(out.tmle) <- s1

save(out.tmle, file=paste("Resultssecondpart:","corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,"iter:",iter,".RData", sep=""))
