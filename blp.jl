# BLP for opioids.
    #=
    Resources:
    NEVO RA Guide, RAs guide to BLP appendix
    Nevo, RAs guide to BLP Estimation
    Gentzkow, Shapiro Replication
    Train, Discrete Choice Models with Simulation
    =#


    #=
    how do we handle correlation among product characteristics when that is unknown?
    They are all assumed independent, apparently, b/c anything else is too demanding.  
    =#

using CSV
using GLM 
using DataFrames
using DataFramesMeta
using StatsBase
using StaticArrays 
using LinearAlgebra 
using Statistics
using Random 

"""
`FW(x)`
Takes the object x and maps it to FrequencyWeights for use in sampling.
x should be a vector of real numbers of some kind


## Test: ##

julia>`FW([1.0])`
1-element FrequencyWeights{Float64,Float64,Array{Float64,1}}:
 1.0
 
julia>`sample(["a","b"], FW([0.5, 0.5]))`
"b"
"""
function FW(x)
    return FrequencyWeights(x)
end 


"""
`MFW(ar1)`
Takes a matrix of real numbers (percentages of population having some characteristic from CPS)
and returns an Array{AbstractWeights, 1} where each element is a set of FrequencyWeights for some
population characteristic.

## Test ## 

julia> MFW([0.5 0.5;0.25 0.75])
2-element Array{AbstractWeights,1}:
 [0.5, 0.5]
 [0.25, 0.75]


julia> sample(["a", "B"], MFW([0.5 0.5;0.25 0.75])[1])
"B"

julia> for el in MFW([0.5 0.5;0.25 0.75])
       println(sample(["a", "b"], el))
       end
"a"
"b"
"""
function MFW(ar1)
    outp = Array{AbstractWeights, 1}()
    for i = 1:size(ar1,1)
        push!(outp, FW(ar1[i,:]))
    end 
    return outp  
end 


"""
`OH(N)`
Generates an Array{Array{Int64,1}, 1}, of one-hot vectors.  It's an identity matrix, but represented 
as a vector of vectors, so the indexing is simpler.

## Test ##

julia> OH(3) 

3-element Array{Array{Int64,1},1}:
 [1, 0, 0]
 [0, 1, 0]
 [0, 0, 1]

 """
function OH(N)
    # generates an Array{Array{Int64,1}, 1} w/ 1's on the diagonal.  Looks like an identity matrix but is an array of the rows of one instead.  
    outp = Array{Array{Int64,1},1}()
    for i = 1:N
        tm1 = zeros(N)
        tm1[i] += 1
        push!(outp, tm1)
    end 
    return outp
end 

"""
`Sampler(n, x...)`

Samples characteristics for a single individual.  Returns a list of those characteristics x..., which can handle many 
characteristics.   Index n is for the market.

- n indexes the market 
- x... is a collection of characteristics, stored as tuples of OH-vectors and FrequencyWeights.

## TEST: ##

mkt_chars = CSV.read("/Users/austinbean/Desktop/programs/opioids/state_demographics.csv", DataFrame) 

mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop])

race_w = convert(Array{Float64,2}, mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]])

disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability])

race = (OH(size(race_w, 2)), MFW(race_w))

disability = (OH(size(disability_w, 2)), MFW(disability_w))

Sampler(4, race, disability)

# returns an Array{Float64,1} of eight elements, first six corresponding to race and last two to disability status.  
"""
function Sampler(n, x...)
    # generates ONE random individual according to the objects in the list x...
    outp = zeros(Float64, 0)
    for (i,el) in enumerate(x) 
        outp = vcat(outp, sample(el[1], el[2][n])) # n is the index of the market sampling weights 
    end 
    return outp 
end 

"""
`Population(S, n, x...)`

Returns a set of S individuals w/ random characteristics from the collection x... for the market n.

- S is an integer representing a number of people.
- n is the index of a market 
- x... is a collection of characteristics, stored as tuples of OH-vectors and FrequencyWeights 

## TEST: ##

mkt_chars = CSV.read("/Users/austinbean/Desktop/programs/opioids/state_demographics.csv", DataFrame) 

mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop])

race_w = convert(Array{Float64,2}, mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]])

disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability])

race = (OH(size(race_w, 2)), MFW(race_w))

disability = (OH(size(disability_w, 2)), MFW(disability_w))

Population(100, 2, race, disability)

# returns an 8 × 100 array, where each column is an "individual" represented as a race (first six elements) and a disability status (last two)
"""
function Population(S, n, x...)
    # for a market n, returns S random individuals given the objects in the list x 
    length = size( Sampler(n, x...) , 1)
    outp = zeros(Float64, length, S)
    for i = 1:S
        outp[:,i] += Sampler(n, x...)
    end 
    return outp 
end 

"""
`PopMarkets(M, S, Ch, x...)`

Returns a collection of simulated individuals numbering S across the markets M, where C is a set of random shocks and x... is a collection of characteristics.

- M indexes markets. A list of e.g., strings ("Alabama", "Arkansas", ... ) or ("2001", "2002", ... ). 
- S is the number of individuals to be generated.
- Ch is an integer. indexes the number of characteristics w/ a random coefficient as an integer (?)
- x... is a list of demographics, e.g., pop_w, race_w, ... 


## TEST: ## 

mkt_chars = CSV.read("/Users/austinbean/Desktop/programs/opioids/state_demographics.csv", DataFrame) 

states = convert(Array{String,1}, mkt_chars[!,:name])

pop_w = convert(Array{Float64,2}, mkt_chars[!, [:pop_10_14, :pop_15_19, :pop_20_24, :pop_25_29, :pop_30_34, :pop_35_39, :pop_40_44, :pop_45_49, :pop_50_54, :pop_55_59, :pop_60_64, :pop_65_69, :pop_70_74, :pop_75_79, :pop_80_84, :pop_85_plus]])

pop = (OH(size(pop_w, 2)), MFW(pop_w))

N_individuals = 100

N_characteristics = 3

sim_individuals = PopMarkets(states, N_individuals, N_characteristics, pop)

# returns a 19 × 100 × 52 (characteristics × individuals × markets) array 
"""
function PopMarkets(M, S, Ch, x...)
    # get the simulated for S individuals demographics over all of the markets M w/ Ch characteristics and x... demographics.  
    length = size( Sampler(1, x...) , 1)
    mkts = size(M,1)
    outp = zeros(Float64, length+Ch, S, mkts)
    for i = 1:mkts 
        outp[1:length,:,i] += Population(S, i, x...) #
        outp[(length+1):end,:,i] += randn(Ch, S)     # shocks, but think carefully about this.  These go on product features.  
    end 
    return outp 
end 

"""
`AllMarketShares(mkts::Array, params::Array, δ::Array, products::Array, mean_utils::Array)`
- `mkts` - a collection of markets
- `params` - current parameter values 
- `δ` - mean utilities 
- `products` - product characteristics
- `mean_utils` - output, shares across markets 

This will compute the predicted market shares across all of the markets given in `mkts`.
Operates in-place on mean_utils.  Ordered returned is products × markets in mean_utils.

## TEST ##
shares = MarketShares(:yr, :ndc_code, :market_shares);
charcs = ProductChars(:yr, :ndc_code, :copay_high, :simple_fent, :simple_hydro, :simple_oxy, :DEA2, :ORAL);
params_indices, markets = MKT(10,3);
    # now markets is [93,10,52] - characteristics dim × individuals × markets (states)
cinc = markets[:,:,10];

mean_u = zeros(948, 52);
AllMarketShares(markets, params_indices[1], zeros(948), charcs, mean_u)

mean_u 

## TODO ##
δ is market specific too.  Needs to be products × markets  
"""
function AllMarketShares(mkts::Array, params::Array, δ::Array, products::Array, mean_utils::Array)
    param_dim, n_individuals, n_markets = size(mkts)
    n_products, n_chars = size(products)
    ind_utils = zeros(n_products)
    for m = 1:n_markets
        # TODO - something is wrong.  B/c pred share generates shares which sum to one.
        mu = @view mean_utils[:,m] 
        mk = @view mkts[:,:,m]
        PredShare(mk, params, δ, products, mu, ind_utils)
        #println("mu? ", sum(mu))
    end 
    println("LT zero shares: last one ", sum(mean_utils.<=0))
   return nothing 
end 



"""
`PredShare(mkt::Array, params::Array, δ::Array, products::Array, market_shares, ind_utils::Array)`
Should take a single market, return mean util across a bunch of products.
To cut allocations, pass a vector to hold the utilities.  
This should operate in-place on the vector δ
- `mkt` current collection of simulated individuals.  
- `params` current value of all parameters 
- `δ` current value of mean utilities 
- `products` set of items and their characteristics, by market 
- `market_shares` temporary collection to put the mean new market_shares
- `ind_utils` container for utilites, called in Utils.

∑_ns exp ( δ + ∑_k σ_k x^k_jt ν_i^k + π_k1 D_i1 + … + π_kd D_id ) / 1 + ∑ exp ( δ + ∑_k σ_k x^k_jt ν_i^k + π_k1 D_i1 + … + π_kd D_id )


## TEST ##
shares = MarketShares(:yr, :ndc_code, :market_shares);
charcs = ProductChars(:yr, :ndc_code, :copay_high, :simple_fent, :simple_hydro, :simple_oxy, :DEA2, :ORAL);
params_indices, markets = MKT(10,3);
    # now markets is [93,10,52] - characteristics dim × individuals × markets (states)
cinc = markets[:,:,10];
mu = zeros(948);
ind_u = zeros(948); 
PredShare(cinc, params_indices[1], zeros(948), charcs, mu, ind_u)
sum(ind_u) # does sum to nearly one.  

## Test All markets ##
muts = zeros(948, 52)
for i = 1:size(markets,3) 
    b = @view muts[:,i] # note this!
        # TODO - not that ind_u sums to 1, but b does not.  
    PredShare(markets[:,:,i], params_indices[1], zeros(948), charcs, b, ind_u)
    println("pred share: ", sum(b)) # this is a puzzle...  is there something I'm not fixing?  
   # println("LT zero shares: ", sum(muts.<=0))
end

TODO - mean_utils should be an array with dimension equal to the number of markets.  Each market gets a row 
TODO - ind_utils can be pre-allocated at a higher level.  
TODO - this does not generate shares approximately 1 w/in a market, as it must.  



"""
function PredShare(mkt, params::Array, δ::Array, products::Array, market_shares, ind_utils::Array)
    characs, individuals = size(mkt)         # number of features, number of individuals.  
    ZeroOut(market_shares)                   # be careful w/ this since it will zero out the **entire** market_shares Array.
    for i = 1:individuals
        # TODO - this function does not always sum to 1 across all individuals - why is that?  
        v1 = @view mkt[:,i]
        Util( v1, products, δ, params, ind_utils ) # computes utility for ALL products in market for one person
        println("sum utils inside: ", sum(ind_utils))
        market_shares .+= ind_utils          # FIXME - check that this .+= change works
    end
        # this is weird... why don't these sum to 1?  
    println("mkt ", sum(market_shares), " num individuals ", individuals)
    market_shares ./=individuals             # take mean over individuals in the market - divide by N_individuals. 
    println("sum ", sum(market_shares))
    println("uts ", sum(ind_utils))
    return nothing  
end 



"""
`Util(demographics::Array, products_char::Array, δ::Array, params::Array, utils::Array)`
Compute the utility over all products for a single simulated person in the market 
- `demographics` is an array of demographics for an individual
- `products_char` is an array of features 
- `δ` is an array of the current mean utilities 
- `params` is an array of the current set of parameters
- `utils` is an array w/ dimension equal to that of the products in the market.
- NB: operates in-place on the vector utils, which is reset to zero every time.  Cuts allocations

Products, δ must be in the same order


This is computing: exp ( δ + ∑_k x^k_jt (σ_k ν_i^k + π_k1 D_i1 + … + π_kd D_id ) / 1 + ∑ exp ( δ + ∑_k σ_k x^k_jt ν_i^k + π_k1 D_i1 + … + π_kd D_id )
- δ a mean util
- x^k_jt are characteristics getting a random coefficient.  
- σ_k a parameter multiplying a shock
- D_i1, ..., D_id are demographic characteristics (no random coeff, but param π_id)

TODO - can cut the allocation a little by removing tmp_sum and making it a float in the argument?  

## TEST ##
shares = MarketShares(:yr, :ndc_code, :market_shares)
charcs = ProductChars(:yr, :ndc_code, :copay_high, :simple_fent, :simple_hydro, :simple_oxy, :DEA2, :ORAL)
params_indices, markets = MKT(10,3);
cinc = markets[:,:,10]
utils = zeros(948);
δ = zeros(948);
Util(cinc[:,1], charcs, zeros(948), params_indices[1], utils )

## Test Across individuals.  

for i =1:size(cinc,2) 
    Util(cinc[:,i], charcs, δ, params_indices[1], utils)
    println(sum(utils))
end 

## Known answer test case ##
 
Util([1; 0; 0], ['x' 'y' 1 1], [0 0 0], [1; 1; 1], [0 0 0]).≈[0.7112345942275937  0.09625513525746869  0.09625513525746869]

"""
function Util(demographics, products_char::Array, δ::Array, params::Array, utils::Array)
    ZeroOut(utils)                                     # will hold utility for one guy over all of the products 
    num_prods, num_chars = size(products_char)
    # weirdly the problem might be in here?  but how?  
    for i = 1:num_prods 
        tmp_sum = 0.0                                  # reset the running utility for each person. 
        tmp_sum += δ[i]                                # product-specific part 
        for j = 3:num_chars                            # TODO - this can be redone so that it doesn't require keeping track of this 3.
            tmp_sum += products_char[i,j]*(params'*demographics) 
        end 
        utils[i] += tmp_sum 
    end   
    #mx_u = maximum(utils)                              # max for numerical stability
    #sm = (1/exp(mx_u))+sum(exp.(utils.-mx_u))          # denominator: 1+ sum (exp ( util - mx_u))
    #utils .= (exp.(utils.-mx_u))./sm                   # normalize by denominator 
    return nothing                                     # make sure this doesn't return, but operates on utils in place
end 

"""
`ZeroOut`
Dumb function to set a vector or any array equal to zero.
"""
function ZeroOut(x)
    for i = 1:length(x)
        x[i] = 0.0
    end 
end 




"""
`Contraction()`

Computes the contraction within a single market.

This should be:

δ^{t+1} = δ^{t} + log S_{.t} - log ( s_{.t}( ... ) )
- δ^t is previous iteration of values 
- log S_{.t} is log market shares from data 
- log (s_{.t} (...) ) are log computed market shares. 
- Uses a more numerically stable iteration computed using exp.(δ^t)

## Test ## 

shares = MarketShares(:yr, :ndc_code, :market_shares);
charcs = ProductChars(:yr, :ndc_code, :copay_high, :simple_fent, :simple_hydro, :simple_oxy, :DEA2, :ORAL);
params_indices, markets = MKT(10,3);
    # now markets is [93,10,52] - characteristics dim × individuals × markets (states)
cinc = markets[:,:,10];
market_shares = zeros(948, 52);
δ = rand(948);  #  initialize random
new_δ = rand(948) # initialize zero - should be fine.    
AllMarketShares(markets, params_indices[1], δ, charcs, market_shares)

Contraction(cinc, params_indices[1], charcs, shares[:,3], market_shares[:,1], δ, new_δ)

# TODO - too many products w/ very small shares?  many of empirical_shares./predicted_shares are very very large 
Could maybe start w/ dampening until good params are found.  

"""
function Contraction(mkt::Array, params::Array, products::Array, empirical_shares::Array, predicted_shares::Array, δ::Array, new_δ::Array ; ϵ = 1e-6, max_it = 100)
    ctr = 1 # keep a counter for debug 
    conv = 1.0
    curr_its = 1
    us = zeros(948)
    δ = exp.(δ) # to use the more numerically stable iteration 
    while (conv > ϵ) & (curr_its < max_it)
            # TODO - here predicted shares are not constant, but must be recomputed w/ the new delta every time. 
        println("how big are these: ", empirical_shares./predicted_shares)
        println("new δ before update: ", new_δ[1:10])
        new_δ .= δ.*(empirical_shares./predicted_shares) # NB some δ's get really big.           
        #new_δ .= δ .+ log.(empirical_shares) .- log.(predicted_shares)
        println("new δ after update: ", new_δ[1:10])
        conv = norm(new_δ - δ, 2)
        curr_its += 1
        δ = new_δ
        # now update the δ
        println("⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆⋆")
        println(" before share update", maximum(predicted_shares), " ", minimum(predicted_shares))
        # TODO - maybe the predicted_shares are not getting updated in this equation.  
            # worse - they are getting set to 0.  
        ZeroOut(us)
        PredShare(mkt, params, δ, products, predicted_shares, us)
        println("†††††††††††††††††††††††††††††† ")
        println(" after share update ", maximum(predicted_shares), " ", minimum(predicted_shares))
        println("diff: ", conv, " its: ", curr_its)
        println("**************")
    end 
end 

"""
`NormalizeVar(x)`

Normalizes the variable given by the vector x, subtracting the mean and dividing by the SD.
 
## Test ## 

NormalizeVar([1,0]) ≈ [+ √2, - √2]

"""
function NormalizeVar(x)   
    # check here that this has only one dimension
    if (minimum(size(x)) > 2)&(ndims(x) > 1)
        throw(ArgumentError("the argument x is too big, e.g., is not a column vector"))
    end
    μ = Statistics.mean(x)
    σ = Statistics.std(x)
    return (x.-μ)./σ  
end 

"""
`InitialParams(Characteristics, x...; rand_init = true )`
Will take a collection of demographics stored as tuples of OH-vectors and FrequencyWeights in x... 
and will return an initial vector, which can either be random or from a particular spot.
Will also return a collection of indexes corresponding to the dimension of the x... vectors 
Can set rand_init = false to start from a particular spot.

- `Characteristics` - how many characteristics will get random coefficients?  these have variances
- `x...` collection of demographic features stored as tuples of OH-vectors and FrequencyWeights
- `rand_init` = true; set to false to start from some particular set of parameters

TODO - this does not include the variance of the random shock on the characteristic  

## Test ## 
- broken ATM since another argument was added.  
mkt_chars = CSV.read("/Users/austinbean/Desktop/programs/opioids/state_demographics.csv", DataFrame) ;

mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop]);

race_w = convert(Array{Float64,2}, mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]]);

disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability]);

race = (OH(size(race_w, 2)), MFW(race_w));

disability = (OH(size(disability_w, 2)), MFW(disability_w));

a1, b1 = InitialParams(3, race, disability)

- not right ATM since another argument added 
b1 == [(1,6), (7,8)]
sum(a1 .≈ [  1.065729740994666, -0.829056350999318,  0.8962148070867403,  1.0436992067470956,  0.07009106904271295, -0.5353616478134361, -0.44631360818507515, 0.11163462482008807]) == 8
"""
function InitialParams(Characteristics, x...; rand_init = true )
    Random.seed!(323)
    ds = Array{Tuple{Int64,Int64},1}()
    curr = 1
    for (i, el) in enumerate(x)
        push!(ds, (curr,curr+length(el[1])-1))
        curr = curr +length(el[1]) 
    end   
    if rand_init 
        arr = randn(curr-1)  # generate random parameters
    else 
        arr = zeros(Float64, curr-1)
    end 
    push!(ds, (curr,curr+Characteristics-1))
    return vcat(arr, abs.(rand(Float64, Characteristics))), ds 
end 

"""
`MKT(N, C)`

Imports the demographics, draws a sample of simulated individuals according to those characteristics.  
- The variable N is the number of individuals drawn per market.
- C is the number of characteristics getting a random coefficient.   
- Returns a collection of those individuals, plus a collection of parameters of the right dimension (corresponding to the characteristcs AND the product features)

Returns a collection given by the call to PopMarkets at the bottom: 
(characteristics + # rand shocks) × number of individuals × number of markets 
"""
function MKT(N, C)

    N_individuals = N      # number of individuals to simulate per market.  
    N_characteristics = C  # number of characteristics getting a random coeff 

    mkt_chars = CSV.read("/Users/austinbean/Desktop/programs/opioids/state_demographics.csv", DataFrame) 
    mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop])
    # at least import the state-level data...
        # TODO - there are too many features here relative to other applications.  
        # could do sum of maybe the 20 - 49 popluation
    pop_w = convert(Array{Float64,2}, mkt_chars[!, [:pop_10_14, :pop_15_19, :pop_20_24, :pop_25_29, :pop_30_34, :pop_35_39, :pop_40_44, :pop_45_49, :pop_50_54, :pop_55_59, :pop_60_64, :pop_65_69, :pop_70_74, :pop_75_79, :pop_80_84, :pop_85_plus]])
        # males 20 - 49, 50++
    male_w = convert(Array{Float64,2}, mkt_chars[!, [:male_10_14, :male_15_19, :male_20_24, :male_25_29, :male_30_34, :male_35_39, :male_40_44, :male_45_49, :male_50_54, :male_55_59, :male_60_64, :male_65_69, :male_70_74, :male_75_79, :male_80_84, :male_85_plus]])
        # females 20 - 49, 50++
    female_w = convert(Array{Float64,2}, mkt_chars[!, [:female_10_14, :female_15_19, :female_20_24, :female_25_29, :female_30_34, :female_35_39, :female_40_44, :female_45_49, :female_50_54, :female_55_59, :female_60_64, :female_65_69, :female_70_74, :female_75_79, :female_80_84, :female_85_plus]])
        # white, black, other 
    race_w = convert(Array{Float64,2}, mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]])
        # leave as is.
    disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability])
        # HS or less, Some college or More 
    education_w = convert(Array{Float64,2}, mkt_chars[!, [:total_less_than_hs_grad, :total_hs_grad, :total_some_college, :total_bachelors, :total_less_than_9th_grade, :total_only_9_12_grade, :total_aa_degree, :total_ba_degree, :total_grad_degree]])
        # would be nice to get out of labor force 
    laborforce_w = convert(Array{Float64,2}, mkt_chars[!, [:in_lab_for_16_19, :in_lab_for_20_24, :in_lab_for_25_44, :in_lab_for_45_54, :in_lab_for_55_64, :in_lab_for_65_74, :in_lab_for_75_plus]])
        # unemployment 20 - 54
    unemployment_w = convert(Array{Float64,2}, mkt_chars[!, [:unemp_rate_16_plus, :unemp_rate_16_19, :unemp_rate_20_24, :unemp_rate_25_44, :unemp_rate_45_54, :unemp_rate_55_64, :unemp_rate_65_74, :unemp_rate_75_plus]])
        # not sure yet.  
    hhinc_w = convert(Array{Float64,2}, mkt_chars[!, [:hhinc_lt_10000, :hhinc_10_14999, :hhinc_15_24999, :hhinc_25_34999, :hhinc_35_49999, :hhinc_50_74999, :hhinc_75_99999, :hhinc_100_149999, :hhinc_150_199999, :hhinc_gt_200000]])
    states = convert(Array{String,1}, mkt_chars[!,:name])

    # sample systems
        # a tuple of one-hot vectors and weights, one for each state market. 
    pop = (OH(size(pop_w, 2)), MFW(pop_w))
    male = (OH(size(male_w, 2)), MFW(male_w))
    female = (OH(size(female_w, 2)), MFW(female_w))
    race = (OH(size(race_w, 2)), MFW(race_w))
    disability = (OH(size(disability_w, 2)), MFW(disability_w))
    education = (OH(size(education_w, 2)), MFW(education_w))
    labor = (OH(size(laborforce_w, 2)), MFW(laborforce_w))
    unemp = (OH(size(unemployment_w, 2)), MFW(unemployment_w))
    hhinc = (OH(size(hhinc_w, 2)), MFW(hhinc_w))

    params = InitialParams(3, pop, male, female, race, disability, education, labor, unemp, hhinc)
    # NB size of this is: ("features" = demographics + characteristics) × number of individuals × # of markets 
    # to index one person: sim_individuals[:, i, j] -> some person i in market j 
    sim_individuals = PopMarkets(states, N_individuals, N_characteristics, pop, male, female, race, disability, education, labor, unemp, hhinc)
    # products w/ their characteristics.   
    # shares, when available. 
    return params, sim_individuals  
end 



"""
`MarketShares(MKT...)`
Doesn't do anything but import and return the market share and product characteristic data.
Returns both the original data set and a subset called wanted_data w/ just the columns of interest. 
- Takes a set of arguments MKT... which are column indices  

## TEST ##

shares = MarketShares(:yr, :ndc_code, :market_shares)

1 yr
2 ndc_code
3 nat_pres_low
4 nat_pres_high
5 nat_pres_rand
6 nat_pats_low
7 nat_pats_high
8 nat_pats_rand
9 copay_low
10 deduct_low
11 copay_high
12 deduct_high
13 nat_total_pres_low
14 nat_total_pres_high
15 nat_total_pres_rand
16 nat_total_pats_low
17 nat_total_pats_high
18 nat_total_pats_rand
19 p75
20 ndccode
21 packagedescription
22 ndc11code
23 productndc
24 producttypename
25 proprietaryname
26 proprietarynamesuffix
27 nonproprietaryname
28 dosageformname
29 routename
30 startmarketingdate
31 endmarketingdate
32 marketingcategoryname
33 applicationnumber
34 labelername
35 substancename
36 strengthnumber
37 strengthunit
38 pharm_classes
39 deaschedule
40 status
41 lastupdate
42 packagendcexcludeflag
43 productndcexcludeflag
44 listingrecordcertifiedthrough
45 startmarketingdatepackage
46 endmarketingdatepackage
47 samplepackage
48 querycode
49 supplementary_querycode
50 DEA2
51 ORAL
52 simple_fent
53 simple_oxy
54 simple_hydro
55 _merge
56 outside_patients
57 outside_presc
58 market_shares
59 dd
"""
function MarketShares(MKT...) # take a variable identifying the market here
    # TODO here - split these up more effectively into markets, however divided.  
    market_shares = CSV.read("/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/national_shares.csv")
    wanted_shares = market_shares[!, [MKT...]]
    return convert(Array{Real,2}, wanted_shares)
end 

"""
`ProductChars(Characteristics...)`
Takes a set `Characteristics` of column indexes in the file and returns the characteristics 

## TEST ### 

charcs = ProductChars(:yr, :ndc_code, :copay_high, :simple_fent, :simple_hydro, :simple_oxy, :DEA2, :ORAL)
"""
function ProductChars(Characteristics...)
    # TODO - need to split into markets in the same way as MarketShares() does it.
    market_shares = CSV.read("/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/hcci_opioid_data/national_shares.csv")
    #wanted_characteristics = market_shares[!, [:yr, :ndc_code, :copay_high, :simple_fent, :simple_hydro, :simple_oxy, :DEA2, :ORAL ] ]
    wanted_characteristics = market_shares[!, [Characteristics...] ]
    return convert(Array{Real,2}, wanted_characteristics)
end 



#=
characteristics list from ACS:

geo_id
name
total_est_pop
pop_10_14
pop_15_19
pop_20_24
pop_25_29
pop_30_34
pop_35_39
pop_40_44
pop_45_49
pop_50_54
pop_55_59
pop_60_64
pop_65_69
pop_70_74
pop_75_79
pop_80_84
pop_85_plus

male_total_est_pop
male_10_14
male_15_19
male_20_24
male_25_29
male_30_34
male_35_39
male_40_44
male_45_49
male_50_54
male_55_59
male_60_64
male_65_69
male_70_74
male_75_79
male_80_84
male_85_plus

female_total_est_pop
female_10_14
female_15_19
female_20_24
female_25_29
female_30_34
female_35_39
female_40_44
female_45_49
female_50_54
female_55_59
female_60_64
female_65_69
female_70_74
female_75_79
female_80_84
female_85_plus

st_cd
st_abbrev

total_pop
total_pop_w_disability
total_pop_w_disability_male
total_pop_w_disability_female

total_less_than_hs_grad
total_hs_grad
total_some_college
total_bachelors
total_less_than_9th_grade
total_only_9_12_grade
total_aa_degree
total_ba_degree
total_grad_degree

all_med_earn_pr_yr_lt_h_grad
all_med_earn_pr_yr_h_grad
all_med_earn_pr_yr_sm_coll
all_med_earn_pr_yr_coll_deg
all_med_earn_pr_yr_grad_deg

male_less_than_hs_grad
male_hs_grad
male_some_college
male_bachelors
male_less_than_9th_grade
male_only_9_12_grade
male_aa_degree
male_ba_degree
male_grad_degree

male_med_earn_pr_yr_lt_h_grad
male_med_earn_pr_yr_h_grad
male_med_earn_pr_yr_sm_coll
male_med_earn_pr_yr_coll_deg
male_med_earn_pr_yr_grad_deg

female_less_than_hs_grad
female_hs_grad
female_some_college
female_bachelors
female_less_than_9th_grade
female_only_9_12_grade
female_aa_degree
female_ba_degree
female_grad_degree

fem_med_earn_pr_yr_lt_h_grad
fem_med_earn_pr_yr_h_grad
fem_med_earn_pr_yr_sm_coll
fem_med_earn_pr_yr_coll_deg
fem_med_earn_pr_yr_grad_deg

in_lab_for_16_19
in_lab_for_20_24
in_lab_for_25_44
in_lab_for_45_54
in_lab_for_55_64
in_lab_for_65_74
in_lab_for_75_plus

unemp_rate_16_plus
unemp_rate_16_19
unemp_rate_20_24
unemp_rate_25_44
unemp_rate_45_54
unemp_rate_55_64
unemp_rate_65_74
unemp_rate_75_plus

healthins_white_uninsured
healthins_lt_hs_grad_uninsured
healthins_hs_grad_uninsured
healthins_some_college_uninsured
healthins_ba_uninsured
healthins_in_lab_for_uninsured
healthins_employed_uninsured
healthins_in_lab_for_unemp_unins
healthins_not_in_labor_for_unins
healthins_num_uninsured

hhinc_lt_10000
hhinc_10_14999
hhinc_15_24999
hhinc_25_34999
hhinc_35_49999
hhinc_50_74999
hhinc_75_99999
hhinc_100_149999
hhinc_150_199999
hhinc_gt_200000

hhinc_median_income

race_white
race_afam
race_nativeam
race_asian
race_pacisland
race_other
=#