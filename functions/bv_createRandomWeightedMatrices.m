function R = bv_createRandomWeightedMatrices(nodes)

noCells = ( nodes * ( nodes - 1 ) ) / 2;
weights = rand(1,noCells);
R       = squareform(weights);
