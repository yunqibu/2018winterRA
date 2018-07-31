for (corr_S1_W in c(0.25,0.5,0.75)){
  for (crossover_rate_A0Y0 in c(0.25,0.5,1)){
    for (crossover_rate_A1 in c(0.25,0.5,1)){
      print(c(corr_S1_W,crossover_rate_A0Y0,crossover_rate_A1))
      nona <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0731corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".csv", sep=""))
      new <- nona[,c("psi","sd" , "init.psi" ,"h","smooth.true.psi","true.psi" ,"s1", "psi_NA_percent", "power")]
      colnames(new) <-c( "Estimate log(RR)", "Standard Error", "Initial Estimate",
                       "Bandwith",  "Smooth Truth", "Truth", "s1star", "Percent of Estimation Missing",
                       "Power")
      row.names(new)<-NULL
    
      write.csv(round(new,digits=3), file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/TidyTable/corr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1, ".csv", sep=""))
    }
  }
}

 
for (corr_S1_W in c(0.25,0.5,0.75)){
  for (crossover_rate_A0Y0 in c(0.25,0.5,1)){
    for (crossover_rate_A1 in c(0.25,0.5,1)){
      print(c(corr_S1_W,crossover_rate_A0Y0,crossover_rate_A1))
      nona <- read.csv( file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/removeNaN/0731nullcorr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1,".csv", sep=""))
      new <- nona[,c("psi","sd" , "init.psi" ,"h","smooth.true.psi","true.psi" ,"s1", "psi_NA_percent", "ci.coverage.true.psi" )]
      colnames(new) <-c( "Estimate log(RR)", "Standard Error", "Initial Estimate",
                         "Bandwith",  "Smooth Truth", "Truth", "s1star", "Percent of Estimation Missing",
                         "Truth CI coverage")
      row.names(new)<-NULL
      
      write.csv(round(new,digits=3), file=paste("~/Desktop/Peter Gilbert/2018winterRA/Results/TidyTable/nullcorr_S1_W:",corr_S1_W,"crossover_rate_A0Y0:",crossover_rate_A0Y0,"crossover_rate_A1:",crossover_rate_A1, ".csv", sep=""))
    }
  }
}
