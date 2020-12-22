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


"""
`FW(x)`
Takes the object x and maps it to FrequencyWeights for use in sampling.
x should be a vector of real numbers of some kind

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

TEST: 

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

TEST: 


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


TEST: 
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
        outp[(length+1):end,:,i] += randn(Ch, S)     # shocks, but think carefully about this.  
    end 
    return outp 
end 

### TODO 
function DemographicParams(x...)
    # do I need something like this?  
    return nothing 
end 

function PredUtil(D)
    return nothing
end 

function SimShares()
    return nothing
end 


"""
`NormalizeVar(x)`

Normalizes the variable given by the vector x, subtracting the mean and dividing by the SD.

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
`MKT(N)`

Imports the demographics, draws a sample of simulated individuals according to those characteristics.  
The variable N is actually not used.

Returns a collection given by the call to PopMarkets at the bottom: 
(characteristics + # rand shocks) × number of individuals × number of markets 
"""
function MKT(N)

    N_individuals = 100
    N_characteristics = 3

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

    # NB size of this is: "features" × number of individuals × # of markets 
    # to index one person: sim_individuals[:, i, j] -> some person i in market j 
    sim_individuals = PopMarkets(states, N_individuals, N_characteristics, pop, male, female, race, disability, education, labor, unemp, hhinc)
    # products w/ their characteristics.   
    # shares, when available.  
end 


function Product(N)
    product_chars = CSV.read("/Users/austinbean/Google Drive/Current Projects/HCCI Opioids/simple_product_chars.csv", DataFrame)
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