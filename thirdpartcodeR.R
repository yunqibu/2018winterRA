setwd("~/Desktop/Peter Gilbert/2018winterRA")
library(mvtnorm )
library(ks)
library(gmodels)
if(2!=3)
{
  results <- array(,dim=c(11,10,100))
  corr_S1_W = 0.75
  crossover_rate_A0Y0 = 1
  crossover_rate_A1 = 0.25
  for (iter in 1:100){
  print(iter)
  load(paste("nullResultssecondpart:","corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,"iter:",iter,".RData", sep=""))
  print("loaded")
  results[,,iter] <- array(unlist(out.tmle), dim = c(nrow(out.tmle), ncol(out.tmle)))
  colnames(results[,,iter]) <- colnames(out.tmle)
  }

my.mean<-function(x){mean(x, na.rm = TRUE)}
nona <- as.data.frame(apply(results,c(1,2), my.mean))
withna <- as.data.frame(apply(results,c(1,2), mean))
colnames(withna) <- colnames(out.tmle) 
colnames(nona) <- colnames(out.tmle) 
rownames(nona) <- rownames(out.tmle) 
rownames(withna) <- rownames(out.tmle) 
load(paste("nullfirstpart","corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".RData", sep=""))
rep.smooth <- 10
smooth.true.psi <- array(,dim=c(lens,rep.smooth))
smooth.true.psi1 <- array(,dim=c(lens,rep.smooth))
smooth.true.psi2 <- array(,dim=c(lens,rep.smooth))
smooth.true.psi3 <- array(,dim=c(lens,rep.smooth))

for (i in 1:rep.smooth){
  print(i)
  for (j in 1:lens) {
    dat = generate.data(nv=nv, np=np, 
                        corr_S1_W=corr_S1_W, 
                        crossover_rate_A0Y0=crossover_rate_A0Y0, 
                        crossover_rate_A1=crossover_rate_A1)
    out.smooth = smooth.truth(dat=dat$unobs, h=nona$h[j], s1star=s1[j])
    smooth.true.psi[j,i] = out.smooth$psi
    smooth.true.psi1[j,i] = out.smooth$psi1
    smooth.true.psi2[j,i] = out.smooth$psi2
    smooth.true.psi3[j,i] = out.smooth$psi3
  }
}

nona$smooth.true.psi = rowMeans (smooth.true.psi)
nona$smooth.true.psi1 = rowMeans(smooth.true.psi1)
nona$smooth.true.psi2 = rowMeans(smooth.true.psi2)
nona$smooth.true.psi3 = rowMeans(smooth.true.psi3)
withna$smooth.true.psi = rowMeans(smooth.true.psi)
withna$smooth.true.psi1 = rowMeans(smooth.true.psi1)
withna$smooth.true.psi2 = rowMeans(smooth.true.psi2)
withna$smooth.true.psi3 = rowMeans(smooth.true.psi3)

# calculate the theortical truth of psi
true.psi = numeric(lens)
true.psi1 = numeric(lens)
true.psi2 = numeric(lens)
true.psi3 = numeric(lens)
for (j in 1:lens) {
  out = truth(s1star=s1[j],corr_S1_W=corr_S1_W)
  true.psi[j] = out$psi
  true.psi1[j] = out$psi1
  true.psi2[j] = out$psi2
  true.psi3[j] = out$psi3
}


nona$true.psi = true.psi
nona$true.psi1 = true.psi1
nona$true.psi2 = true.psi2
nona$true.psi3 = true.psi3
nona$s1 = s1
withna$true.psi = true.psi
withna$true.psi1 = true.psi1
withna$true.psi2 = true.psi2
withna$true.psi3 = true.psi3
withna$s1 = s1
withna$psi_NA_percent <- rowMeans(is.na(results[,1,]))
nona$psi_NA_percent <- rowMeans(is.na(results[,1,]))
for(i in 1:lens){
  ci <- cbind(results[i,1,]-qnorm(0.975)*results[i,2,], 
              results[i,1,]+qnorm(0.975)*results[i,2,])
  RR.u.ci <- exp(ci[,2])
  RR.u.ci[is.na(RR.u.ci)]<-0
  nona$power[i] <-mean(RR.u.ci>1)
}
for(i in 1:lens){
  ci <- cbind(results[i,1,]-qnorm(0.975)*results[i,2,], 
              results[i,1,]+qnorm(0.975)*results[i,2,])
  bias <- results[i,1,]-nona$true.psi[i]
  nona$bias.mean[i] <-mean(bias, na.rm=T)
  nona$bias.sd[i] <-sd(bias, na.rm=T)
  nona$bias.min[i]<-range(bias, na.rm=T)[1]
  nona$bias.max[i] <-range(bias, na.rm=T)[2]
  nona$ci.coverage.true.psi[i] <- mean(nona$true.psi[i]>=ci[,1] & nona$true.psi[i]<=ci[,2], na.rm=T)
  nona$ci.coverage.smooth.true.psi[i] <-  mean(nona$smooth.true.psi[i]>=ci[,1] & nona$smooth.true.psi[i]<=ci[,2], na.rm=T)
}
save(results, file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/1000iter/0725nullcorr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".RData", sep=""))
write.csv(nona, file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0725nullcorr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".csv", sep=""))
write.csv(withna, file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/includeNaN/0725nullcorr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".csv", sep=""))
}
else{
  corr_S1_W = 0.25
  crossover_rate_A0Y0 = 0.5
  crossover_rate_A1 = 0.25
  load(file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/1000iter/0725corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".RData", sep=""))
  nona <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0725corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".csv", sep=""))
  withna <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/includeNaN/0725corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".csv", sep=""))
  }




pdf(file=
    paste("Results/plots/0725_null_all_psi_corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".pdf", sep="")) 
par(mfrow = c(1,1))
for(i in 1:11){
  ci <- cbind(results[i,1,]-qnorm(0.975)*results[i,2,], 
              results[i,1,]+qnorm(0.975)*results[i,2,])
  yrange <- range(c(nona$true.psi,nona$smooth.true.psi,results[,c(1,9),]),na.rm=T)
  #yrange[1] <- yrange[1]-1
  #yrange[2] <- yrange[2]+1
  plot(results[i,1,], ylim=yrange,col="blue",pch=15, xlab="iteration",ylab="psi",
       main=paste("s1=",nona$s1[i],", psi NA % =",round(nona$psi_NA_percent[i], digits=2), sep=""))
  points(results[i,9,], col="orange", type="p", pch=17)
  points(ci[,1], type="l", lty=3 ,col="blue")
  points(ci[,2], type="l", lty=3 ,col="blue")
  abline(h=nona$true.psi[i],col="red", lty=1)
  abline(h=nona$smooth.true.psi[i],col="brown", lty=2)
  
  legend( x="topright", 
          legend=c("true psi","psi","smooth psi","initial psi","psi 95%"),
          col=c("red","blue","brown","orange","blue"), lwd=1, lty=c(1,NA,2,NA,3),
          pch=c(NA,15,NA,17,NA) )
  
}
dev.off()



# pdf(paste("~/Desktop/Peter Gilbert/2018winterRA/Results/plots/type1:0306corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".pdf", sep=""),
#     width=6,height=6,paper='special') 
# plot(nona[,c(20,11,16,12,2,10)])
# dev.off()

# pdf(paste("~/Desktop/Peter Gilbert/2018winterRA/Results/plots/type2:0306corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".pdf", sep=""),
#     width=6,height=6,paper='special') 
# plot(nona[,c(16,12)], col=1, type='l', ylim=c(-5,0), ylab="")
# points(nona[,c(16,2)], col=2, type='l')
# points(nona[,c(16,10)],col=3, type='l')
# abline(a=0,b=1, lty=2, col=4)  
# legend("bottom", legend=c("smooth.true.psi", "psi","init.psi","true.psi"),
#        col=c(1,2,3,4), lty=c(1,1,1,2), cex=0.8)
# dev.off()


# plot(0:10/10,results[,3,1],type="l",ylim=c(0.20,0.45))
# legend("topright", c("psi1","psi3"),
#        lty=c(1,1), col=1:2) 
# for (i in 1:9){
#   points(0:10/10,results[,3,i],type="l")
#   points(0:10/10,results[,5,i],type="l",col=2)
# }