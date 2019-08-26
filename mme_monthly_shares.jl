using Dates, CSV, Tables

abstract type substance_month end
abstract type zipcode_market end 


struct monthly_mme <: substance_month 
	h::Dict{Date,Float64} # a Month/year (date) and a mme quantity
end 

struct zip_mkt <: zipcode_market
	d::Dict{String, monthly_mme} # this dict will hold active ingredient, MME by months/year.
end 



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


function get_mme(x, outp::Dict{String, zip_mkt}; datecol = 31, subscol = 36, countycol = 20, pill_count_coll = 25, statecol = 18, mmefactcol = 38,  quant_ingr_col = 32)
	dateformat = Dates.DateFormat("mmddyyyy")
	for i = 1:size(x, 1)
		county = x[i,countycol]                                              #location is a unique county/state pair as a string - what if it's missing?
		state = x[i, statecol]
		location = county*"_"*state
			# TODO - this isn't right yet, but let's get a version to start with.  - is MME by weight or by pill unit? 
		mme_equiv = x[i,mmefactcol]*x[i,pill_count_coll]*x[i, quant_ingr_col]
		substance = x[i,subscol]
		date_month = Dates.Month(Dates.Date( x[i, datecol] , dateformat)) 	# CAUTION - Dates.month and Dates.Month are different functions.  Dates.month: Dates.Date -> Month (as an Int64)
		date_year = Dates.Year(Dates.Date(x[i, datecol], dateformat))
		purch_date = Dates.Date(date_month, date_year) 
		if haskey(outp, location)                                           #if the state/county pair has been seen before
			if haskey(outp[location].d, substance)
				if haskey(outp[location].d[substance].h, purch_date)
					outp[location].d[substance].h[purch_date] += mme_equiv
				else 
					outp[location].d[substance].h[purch_date] = mme_equiv
				end 
			else
				outp[location].d[substance] = monthly_mme( Dict(purch_date => mme_equiv) )
			end 
		else                                                                # if the state/county pair has not been seen before
			outp[location] = zip_mkt( Dict( substance => monthly_mme( Dict(purch_date => mme_equiv)) )) 
		end 
	end 
end 

function market_shares(d::Dict{String, zip_mkt})



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