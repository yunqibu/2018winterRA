#!/bin/bash

for iter in $(eval echo {1..$1})
do
qsub -cwd secondpartcode.R $iter $2 $3 $4
done
