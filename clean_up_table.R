for (corr_S1_W in c(0.25,0.5,0.75)){
  for (crossover_rate in c(0.25,0.5,1)){
    nona <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0530corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".csv", sep=""))
    new <- nona[,c(2,3,10:12,16,20:22)]
    colnames(new) <-c( "Estimate log(RR)", "Standard Error", "Initial Estimate",
                       "Bandwith",  "Smooth Truth", "Truth", "s1* ", "Percent of Estimation Missing",
                       "Power")
    row.names(new)<-NULL
    
    write.csv(new, file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/TidyTable/corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate, ".csv", sep=""))
    
  }
}

corr_S1_W = 0.5
crossover_rate = 0.25
nona <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0530corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate,".csv", sep=""))
new <- nona[,c(2,3,10:12,16,20:22)]
colnames(new) <-c( "Estimate log(RR)", "Standard Error", "Initial Estimate",
                   "Bandwith",  "Smooth Truth", "Truth", "s1* ", "Percent of Estimation Missing",
                   "Power")
row.names(new)<-NULL

write.csv(new, file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/TidyTable/corr_S1_W:",corr_S1_W,"crossover_rate:",crossover_rate, ".csv", sep=""))
