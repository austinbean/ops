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
#using GLM 
using DataFrames
using DataFramesMeta
using StatsBase
#using StaticArrays 
using LinearAlgebra 
using Statistics
using Random 
using Distributed
#using DistributedArrays
using SharedArrays

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

mkt_chars = CSV.read("./state_demographics.csv", DataFrame) 

mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop])

race_w = convert(Array{Float64,2}, mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]])

disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability])

race = (OH(size(race_w, 2)), MFW(race_w))

disability = (OH(size(disability_w, 2)), MFW(disability_w))

Sampler(4, race, disability)

# returns indexes corresponding to sampled element, so [5 1] has sampled fifth element of race, 1 of dis.  
"""
function Sampler(n, x...)
    # generates ONE random individual according to the objects in the list x...
    outp = zeros(Float64, 0)
    for (i,el) in enumerate(x) 
        outp = vcat(outp, findmax(sample(el[1], el[2][n]))[2]) # n is the index of the market sampling weights 
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

mkt_chars = CSV.read("./state_demographics.csv", DataFrame) 

mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop])

race_w = convert(Array{Float64,2}, Matrix(mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]]))

disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability])

race = (OH(size(race_w, 2)), MFW(race_w))

disability = (OH(size(disability_w, 2)), MFW(disability_w))

Population(100, 2, race, disability)

# returns a 2 × 100 array, where each column is an "individual" represented as a race (first element) and a disability status (last).  
Values correspond to indexes within category -> 5th element of race category.
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

- M indexes markets. A list of e.g., strings ("Alabama", "Arkansas", ... ) or years or market-years.  
- S is the number of individuals to be generated.
- Ch is an integer. indexes the number of characteristics w/ a random coefficient as an integer (?)
- x... is a list of demographics, e.g., pop_w, race_w, ... 


## TEST: ## 

mkt_chars = CSV.read("./state_demographics.csv", DataFrame) 

st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];
mkt_ids = sort([Base.Iterators.product(st1,yr1)...], by = x-> (x[1], x[2]))

pop_w = convert(Array{Float64,2}, Matrix(mkt_chars[!, [:pop_10_14, :pop_15_19, :pop_20_24, :pop_25_29, :pop_30_34, :pop_35_39, :pop_40_44, :pop_45_49, :pop_50_54, :pop_55_59, :pop_60_64, :pop_65_69, :pop_70_74, :pop_75_79, :pop_80_84, :pop_85_plus]]))

pop = (OH(size(pop_w, 2)), MFW(pop_w))

N_individuals = 100

N_characteristics = 3

sim_individuals, shocks = PopMarkets(st1, N_individuals, N_characteristics, pop)

# returns a 4 × 100 × 255 (characteristics × individuals × markets) array 

new_arr = sim_individuals
new_arr[2:end, :, :] += shocks

# this obtains the right values.  

"""
function PopMarkets(M, S, Ch, x...; years = 5)
    # get the simulated for S individuals demographics over all of the markets M w/ Ch characteristics and x... demographics.  
    length = size( Sampler(1, x...) , 1)
    mkts = size(M,1)
    mlen = mkts*years
    outp = zeros(Float64, length+Ch, S, mlen) # hold space open for the ν = μ + σ*ϵ version of the shocks.
    shocks = zeros(Float64, Ch, S, mlen)   
    for i = 1:mkts     
        for k = 1:years  
            outp[1:length,:,(i-1)*years+k] += Population(S, i, x...) 
            shocks[1:Ch,:,(i-1)*years+k] += randn(Ch, S)     # shocks, but think carefully about this.  These go on product features.  
        end 
    end 
    return outp, shocks  # separately holding demographics, shocks.  
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
st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];
shares, labs = MarketShares(st1, yr1);
charcs = ProductChars(:ndc_code, :avg_copay, :codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone,:other, :tramadol, :mme, :small_package, :medium_package,:large_package);
params_indices, common_params, markets, shocks = MKT(10,3);
    # now markets is [93,10,52] - characteristics dim × individuals × markets (states)
cinc = markets[:,:,10];

mean_u = zeros(size(shares[1])[1], 52);
AllMarketShares(markets, params_indices[1], zeros(948), charcs[1], mean_u)

mean_u 

## TODO ##
δ is market specific too.  Needs to be products × markets  
"""
function AllMarketShares(mkts::Array, params::Array, δ::Array, products::Array, mean_utils::Array)
    param_dim, n_individuals, n_markets = size(mkts)
    n_products, n_chars = size(products)
    ind_utils = zeros(n_products)
    for m = 1:n_markets
        mu = @view mean_utils[:,m] 
        mk = @view mkts[:,:,m]
        PredShare(mk, params, δ, products, mu, ind_utils)
    end 
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
st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];
shares, labs = MarketShares(st1, yr1);
charcs = ProductChars(:ndc_code, :avg_copay, :codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone,:other, :tramadol, :mme, :small_package, :medium_package,:large_package);
params_indices, common_params, markets, shocks = MKT(10,3);
    # now markets is [93,10,52] - characteristics dim × individuals × markets (states)
cinc = markets[:,:,10];
cin_shock = shocks[:,:,10];
mu = zeros(size(shares[1],1));
δ = zeros(size(shares[1],1));
ind_u = zeros(size(shares[1],1)); 
p = zeros(Float64,3);
PredShare(cinc, cin_shock, params_indices[1],params_indices[2] , δ, charcs, mu, ind_u, p)
@benchmark PredShare(cinc, cin_shock, params_indices[1],params_indices[2] , δ, charcs, mu, ind_u, p)


sum(ind_u) # does sum to nearly one.  



TODO - mean_utils should be an array with dimension equal to the number of markets.  Each market gets a row 
TODO - ind_utils can be pre-allocated at a higher level.  
TIMING - takes basically exactly 10x as long (and allocates 10x) as Util when individuals == 10.


"""
function PredShare(mkt, shk, params::Array, shk_params::Array, δ::Array, products::Array, market_shares,  ind_utils::Array, pd::Array)
    characs, individuals = size(mkt)                # number of features, number of individuals.  
    ZeroOut(market_shares)                          # be careful w/ this since it will zero out the **entire** market_shares Array.
    for i = 1:individuals
        v1 = @view mkt[:,i]                         # selects demographics for one "person" w/out allocating
        s1 = @view shk[:,i]                         
        # TODO - should all of these arguments be views??
        Util( v1, s1, products, δ, params, shk_params, ind_utils, pd )  # computes utility for ALL products in market for one person
        market_shares .+= ind_utils          
    end
    market_shares ./=individuals                    # take mean over individuals in the market - divide by N_individuals. 
    return nothing  
end 



"""
`Util(demographics, products_char::Array, δ::Array, params::Array, utils::Array)`
Compute the utility over all products for a single simulated person in the market 
- `demographics` is a view of an array of demographics for an individual
- `products_char` is an array of features 
- `δ` is an array of the current mean utilities 
- `params` is an array of the current set of parameters
- `utils` is an array w/ dimension equal to that of the products in the market.
- NB: operates in-place on the vector utils, which is reset to zero every time.  Cuts allocations somewhat
- NB: Products, δ must be in the same order


This is computing: exp ( δ + ∑_k x^k_jt (σ_k ν_i^k + π_k1 D_i1 + … + π_kd D_id ) / 1 + ∑ exp ( δ + ∑_k σ_k x^k_jt ν_i^k + π_k1 D_i1 + … + π_kd D_id )
- δ a mean util
- x^k_jt are characteristics getting a random coefficient.  
- σ_k a parameter multiplying a shock
- D_i1, ..., D_id are demographic characteristics (no random coeff, but param π_id)

## TEST ##
st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];
shares, labs =MarketShares(st1, yr1);
charcs = ProductChars(:ndc_code, :avg_copay, :codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone,:other, :tramadol, :mme, :small_package, :medium_package,:large_package);
params_indices, common_params, markets, shocks = MKT(10,3);
cinc = markets[:,:,10];
cin_shock = shocks[:,:,10];
utils = zeros(size(shares[1],1));
δ = zeros(size(shares[1],1));
pd = zeros(Float64,3)
shr = zeros(size(shares[1],1));
Util(cinc[:,1], cin_shock[:,1], charcs, shr, params_indices[1], params_indices[2] ,utils, pd );

@benchmark Util(cinc[:,1], cin_shock[:,1], charcs, shr, params_indices[1], params_indices[2] ,utils, pd)
  minimum time:     67.992 μs (0.00% GC)
  median time:      69.050 μs (0.00% GC)
  mean time:        75.198 μs (2.18% GC)
  maximum time:     1.942 ms (94.05% GC)

## Known answer test case ##
us = [0.0 0.0 0.0]
Util([1; 0; 0], ['x' 'y' 1 1], [0 0 0], [1; 1; 1], us)
us.≈[0.7112345942275937  0.09625513525746869  0.09625513525746869]

# TODO - approximately equals 1, but *very* approximately (w/in 0.1).  Should be able to do better.  
# TODO - made 40% faster, but can I do more?   multithreading makes max_time worse, FYI.

# TODO - problem currently is that shares and charcs have different dimensions.  Why?  Product characteristics
now are too numerous.  
"""
function Util(demographics, 
              shocks, 
              products_char::Array, 
              δ::Array, 
              demo_params::Array, 
              shock_params::Array, 
              utils::Array, 
              pd::Array)
    ZeroOut(utils)                                     # will hold utility for one guy over all of the products 
    num_prods, num_chars = size(products_char)
    ZeroOut(pd)
    demo_ix = size(demographics,1)-size(pd,1) # Starting point.  This is terrible.  
    for k = 1:size(pd,1)  
        @inbounds demographics[demo_ix+k] = shock_params[1,k] + shock_params[2,k]*shocks[k] # Creates the characteristic-specific shock first.  
    end 
    for j = 1:size(pd,1)   # == size(params,2) 
        for i = 1:size(demographics,1)                          # NOTE: demographics column has different dimensions from params (shorter, on purpose, see InitialParams).  
            @inbounds pd[j] += demo_params[i,j]*demographics[i]      # this term is constant across the products
        end 
    end 
    utils .+= δ
    for i = 1:num_prods                                     # NB: multithreading here makes max_time worse by 6x - 8x
        tmp_sum = 0.0                                       # reset the running utility for each person - weirdly faster than adding directly to utils[i]. 
        for j = 2:num_chars                                 # TODO - this can be redone so that it doesn't require keeping track of this 3.
            @inbounds tmp_sum += products_char[i,j]*pd[j]   # TODO - 90% of the allocation in this function takes place here.
        end 
        utils[i] += tmp_sum                                 # TODO - the other 10% of the allocation takes place here. 
    end   
    mx_u = maximum(utils)                                   # max for numerical stability - faster than doing the comparison every step in the main loop         
    sm = 1/exp(mx_u)                                        # denominator: 1/exp(mx_u) + sum (exp ( util - mx_u))
    for i = 1:length(utils)
        @inbounds sm += exp(utils[i]-mx_u)
        @inbounds utils[i] = exp(utils[i] - mx_u)
    end 
    utils ./=sm
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
`Contraction(mkt::Array, params::Array, products::Array, empirical_shares, predicted_shares, δ::Array, new_δ::Array ; ϵ = 1e-6, max_it = 5_000_000)`
- mkt::Array - a set of demographics for simulated individuals.
- params::Array -  the current set of parameters (e.g., β, σ)
- products::Array - a set of product features, needed to compute predicted shares 
- empirical_shares - these are shares from the data.
- predicted_shares - market shares are predicted given the δ's available at the current iteration
- δ::Array - the product-specific terms used in computing utility. 
- new_δ::Array - container to hold the new δ's after the update
- ϵ = 1e-6 - this will need to be set a lot lower eventually.  
- max_it = 5_000_000 - stop if it doesn't finish by then.
Computes the contraction within a single market.

This should be:

δ^{t+1} = δ^{t} + log S_{.t} - log ( s_{.t}( ... ) )
- δ^t is previous iteration of values 
- log S_{.t} is log market shares from data 
- log (s_{.t} (...) ) are log computed market shares. 

## Test ## 
st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];
shares, labs = MarketShares(st1, yr1);
charcs = ProductChars(:ndc_code, :avg_copay, :codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone,:other, :tramadol, :mme, :small_package, :medium_package,:large_package);
params_indices, common_params, markets, shocks = MKT(10,3);
    # now markets is [93,10,52] - characteristics dim × individuals × markets (states)
cinc = markets[:,:,10];
cinc_shock = shocks[:,:,10];
market_shares = zeros(size(shares[1],1), 52);
    # TODO - indexing here will allocate, @view instead. 
    emp_shr = @view shares[1][:,2] 
Contraction(cinc, cinc_shock, params_indices[1], params_indices[2], charcs, emp_shr, 4)


This allocates a lot and takes a while, b/c it is computing PredShares until convergence.  
numerically stable version frequently gives NaN, probably due to small mkt shares?   

Timing note: all overhead is due to Utils, via PredShares
# TODO - needs to take a market identifier and return one.  Easy. 
# TODO - now returns all NaNs pretty rapidly    

"""
function Contraction(mkt::Array, mkt_shock::Array, params::Array, shk_params::Array, products::Array, empirical_shares, ID; ϵ = 1e-6, max_it = 5)
    conv = 1.0
    curr_its = 1
    us = zeros(size(products,1),1)                      # TODO - check that this will be right.  
    δ = zeros(size(empirical_shares,1),1).+=(1/size(empirical_shares,1))
    new_δ = zeros(size(empirical_shares,1))             # TODO - these can be started at a better value, like log(s) - log(s_0)
    predicted_shares = zeros(size(empirical_shares,1),1)
    pd = zeros(Float64, size(mkt_shock,1),1)            # The number of random coefficients.
    while (conv > ϵ) & (curr_its < max_it)
        # debugging related... 
        conv = norm(new_δ.-δ, Inf) 
        two_norm = norm(new_δ.-δ, 2)
        if curr_its%1000 == 0
            @info ID curr_its conv two_norm
        end 
        PredShare(mkt, mkt_shock, params, shk_params, new_δ, products, predicted_shares, us, pd)
        # now update the δ
        for i = 1:length(new_δ)
            δ[i] = new_δ[i]                                                             # copy/reassign so that I can preserve these values to compare.  
            new_δ[i] = new_δ[i] + (log(empirical_shares[i]) - log(predicted_shares[i]))  
        end 
        curr_its += 1
    end 
    return ID, new_δ
end 

"""
`FastContraction(mkt::Array, params::Array, products::Array, empirical_shares, predicted_shares, δ::Array, new_δ::Array ; ϵ = 1e-6, max_it = 5_000_000)`
A version of the Ryngaert/Varadhan/Nash (2012) faster BLP contraction.  
See Section 2.3 for the equation.  
See also MST RCNL.f90 lines 4737 - 4775 for an implementation  
TODO
"""
function FastContraction(mkt::Array, params::Array, products::Array, empirical_shares, predicted_shares, δ::Array, new_δ::Array ; ϵ = 1e-6, max_it = 5_000_000)
    return nothing 
end 



"""
`FormError(mkts, params::Array, products::Array, empirical_shares, predicted_shares)`
- mkts: the markets, e.g., demographics for N simulated individuals in the markets
- mkt_shocks: shocks for the random coeffs of N individuals in the market 
- params::Array: Current value of the parameters, except those for the shocks 
- shk_params::Array: Current value of the mean and variance of the shock parameters
- common_params::Array: current value of the common parameters.  
- products::Array: product characteristics 
- empirical_shares: data, e.g., the empirical shares 
- IDs: a vector of IDs (here tuples of "state abbrev" and int year)
- random_coeffs = 3: number of random coefficients.  

This will pmap the Contraction function across the markets to recover the error ω.
Computes ω = δ - X_1 Θ_1, where X_1 is J × T, where J is the number of products and T is the number of markets.  
Per appendix Step 0, X_1 contains the components of the δ in Equation (3) in RG p.520.
So δ_jt = x_jt β - α p_jt + ξ_jt.  The contraction recovers δ_jt.   
There is a current set of parameters θ_1 = (β, α) which are in params.
The characteristics are in products.  This is the X_1 in X_1 Θ_1
So all that is necessary is to recover ξ_jt = δ_jt - X_jt (β α) 
These are the characteristics without random coefficients.   

# Test 

st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];

cop = (:copay, [:copay]) 
ingr = (:active_ingredient, [:codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone, :other, :tramadol]) 
mme = (:mme, [:mme])
pack = (:package_size, [:small_package, :medium_package, :large_package])

mkt_ID = [ Iterators.product(st1, yr1)...]
shares, labs =MarketShares(st1, yr1);
charcs = ProductChars(:ndc_code, :avg_copay, :codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone,:other, :tramadol, :mme, :small_package, :medium_package,:large_package);
params_indices, common_params, markets, shocks = MKT(10,3);
common_params, common_locs, common_names = ProductParams(cop, ingr, mme, pack)

labs, val = FormError(markets, shocks, params_indices[1], params_indices[2], common_params, charcs, shares, labs)

TODO - need to fix the products × params issue.  
TODO - fix tolerance when debugging is done!
TODO - several of these return all NaNs.  
("CA", 2009)
("DE", 2009)
("HI", 2009)
("DC", 2012)
("SD", 2013) 

"""
function FormError(mkts, mkt_shocks, params::Array, shk_params::Array, common_params::Array, products::Array, empirical_shares, IDs; random_coeffs = 3)
    demos, individuals, num_mkts = size(mkts)
    m = [ mkts[:,:,k] for k = 1:size(mkts,3)]  # faster than a loop   
    s = [ mkt_shocks[:,:,k] for k = 1:size(mkt_shocks,3)]
    p = [params for k = 1:num_mkts]      
    sp = [shk_params for k = 1:num_mkts] 
    prods = [products for k = 1:num_mkts]
        # x[1] - markets, m as above
        # x[2] - market shocks, s as above
        # x[3] - parameters, repeated for each processor
        # x[4] - shock parameters, repeated for each processor 
        # x[5] - products, comes w/ right dimension.
        # x[6] - empirical shares, comes w/ right dimension.
        # x[7] - market-level ID's 
    contract_δ = pmap(x->Contraction(x[1], x[2], x[3], x[4], x[5], x[6], x[7]), zip(m, s, p, sp, prods, empirical_shares, IDs))
    labels, new_δ = ([x[1] for x in contract_δ], [x[2] for x in contract_δ]) # separate to regress.
        # TODO - is does not make sense to do these as rows since the storage order is column major.  
    mkt_δ = reduce(hcat, new_δ)
    err = zeros(size(mkt_δ)) # TODO - preallocate this 
    for i = 1:size(mkt_δ,2) # up to 255 
        for j = 1:size(mkt_δ, 1)  # up to 
        pv = @view products[j, 2:end]
        mv = @view common_params[:]       
        err[j,i] = mkt_δ[j,i] - pv'*mv# form error here.  
        end 
    end 
    # reshape to stack 
    err = reshape(err, (size(err,1)*size(err,2), 1)) # dimensions are J products × T markets 
    # TODO - these must be sorted so that the order respects that of the instruments.
    return labels, err   
end 


"""
GMM()
- W/ the error in hand, form the GMM objective.  
- The instruments are constant obviously.
- This function should call `FormError`
- We want:

ω(θ)'ZΦZ'ω(θ)


The matrices are now the right shape...

# TODO - Φ function 

"""
function GMM(err::Array, Z::Array)
    # TODO - these dimensions aren't right anyway.  
    Φ =  I(size(transpose(err)*Z,1), size(transpose(Z)*err,2))# TODO
    (transpose(err)*Z)*Φ*(transpose(Z)*err)
    return nothing 
end 


"""
`Instruments`
- These instruments are created in differentiation_ivs.do
- They are organized by Year - State - NDC code 
- All are normalized so they have mean 0 and variance 1.  This is fine -  gives numerically identical results in the linear case.
- There are ten instruments in this order:
1.  "smme_prod_instrument", 
2.  "sp_prod_instrument", 
3.  "scov_price_ingredient_instrument", 
4.  "scov_mme_package_instrument", 
5.  "scov_price_package_instrument", 
6.  "scov_price_mme_instrument", 
7.  "ssub_instrument", 
8.  "spackage_instrument", 
9.  "smme_instrument", 
10. "sp_instrument"


TODO - there is still something to do w/ the p̂ values from Gandhi/Houde.

# Checking the size of this or something else... 
    # Now there are a huge number of missing values here - why? 
i1 = Instruments()

"""
function Instruments()
    # load the instruments generated by differentiation_ivs.do.  
    inst = CSV.read("./differentiation_ivs.csv", DataFrame)
        # There are missing vals in the DataFrame now.
    return Matrix{Union{Float64,Missing}}( inst[!, ["smme_prod_instrument", "sp_prod_instrument", "scov_price_ingredient_instrument", "scov_mme_package_instrument", "scov_price_package_instrument", "scov_price_mme_instrument", "ssub_instrument", "spackage_instrument", "smme_instrument", "sp_instrument"]])  
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

- `Characteristics` - how many characteristics will get random coefficients?  these have variances > 0
- `Characteristics` - must also have means.
- `x...` collection of demographic features stored as tuples of OH-vectors and FrequencyWeights
- The `x...` features are "dummy trap coded".  Fix first value here to zero.
- `rand_init` = true; set to false to start from some particular set of parameters
- The returned items are a vector w/ the parameter values 
- FIXME: [Not correct at the moment] A vector of tuples recording where each demographic item stops and finishes
- Then a separate matrix w/ the random coefficient pieces.  
- the locations of the means of the random coefficients.
- Followed by the locations of the variances of the random coefficients.  
- The last 2*#(characteristics) + [#(characteristics) × #(characteristics)] items should be handled carefully.  
- For each characteristic i, the last element in the block is the variance. 
- For each characteristic i, the second last in this block is the mean.
- the #(c) × #(c) prior to that, the i-th element of row i is the σ.  The j ≂̸ i are the covariances among different product characteristics.
- Then for each individual we have drawn N(0,1) shocks η', so the shock for the individual is actually: η_i = μ_i + η'_i*σ_i
- This appears interacted w/ the i-th random characteristic
- But also in the j-th random characteristic via ρ_ij ( η_j ) = ρ_ij ( μ_i + η'_i*σ_i)
- Params vector returned by initial params is LONGER than demographics.  

## Test ## 
mkt_chars = CSV.read("./state_demographics.csv", DataFrame) ;

mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop]);

race_w = Matrix{Float64}( mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]]);

disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability]);

race = (OH(size(race_w, 2)), MFW(race_w));

disability = (OH(size(disability_w, 2)), MFW(disability_w));

a1, b1, c1 = InitialParams(3, race, disability)

- not right ATM since another argument added 
b1 == [(1,6), (7,8)]
sum(a1 .≈ [  1.065729740994666, -0.829056350999318,  0.8962148070867403,  1.0436992067470956,  0.07009106904271295, -0.5353616478134361, -0.44631360818507515, 0.11163462482008807]) == 8

TODO: indices are not right, but they aren't being used so whatever.     
"""
function InitialParams(Characteristics, x...; rand_init = true )
    Random.seed!(323)
    ds = Array{Tuple{Int64,Int64},1}()
    curr = 1
    len = 0
    first_ix = zeros(Int64, length(x)) # this will be length(x) long 
        # creates tuples corresponding to parameters, records how many parameters there are.
    for (i, el) in enumerate(x)
        push!(ds, (curr,curr+length(el[1])-1))
        first_ix[i] = curr
        curr = curr +length(el[1])
        len += length(el[1])
    end   
    if rand_init 
        arr = randn(len, max(Characteristics,1))  # generate random parameters
    else 
        arr = zeros(Float64, len, max(Characteristics,1))
    end 
    for j ∈ first_ix 
        arr[j,:] .= 0.0   # reset these back to zero to make multiplication easier.  
    end 
    if Characteristics > 0 
        # means of the characteristics.  
        push!(ds, (curr,curr+Characteristics-1))
        curr = curr +max(Characteristics,1)
        push!(ds, (curr,curr+Characteristics-1))
        # duplicate this to get the variances.
        curr += 1
        push!(ds, (curr,curr+Characteristics-1))
        curr = curr +max(Characteristics,1)
        push!(ds, (curr,curr+Characteristics-1))
    end  # NB:If characteristics == 0, vcat below has the correct dimension.  
    vcv =  rand(Float64, Characteristics, Characteristics)
    # tODO - identity matrix of dim #(characteristics) here.  Zeros(Characteristics,Characteristics).+I(Characteristics)
    if Characteristics > 0   # Order below: parameters, means, variances, correlation parameters Ρ.
        return vcat(arr, vcv), vcat(rand(Float64,1,Characteristics), abs.(rand(Float64,1,Characteristics))), ds, first_ix  # can return len if need params less random coeffs.  
    else
        return arr, ds, first_ix # special case when there are no random characteristics - not that relevant.  
    end 
end 


"""
`ProductParams`
This function returns the parameters which multiply the characteristics within δ_jt.
Since δ_jt = x_{jt}β- α p_{jt} + ξ_{jt} we need parameters multiplying the product
characteristics which are shared across all individuals in the market. 

- Takes a collection of product characteristics and returns some parameters.  
 
 cop = (:copay, [:copay]) 
 ingr = (:active_ingredient, [:codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone, :other, :tramadol]) 
 mme = (:mme, [:mme])
 pack = (:package_size, [:small_package, :medium_package, :large_package])


ProductParams(cop, ingr, mme, pack)
"""
function ProductParams(Characteristics...)
    Random.seed!(31) 
    # 13 total
    locs = Array{Tuple{Int64,Int64},1}() 
    name_loc = Array{Tuple{Symbol, Int64},1}()
    ix = 1
    tot_p = 0
    for el in Characteristics
        tot_p += length(el[2])
        tup1 = (ix, ix+(length(el[2])-1))
        push!(locs, tup1 )
        for i = 1:length(el[2])        
            push!(name_loc, (el[2][i], ix+i-1))
        end 
        ix += length(el[2])
    end  
    return randn(ix-1), locs, name_loc   
end 






"""
`MKT(N, C)`

Imports the demographics, draws a sample of simulated individuals according to those characteristics.  
- The variable N is the number of individuals drawn per market.
- C is the number of characteristics getting a random coefficient.   
- Returns a collection of those individuals, plus a collection of parameters of the right dimension (corresponding to the characteristcs AND the product features)

Returns a collection given by the call to PopMarkets at the bottom: 
(characteristics + # rand shocks) × number of individuals × number of markets 

# Test:

mkk = MKT(10,3)
mkk[3] # the demographics across markets.  
mkk[4] # shocks, so random coefficient draws 

# TODO - how many markets?  State × year I think. 

# For PyBLP:

sim_individuals, shocks = PopMarkets(states, N_individuals, N_characteristics, pop, male, female, race, disability, education, labor, unemp, hhinc)

"""
function MKT(N, C)

    N_individuals = N      # number of individuals to simulate per market.  
    N_characteristics = C  # number of characteristics getting a random coeff 

    mkt_chars = CSV.read("./state_demographics.csv", DataFrame) 
    mkt_chars[!,:total_est_pop] = log.(mkt_chars[!,:total_est_pop])
    # at least import the state-level data...
        # TODO - there are too many features here relative to other applications.  
        # could do sum of maybe the 20 - 49 popluation
    pop_w = Matrix{Float64}( mkt_chars[!, [:pop_10_14, :pop_15_19, :pop_20_24, :pop_25_29, :pop_30_34, :pop_35_39, :pop_40_44, :pop_45_49, :pop_50_54, :pop_55_59, :pop_60_64, :pop_65_69, :pop_70_74, :pop_75_79, :pop_80_84, :pop_85_plus]])
        # males 20 - 49, 50++
    male_w = Matrix{Float64}( mkt_chars[!, [:male_10_14, :male_15_19, :male_20_24, :male_25_29, :male_30_34, :male_35_39, :male_40_44, :male_45_49, :male_50_54, :male_55_59, :male_60_64, :male_65_69, :male_70_74, :male_75_79, :male_80_84, :male_85_plus]])
        # females 20 - 49, 50++
    female_w = Matrix{Float64}( mkt_chars[!, [:female_10_14, :female_15_19, :female_20_24, :female_25_29, :female_30_34, :female_35_39, :female_40_44, :female_45_49, :female_50_54, :female_55_59, :female_60_64, :female_65_69, :female_70_74, :female_75_79, :female_80_84, :female_85_plus]])
        # white, black, other 
    race_w = Matrix{Float64}( mkt_chars[!, [:race_white, :race_afam, :race_nativeam, :race_asian, :race_pacisland, :race_other]])
        # leave as is.
    disability_w = hcat(mkt_chars[!,:total_pop]-mkt_chars[!,:total_pop_w_disability], mkt_chars[!,:total_pop_w_disability])
        # HS or less, Some college or More 
    education_w = Matrix{Float64}( mkt_chars[!, [:total_less_than_hs_grad, :total_hs_grad, :total_some_college, :total_bachelors, :total_less_than_9th_grade, :total_only_9_12_grade, :total_aa_degree, :total_ba_degree, :total_grad_degree]])
        # would be nice to get out of labor force 
    laborforce_w = Matrix{Float64}( mkt_chars[!, [:in_lab_for_16_19, :in_lab_for_20_24, :in_lab_for_25_44, :in_lab_for_45_54, :in_lab_for_55_64, :in_lab_for_65_74, :in_lab_for_75_plus]])
        # unemployment 20 - 54
    unemployment_w = Matrix{Float64}( mkt_chars[!, [:unemp_rate_16_plus, :unemp_rate_16_19, :unemp_rate_20_24, :unemp_rate_25_44, :unemp_rate_45_54, :unemp_rate_55_64, :unemp_rate_65_74, :unemp_rate_75_plus]])
        # not sure yet.  
    hhinc_w = Matrix{Float64}( mkt_chars[!, [:hhinc_lt_10000, :hhinc_10_14999, :hhinc_15_24999, :hhinc_25_34999, :hhinc_35_49999, :hhinc_50_74999, :hhinc_75_99999, :hhinc_100_149999, :hhinc_150_199999, :hhinc_gt_200000]])
    states = Vector{String}( mkt_chars[!,:name])

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

    # TODO:  dumb place to put these
    cop = (:copay, [:copay]) 
    ingr = (:active_ingredient, [:codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone, :other, :tramadol]) 
    mme = (:mme, [:mme])
    pack = (:package_size, [:small_package, :medium_package, :large_package])

    common_params, common_locs, common_names = ProductParams(cop, ingr, mme, pack)
    params = InitialParams(3, pop, male, female, race, disability, education, labor, unemp, hhinc)
    # NB size of this is: ("features" = demographics + characteristics) × number of individuals × # of markets 
    # to index one person: sim_individuals[:, i, j] -> some person i in market j 
    sim_individuals, shocks = PopMarkets(states, N_individuals, N_characteristics, pop, male, female, race, disability, education, labor, unemp, hhinc)
    new_arr = sim_individuals 
    new_arr[(end-2):end, :, :] += shocks
    # products w/ their characteristics.   
    # shares, when available. 
    return params, common_params, sim_individuals, shocks, new_arr 
end 



"""
`MarketShares(mkt_vars::Array, MKT...)`
Doesn't do anything but import and return the market share and product characteristic data.
Returns both the original data set and a subset called wanted_data w/ just the columns of interest. 
- Takes a set of arguments MKT... which are column indices  
- Slightly awful, but returns a vector: (state, year, [ndc_code, market_share]), 
- Can iterate over state-year combinations like that.  
- Comes sorted from mkt_shares.do  
-  
## TEST ##
st1 = ["AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"];
yr1 = [2009, 2010, 2011, 2012, 2013];
a1, a2 = MarketShares(st1, yr1)
TODO: hold el[1], el[2] separate and return separately.  

## To check the size... 
a1, a2 = MarketShares(st1, yr1)
outp = []
for el = 1:size(a1,1)
    for s = 1:size(a1[el],1)
       push!(outp, a1[el][s]) 
    end
end 
size(outp)
"""
function MarketShares(MKT...) # take a variable identifying the market here
    # TODO - rewrite to return two vectors, one w/ data the other w/ state/year. 
    inp_shares = CSV.read("./state_year_shares.csv", DataFrame) # |> DataFrame 
    market_shares = Array{Array{Union{String,Real},2}, 1 }() 
    labels = Array{ Tuple{ String, Int64 } , 1}()
    for el in Iterators.product(MKT...)
        tm1 = Matrix{Union{String,Real}}(inp_shares[ (inp_shares[!,:state].==el[1]).&(inp_shares[!,:yr].==el[2]) , [:ndc_code, :market_share]])
        push!(labels, (el[1], el[2]))
        push!(market_shares, tm1)
    end 
    return market_shares, labels 
end 

"""
`ProductChars(mkt_vars::Array, Characteristics...)`
Takes a set `Characteristics` of column indexes in the file and returns the characteristics 
NB: comes sorted out of mkt_shares.do.
TODO - make sure all future continuous variables are normalized.
TODO - need variables to split the market up 
TODO - would make sense to keep the list so that InitialParams will still behave as intended.  
## TEST ### 
charcs = ProductChars(:ndc_code, :avg_copay, :codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone,:other, :tramadol, :mme, :small_package, :medium_package,:large_package)

Columns: 
["ndc_code", 
 "avg_copay", 
 "codeine", 
 "hydrocodone", 
 "hydromorphone", 
 "methadone", 
 "morphine", 
 "oxycodone", 
 "other", 
 "tramadol", 
 "mme", 
 "small_package", 
 "medium_package", 
 "large_package"]

 Categories:
 [:ndc_code, [:copay]], 
 [:copay, [:copay]], 
 (:active_ingredient, [:codeine, :hydrocodone, :hydromorphone, :methadone, :morphine, :oxycodone, :other, :tramadol]) 
 [:mme, [:mme]], 
 (:package_size, [:small_package, :medium_package, :large_package])

"""
function ProductChars(Characteristics...)
    inp_charcs = CSV.read("./products_characteristics.csv",DataFrame)
    charcs = inp_charcs[ !, [Characteristics...]] 
    # normalize cols 2 and 11, copay and mme.
    charcs[:,2] =NormalizeVar(charcs[:,2])
    charcs[:,11] = NormalizeVar(charcs[:,11])  
    return Matrix{Float64}(charcs )
end 


