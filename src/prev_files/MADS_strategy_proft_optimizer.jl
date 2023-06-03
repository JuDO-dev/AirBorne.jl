"""This file is a script to optimize the profit of a chosen strategy"""

using DirectSearch
include("Basic_strategy_profit.jl")
include("Data.jl")

ticker_symbol = "PYPL"
start_date = "2002-01-01"
end_date = "2022-01-01"
all_data = get_data(ticker_symbol, start_date, end_date, "", "1wk")
all_data = all_data[:, 6]
all_data = all_data[.~(isnan.(all_data))]

system_dimension = 1 #How many signals are added to the Hankel matrix

#L_max = floor((size(all_data,1)+1)/(system_dimension+1)) #This is the maximum possible depth according to the BC theory. Added as a constraint
p = DSProblem(7; objective=MADS_basic_strategy_profit, initial_point=[20, 0.01, 5, 1, 1, 0.003, 1])
SetIterationLimit(p, 5)
# i = 1 #Index of variabels that are granular
# SetGranularity(p, i, 1.0)
gamma_granularity = 0.01
theshhold_granularity = 0.0001
SetGranularity(p, Dict( 1 => 1, 2 => gamma_granularity, 3 => 1, 4 => 1, 5 => 1, 6 => theshhold_granularity, 7 => 1))
#cons(x) = [-x[1] -x[2]] #Constraints x[1] to be greater than or equal to 0

#Constraints on Length (depth) of the Hankel matrix
consL(x) = x[1] > 1
AddExtremeConstraint(p, consL)

consL2(x) = x[1] < floor((size(all_data,1)+1-x[3])/(system_dimension+1))
AddExtremeConstraint(p, consL2)

#Constraints on gamma
consgamma(x) = x[2] > 0
AddExtremeConstraint(p, consgamma)

#constraints on data size
consdata_size(x) = x[3] >= 0 
AddExtremeConstraint(p, consdata_size)
consdata_size2(x) = x[3] <= floor(size(all_data,1)*3/4) 
AddExtremeConstraint(p, consdata_size2)

#constrains on sample sample_frequency
cons_sample_freq(x) = x[4] == 1
AddExtremeConstraint(p, cons_sample_freq)
# cons_sample_freq2(x) = x[4] < size(all_data,1)
# AddExtremeConstraint(p, cons_sample_freq2)

#constraints on ahead_predictions
cons_ahead_preds(x) = x[5] >= 1
AddExtremeConstraint(p, cons_ahead_preds)
cons_ahead_preds2(x) = x[5] < x[1]
AddExtremeConstraint(p, cons_ahead_preds2)

#constraints on threshhold
cons_threshhold(x) = x[6] >= 0
AddExtremeConstraint(p, cons_threshhold)

#constraints on decision taking interval
cons_decision_interval(x) = x[7] == 1
AddExtremeConstraint(p, cons_decision_interval)
# cons_decision_interval2(x) = x[7] < x[4]
# AddExtremeConstraint(p, cons_decision_interval2)

Optimize!(p)