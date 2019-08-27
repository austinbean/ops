using Dates, CSV, Tables

abstract type substance_month end
abstract type zipcode_market end 


struct monthly_mme <: substance_month 
	h::Dict{String,Float64} # a substance and a mme quantity
end 

struct zip_mkt <: zipcode_market
	d::Dict{Date, monthly_mme} # this dict will hold active ingredient, MME by months/year.
end 

# change this to handle years...?  It makes more sense to organize it that way, I think.  


# Test these types:
# Load a subset: 		
# f = CSV.read("/Users/tuk39938/Downloads/arcos_chunk1.csv"; header = 1, limit = 5000,  types=Dict("REPORTER_ZIP"=>String, "BUYER_ZIP"=>String, "TRANSACTION_DATE"=>String ))
# outp = Dict{String, zip_mkt}()
# get_mme(f, outp)

# Next steps - 
# this must be reorgnized... really I need to know what substances appear in a month, then if they are there in the month, what's the amount?  
#=
What it needs is... we have a county/state string, Month-Year pair.
Then within the month - substance/quantity.
Then the dict should really be:

zip_mkt = Dict{County_State, Object}
Object = Month_Year -> {Ingredient_Name, Quantity}

=#
	# (2) Get shares from this.  


function get_mme(x, outp::Dict{String, zip_mkt} ; datecol = 31, subscol = 36, countycol = 20, pill_count_coll = 25, statecol = 18, mmefactcol = 38,  quant_ingr_col = 32)
	dateformat = Dates.DateFormat("mmddyyyy")
	for i = 1:size(x, 1)
		county = x[i,countycol]                                                                          # location is a unique county/state pair as a string - what if it's missing?
		state = x[i, statecol]
		location = county*"_"*state
		mme_equiv = x[i,mmefactcol]*x[i,pill_count_coll]*x[i, quant_ingr_col]                            # TODO - this isn't right yet, but let's get a version to start with.  - is MME by weight or by pill unit? 
		substance = x[i,subscol]
		date_month = Dates.Month(Dates.Date( x[i, datecol] , dateformat))                                # CAUTION - Dates.month and Dates.Month are different functions.  Dates.month: Dates.Date -> Month (as an Int64)
		date_year = Dates.Year(Dates.Date(x[i, datecol], dateformat))
		purch_date = Dates.Date(date_month, date_year) 
		if haskey(outp, location)                                                                        # if the state/county pair has been seen before
			if haskey(outp[location].d, purch_date)
				if haskey(outp[location].d[purch_date].h, substance)
					outp[location].d[purch_date].h[substance] += mme_equiv
				else 
					outp[location].d[purch_date].h[substance] = mme_equiv
				end 
			else
				outp[location].d[purch_date] = monthly_mme( Dict(substance => mme_equiv) )
			end 
		else                                                                
			outp[location] = zip_mkt( Dict( purch_date => monthly_mme( Dict( substance => mme_equiv)) )) # if the state/county pair has not been seen before
		end 
	end 
	return outp 
end 


function mme_output(x::Dict{String,zip_mkt}, year::Int64) # try to write this out by year...
	ctr::Int64 = 0
	# just record drugs with positive market share - add extras later, but be aware of market entry.  
	zip_dims = length(keys(x)) # this is not right.  There are many substances per zip-month!
	labels::Int64 = 3
	months::Int64 = 12
	years::Int64 = 7
	outp_array = Array{Union{String, Float64}}(undef, zip_dims, labels+months)
	for i in eachindex(outp_array)
		outp_array[i] = 0
	end
	# output should be: for each zip (col 1), drug (col 2), 12 months quantity (3 - 14) 
	# so there are something like: 20_000 zip codes, 12 months, some quantity of drug ingredients, 7 years.
	rowctr = 1
	for k in keys(x)           # this is the county_state 
		for dt in keys(x[k].d) # these are dates as Month-Year
			if Dates.Year(dt) == year 
				yr = Dates.Year(dt)
				mnth = Dates.Month(dt)
				for sub in keys(x[k].d[dt])
					outp_array[rowctr, 1] = k
					outp_array[rowctr, 2] = substance
					outp_array[rowctr, 3] = yr
				end 
			end 
		end 
	end 
	return outp_array
end 


# Real data test 
function get_mme_data(x)
	mk1 = Dict{String, zip_mkt}()
	for i = 1:8
		println("Loading $i  ", now())
		f = CSV.read("/Users/tuk39938/Downloads/arcos_chunk$i.csv"; header = 1, limit = 500,  types=Dict("REPORTER_ZIP"=>String, "BUYER_ZIP"=>String, "TRANSACTION_DATE"=>String ))
		println("Processing $i  ", now())
		get_mme(f, mk1)
		f = 0 # drop
	end
	return mk1
	# println("Writing Output ", now())
	# smth = output_array(mk1)
	# println("Saving ", now())
	# CSV.write("/Users/tuk39938/Desktop/programs/ops/short_test.csv", Tables.table(smth); header=["zip_code", "substance", "date", "ctr"])
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







#