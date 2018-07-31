Rotavirus power calculations
================

Simulation study design
-----------------------

*A* := 2-arm randomized trial.

-   *N*<sub>*v*</sub> = 4200 in the vaccine group (*A* = 1).
-   *N*<sub>*p*</sub> = 3000 in the placebo group (*A* = 0).

*S* := the immune response marker of interest measured at month 3 (observed).

-   *S*<sub>1</sub>:= the potential outcome of *S* if assigned to the vaccine arm (*A* = 1).
-   *S*<sub>0</sub>:= the potential outcome of *S* if assigned to the placebo arm (*A* = 0), not used in this analysis.

*W* := the baseline predictor

-   (*W*, *S*<sub>1</sub>) ~ bivariate normal with var(*W*)=var(*S*<sub>1</sub>)=1 and *ρ*=cor(*W*, *S*<sub>1</sub>)=0.25, 0.5, 0.75.

*Y* := occurrence of the rotavirus disease by 2 years post enrollment (i.e. after a 1.75-year follow-up period after *S* is measured at month 3).

Ideal population for inference is subjects at-risk for *Y* = 1 at month 3. (i.e., did not experience the primary rotavirus disease endpoint by month 3).

Practically, the implementation of the method would only include subjects who are observed to attend the month 3 visit without occurrence of the rotavirus by month 3.

Marginal disease rate post marker measurement (from month 3 to month 24):

-   *P*(*Y* = 1|*A* = 0)=0.04 × (1.75/2) for the placebo group.
-   *P*(*Y* = 1|*A* = 1)=0.01 × (1.75/2) for the vaccine group (75% vaccine efficacy(VE)).

#### Case-cohort sampling design for measuring *S*:

-   *S* measured in all *A* = 1 subjects with *Y* = 1 observed,
-   *S* also measured in a simple random sample of all *A* = 1 subjects. (sampling rate = 25%,50%,100%)

For placebo recipients *A* = 0 who complete follow-up with *Y* = 0, cross-over 25%,50%,100% to receive the vaccine and have S measured 3 months after the cross-over. This is used only for filling in *S* = *S*<sub>1</sub>, and we assume that no crossed-over subjects experience the primary rotavirus endpoint between month 24 and month 27.

#### Hypothesis of interest is

-   Null *H*<sub>0</sub> : VE<sub>*s*</sub>=VE (i.e., no modification of VE by the marker *S*<sub>1</sub>).
-   Alternative *H*<sub>1</sub> : VE<sub>*s*</sub>≠VE (some effect modification).

Generation of *Y*: (with marginals kept)

-   Null case: *Y* generated with *W* and *S*<sub>1</sub>.
-   Alternative case: *Y* generated with *W* alone.

The above set-up gives 54 scenarios:

-   *ρ* = (0.25, 0.5, 0.75) × sampling rate =(25%,50%,100%) × cross-over fraction =(25%,50%,100%) × hypothesis=(null, alternative).

Simulation results
------------------

2 examples of the 54 scenarios

    ## [1] "cor(S1,W)=0.25, crossover rate=0.25, sample rate=0.25"

    ## [1] "Alternative case"

    ##    Estimate.log.RR. Standard.Error Initial.Estimate Bandwith Smooth.Truth
    ## 1            -1.333          6.549           -4.303      0.8       -1.559
    ## 2            -1.415          2.319           -4.391      0.8       -1.597
    ## 3            -1.496          4.405           -4.472      0.8       -1.600
    ## 4            -1.610          2.222           -4.551      0.8       -1.615
    ## 5            -1.558          3.608           -4.620      0.8       -1.691
    ## 6            -1.616          2.561           -4.687      0.8       -1.865
    ## 7            -1.712          2.228           -4.744      0.8       -1.821
    ## 8            -1.823          2.450           -4.795      0.8       -1.830
    ## 9            -1.829         10.552           -4.838      0.8       -1.996
    ## 10           -1.813         20.131           -4.884      0.8       -2.005
    ## 11           -1.986         11.132           -4.932      0.8       -2.191
    ##     Truth s1star Percent.of.Estimation.Missing Power
    ## 1  -1.598    0.0                          0.11  0.40
    ## 2  -1.689    0.1                          0.11  0.39
    ## 3  -1.779    0.2                          0.12  0.33
    ## 4  -1.866    0.3                          0.13  0.32
    ## 5  -1.956    0.4                          0.11  0.31
    ## 6  -2.050    0.5                          0.10  0.29
    ## 7  -2.138    0.6                          0.11  0.33
    ## 8  -2.228    0.7                          0.13  0.31
    ## 9  -2.317    0.8                          0.12  0.34
    ## 10 -2.412    0.9                          0.12  0.33
    ## 11 -2.496    1.0                          0.15  0.33

    ## [1] "Null case"

    ##    Estimate.log.RR. Standard.Error Initial.Estimate Bandwith Smooth.Truth
    ## 1            -1.290          2.315           -4.194      0.8       -1.456
    ## 2            -1.262          4.228           -4.255      0.8       -1.417
    ## 3            -1.312          6.707           -4.310      0.8       -1.314
    ## 4            -1.340          1.468           -4.363      0.8       -1.508
    ## 5            -1.248          2.413           -4.405      0.8       -1.394
    ## 6            -1.215          3.893           -4.442      0.8       -1.433
    ## 7            -1.210          2.443           -4.481      0.8       -1.379
    ## 8            -1.271          4.204           -4.505      0.8       -1.404
    ## 9            -1.382          2.571           -4.522      0.8       -1.407
    ## 10           -1.407          2.776           -4.540      0.8       -1.474
    ## 11           -1.456          2.463           -4.547      0.8       -1.526
    ##     Truth s1star Percent.of.Estimation.Missing Truth.CI.coverage
    ## 1  -1.401    0.0                          0.08             0.957
    ## 2  -1.403    0.1                          0.08             0.967
    ## 3  -1.405    0.2                          0.10             0.978
    ## 4  -1.407    0.3                          0.10             0.967
    ## 5  -1.409    0.4                          0.09             0.967
    ## 6  -1.411    0.5                          0.10             0.956
    ## 7  -1.413    0.6                          0.11             0.933
    ## 8  -1.414    0.7                          0.15             0.953
    ## 9  -1.415    0.8                          0.19             0.938
    ## 10 -1.417    0.9                          0.21             0.924
    ## 11 -1.418    1.0                          0.23             0.922
