using Dates, CSV, Tables

abstract type substance_month end
abstract type zipcode_market end 

# top level is : dict{ COUNTY_YEAR, monthly_mme}



struct prod_year <: zipcode_market
	d::Dict{Dates.Year, Array{Float64,1}} # this dict will hold active ingredient, MME by months/year.
end 

struct monthly_mme <: substance_month 
	h::Dict{String,prod_year} # a substance and a mme quantity
end 

# Base: Dict{String, zip_mkt}

# Different way: County_state -> substance -> month -> quantity.

#  Dict{ 
#       County_state(string){ 
#                            Dict{ 
#                                  Substance(String) 
#                                                   Dict{
#                                                         Year, Array{Float64,1}} } }




function get_mme(x, outp::Dict{String, monthly_mme} ; datecol = 31, subscol = 36, countycol = 20, pill_count_coll = 25, statecol = 18, mmefactcol = 38,  quant_ingr_col = 32)
	dateformat = Dates.DateFormat("mmddyyyy")
	for i = 1:size(x, 1)
		county = x[i,countycol]                                                                          # location is a unique county/state pair as a string - what if it's missing?
		state = x[i, statecol]
		location = county*"_"*state
		# TODO - there are some missings in quant_ingr_col -> set to zero
		mme_equiv = x[i,mmefactcol]*x[i,pill_count_coll]*x[i, quant_ingr_col]                            # TODO - this isn't right yet, but let's get a version to start with.  - is MME by weight or by pill unit? 
		if ismissing(x[i,quant_ingr_col])
			mme_equiv = 0.0
		end 
		substance = x[i,subscol]
		date_month = Dates.month(Dates.Date( x[i, datecol] , dateformat))                                # CAUTION - Dates.month and Dates.Month are different functions.  Dates.month: Dates.Date -> Month (as an Int64)
			dm = Dates.Month(Dates.Date( x[i, datecol] , dateformat))
		date_year = Dates.Year(Dates.Date(x[i, datecol], dateformat))
		purch_date = Dates.Date(dm, date_year) 
		if haskey(outp, location)                                                     # if the state/county pair has been seen before, outp[location].h[string] -> a substance
			if haskey(outp[location].h, substance)                                    # the substance has been seen before.
				if haskey(outp[location].h[substance].d, date_year)                   # substance has been seen in that year.
					outp[location].h[substance].d[date_year][date_month] += mme_equiv # month will be an index 1-12
				else 
					outp[location].h[substance].d[date_year] = zeros(Float64,12)
					outp[location].h[substance].d[date_year][date_month] += mme_equiv             # date_month will be a 1-12 index
				end 
			else                                                                   # the substance has not been seen in that county before.
				outp[location].h[substance] = prod_year( Dict(date_year => zeros(Float64,12)) )
			end 
		else                                                                
			outp[location] = monthly_mme( Dict( substance => prod_year( Dict( date_year => zeros(Float64,12))) ) ) # if the state/county pair has not been seen before
			outp[location].h[substance].d[date_year][date_month] += mme_equiv 
		end
	end 
end 


# Test these types:
# Load a subset: 		
# f = CSV.read("/Users/tuk39938/Downloads/arcos_chunk1.csv"; header = 1, limit = 5000,  types=Dict("REPORTER_ZIP"=>String, "BUYER_ZIP"=>String, "TRANSACTION_DATE"=>String, "CALC_BASE_WT_IN_GM"=>Float64 ))
# outp = Dict{String, zip_mkt}()
# get_mme(f)

# Next steps - 
# this must be reorgnized... really I need to know what substances appear in a month, then if they are there in the month, what's the amount?  
#=
What it needs is... we have a county/state string, Month-Year pair.
Then within the month - substance/quantity.
Then the dict should really be:

zip_mkt = Dict{County_State, Object}
Object = Month_Year -> {Ingredient_Name, Quantity}

=#




function mme_output(x::Dict{String,monthly_mme}) # try to write this out by year...
	ctr::Int64 = 0
	# just record drugs with positive market share - add extras later, but be aware of market entry.  
	zip_dims = length(keys(x)) 
	labels::Int64 = 3
	months::Int64 = 12
	years::Int64 = 7
	subs_num::Int64 = 65
	outp_array = Array{Union{String, Number}}(undef, (zip_dims*subs_num), labels+months, years)
	for i in eachindex(outp_array)
		outp_array[i] = 0
	end
	# this is going to really suck... (zips × max subs) x (months + labels) × years = 7 
	# output should be: for each zip (col 1), drug (col 2), 12 months quantity (3 - 14) 
	# so there are something like: 20_000 zip codes, 12 months, some quantity of drug ingredients, 7 years.
	rowctr2006 = 0; rowctr2007 = 0; rowctr2008 = 0; rowctr2009 = 0; rowctr2010 = 0; rowctr2011 = 0; rowctr2012 = 0
	for k in keys(x)                     # this is the county_state 
		for sub in keys(x[k].h)          # these are substances as strings
			for year in keys(x[k].h[sub].d)    # year as a Dates.Year
				rowctr = 0
				if year == Dates.Year(2006)
					yrix = 1
					yrval = 2006
					rowctr2006 += 1
					rowctr = rowctr2006
				elseif year == Dates.Year(2007)
					yrix = 2
					yrval = 2007
					rowctr2007 += 1
					rowctr = rowctr2007
				elseif year == Dates.Year(2008)
					yrix = 3
					yrval = 2008
					rowctr2008 += 1
					rowctr = rowctr2008
				elseif year == Dates.Year(2009)
					yrix = 4 
					yrval = 2009
					rowctr2009 += 1
					rowctr = rowctr2009
				elseif year == Dates.Year(2010)
					yrix = 5
					yrval = 2010
					rowctr2010 += 1
					rowctr = rowctr2010
				elseif year == Dates.Year(2011)
					yrix = 6
					yrval = 2011
					rowctr2011 += 1
					rowctr = rowctr2011
				elseif year == Dates.Year(2012)
					yrix = 7
					yrval = 2012
					rowctr2012 += 1
					rowctr = rowctr2012
				else
					throw("vomit") 
				end 
				outp_array[rowctr, 1, yrix] = k
				outp_array[rowctr, 2, yrix] = sub
				outp_array[rowctr, 3, yrix] = yrval
				for mth = 1:12
					outp_array[rowctr, mth+labels, yrix] += x[k].h[sub].d[year][mth]
				end 
			end 
		end 
	end 
	return outp_array
end 



# Real data test 
function get_mme_data(x)
	mk1 = Dict{String, monthly_mme}()
	maxl = 0
	for i = 1:8
		println("Loading $i  ", now())
		f = CSV.read("/Users/tuk39938/Downloads/arcos_chunk$i.csv"; header = 1,  types=Dict("REPORTER_ZIP"=>String, "BUYER_ZIP"=>String, "TRANSACTION_DATE"=>String , "CALC_BASE_WT_IN_GM"=>Float64, "CALC_BASE_WT_IN_GM"=>Float64))
		println("Processing $i  ", now())
		get_mme(f, mk1)
		f = 0 # drop
	end
	println("Writing Output ", now())
	smth = mme_output(mk1)
	to_shares(smth)
	println("Saving ", now())
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2006.csv", Tables.table(smth[:,:, 1]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2007.csv", Tables.table(smth[:,:, 2]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2008.csv", Tables.table(smth[:,:, 3]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2009.csv", Tables.table(smth[:,:, 4]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2010.csv", Tables.table(smth[:,:, 5]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2011.csv", Tables.table(smth[:,:, 6]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
	CSV.write("/Users/tuk39938/Desktop/programs/ops/yearly_write_test_2012.csv", Tables.table(smth[:,:, 7]); header=["COUNTY", "SUBSTANCE", "YEAR", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"])
end 

"""
`to_shares` iterates
"""
function to_shares(arr1::Array)
	dim3 = size(arr1,3)
	rows = size(arr1,1)
	labels = 3
	for page = 1:dim3
		i = 1; j = 1;
		while arr1[i,1, page] != 0.0
			str1 = arr1[i, 1, page] # find the first county name 
			j = i+1                  # reassign j 
			# find where the current county name stops
			while (arr1[j,1, page] == str1)
				j+=1 
			end 
			# normalize
			for mnth = 1:12
				norm_const = sum(arr1[i:(j-1),mnth+labels, page])
				if norm_const > 0
					for ix = i:(j-1)
						arr1[ix,mnth+labels, page] /= norm_const
					end 	
				end 
			end 
			i = j                   # reassign i -> start at the end of the previous
		end 
	end 
end 


"""
`mme_dim_counter`
max number of substances in any county-month
"""
function mme_dim_counter(d)
	# Max substances in any county month is 65 in Broward, FL, 2011-12-01
	max_dim::Int64 = 0
	county = ""
	month = Dates.Date("01012001", "ddmmyyyy")
	for k1 in keys(d)            # these are county_state 
		for k2 in keys(d[k1].d)  # these are dates 
			# max month count clearly 12
			if length(keys(d[k1].d[k2].h)) > max_dim 
				max_dim = length(keys(d[k1].d[k2].h))
				month = k2
				county = k1 
			end 
		end 
	end 
	return max_dim, month, county 
end 

function year_min_max(x)
	dateformat = Dates.DateFormat("mmddyyyy")
	min_year::Dates.Year = Dates.Year(10_000)
	max_year::Dates.Year = Dates.Year(0)
	for i =1:size(x,1) 
		yr1 = Dates.Year(Dates.Date(x[i,:TRANSACTION_DATE], dateformat))
		if yr1 > max_year
			max_year = yr1
		end 
		if yr1 < min_year 
			min_year = yr1
		end 
	end 	
	return min_year, max_year
end 



function get_year(x)
	for i = 1:8
		println("Loading $i  ", now())
		f = CSV.read("/Users/tuk39938/Downloads/arcos_chunk$i.csv"; header = 1,   types=Dict("REPORTER_ZIP"=>String, "BUYER_ZIP"=>String, "TRANSACTION_DATE"=>String ))
		println(year_min_max(f))
		f = 0 # drop
	end
end 

# min year is 2006, max year is 2012.


# run functions 

get_mme_data(1)


