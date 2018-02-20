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
dat = generate.data(nv=nv, np=np,  corr_S1_W = corr_S1_W)
obs = dat$observed
unobs = dat$unobserved

#result <- matrix( ncol=10,nrow=lens)

cl<-makeCluster(11)
registerDoParallel(cl)
out.tmle <- foreach(j = 1:lens, .combine='rbind') %dopar% {
  library(SuperLearner)
  library(mvtnorm)
  library(foreach)
  library(doParallel)
  estimate(dat=obs, h=h, s1star=s1[j])
}
row.names(out.tmle) <- s1


# for (j in 1:lens) {
#   out.tmle = estimate(dat=obs, h=h, s1star=s1[j])
#   for (count in 1:10){
#     result[j,count] <- out.tmle[[count]]
#   }
#   # TMLE.psi[iter,j] = out.tmle$psi
#   # TMLE.psi1[iter,j] = out.tmle$psi1
#   # TMLE.psi2[iter,j] = out.tmle$psi2
#   # TMLE.psi3[iter,j] = out.tmle$psi3
#   # 
#   # psi.sd[iter,j] = out.tmle$sd
#   # psi.sd1[iter,j] = out.tmle$sd1
#   # psi.sd2[iter,j] = out.tmle$sd2
#   # psi.sd3[iter,j] = out.tmle$sd3
#   # 
#   # init.psi[iter,j] = out.tmle$init.psi
#   # 
#   # h.cv[iter,j] = out.tmle$h
# }


print("before save")

save(out.tmle, file=paste("secondpart:","corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,"iter:",iter,".RData", sep=""))


print("yahhhhhhhh")