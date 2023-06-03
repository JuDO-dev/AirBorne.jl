using DirectSearch
include("rel_error_std_deviation.jl")
include("Data.jl")

ticker_symbol = "AAPL"
start_date = "2022-07-31"
end_date = "2022-08-05"
all_data = get_data(ticker_symbol, start_date, end_date, "", "1m")
all_data = all_data[1:end-1, 6]
all_data = all_data[.~(isnan.(all_data))]

system_dimension = 1 #How many signals are added to the Hankel matrix

#L_max = floor((size(all_data,1)+1)/(system_dimension+1)) #This is the maximum possible depth according to the BC theory. Added as a constraint
p = DSProblem(5; objective=MADS_std_deviation, initial_point=[21, 0.01, 2, 5, 1])
#SetIterationLimit(p, 20)
# i = 1 #Index of variabels that are granular
# SetGranularity(p, i, 1.0)
gamma_granularity = 0.01
SetGranularity(p, Dict( 1 => 1, 2 => gamma_granularity, 3 => 1, 4 => 1, 5 => 1))
#cons(x) = [-x[1] -x[2]] #Constraints x[1] to be greater than or equal to 0

#Constraints on Length (depth) of the Hankel matrix
consL(x) = x[1] > 1
AddExtremeConstraint(p, consL)

consL2(x) = x[1] < floor(((size(all_data, 1)/x[4]) - x[3])*0.75) - x[1] + x[5]
AddExtremeConstraint(p, consL2)

#Constraints on gamma
consgamma(x) = x[2] > 0
AddExtremeConstraint(p, consgamma)

#constraints on data size
consdata_size(x) = x[3] >= 0 
AddExtremeConstraint(p, consdata_size)
consdata_size2(x) = x[3] <= floor((size(all_data,1)/x[4])*3/4) 
AddExtremeConstraint(p, consdata_size2)

#constrains on sample sample_frequency
cons_sample_freq(x) = x[4] >= 1
AddExtremeConstraint(p, cons_sample_freq)
# cons_sample_freq2(x) = x[4] < size(all_data,1)
# AddExtremeConstraint(p, cons_sample_freq2)

#constraints on ahead_predictions
cons_ahead_preds(x) = x[5] >= 1
AddExtremeConstraint(p, cons_ahead_preds)
cons_ahead_preds2(x) = x[5] < x[1]
AddExtremeConstraint(p, cons_ahead_preds2)

Optimize!(p)