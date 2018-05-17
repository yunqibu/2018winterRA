setwd("~/Desktop/Peter Gilbert/2018winterRA")
corr_S1_W = 0.5
crossover_rate = 0.5
load(file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/1000iter/0509nomisscorr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".RData", sep=""))
nona <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0509nomisscorr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".csv", sep=""))
names(nona)[2:11]


for(i in 1:lens){
  ci <- cbind(results[i,1,]-qnorm(0.975)*results[i,2,], 
              results[i,1,]+qnorm(0.975)*results[i,2,])
  RR.u.ci <- exp(ci[,2])
  RR.u.ci[is.na(RR.u.ci)]<-0
  nona$power[i] <-mean(RR.u.ci>1)
}

write.csv(nona, file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0509nomisscorr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".csv", sep=""))

