using LinearAlgebra
using Statistics
using Plots
using Random
using JuMP
using DelimitedFiles
using SCS
using Convex

import MathOptInterface

function initial(A, B, C, D, x ,u, Td)
    y_vals = zeros(0)
    
    x_tmp = x

    for i = 1:Td
        x_1 = A*x_tmp + B*u
        y   = C*x_tmp + D*u
        append!(y_vals, y)
        x_tmp = x_1
    end 
    y_vals
end 

function find_w_given(traj, times)
    w_given = zeros(0)
    for i= 1:size(times, 1)
        append!(w_given, traj[times[i]])
    end
    w_given
end

function hankel(traj, L)
    hank = Array{Float64}(undef, L, (size(traj,1)-L+1))
    for i=1:(size(traj,1)-L+1)
        for j=1:L
            hank[j,i] = traj[j+i-1]
        end
    end
    hank
end

function Lasso(Y,X,γ,λ=0.0) #taken from https://jump.dev/Convex.jl/stable/examples/general_examples/lasso_regression/
    K = size(X,2)

    b_ls = X\Y                    #LS estimate of weights, no restrictions

    Q  = X'X
    c  = X'Y                      #c'b = Y'X*b

    b  = Variable(K)              #define variables to optimize over
    L1 = quadform(b,Q)            #b'Q*b
    L2 = dot(c,b)                 #c'b
    L3 = norm(b,1)                #sum(|b|)
    L4 = sumsquares(b)            #sum(b^2)

    Sol = minimize(L1-2*L2+γ*L3+λ*L4)      #u'u + γ*sum(|b|) + λsum(b^2), where u = Y-Xb
    solve!(Sol,()->SCS.Optimizer(verbose = false))
    Sol.status == MOI.OPTIMAL ? b_i = vec(evaluate(b)) : b_i = NaN

    return b_i, b_ls
end

Opt_folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Behavioural\\Testing"

# set up some linear system with matrices ABCD
n = 6

A = [    1.008          1          0          0          0          0;
     -4.43e-05      1.008          1          0          0          0;
             0          0     0.5015          1          0          0;
             0          0    -0.7707     0.5015          1          0;
             0          0          0          0     0.8786          1;
             0          0          0          0    -0.2539     0.8786 ]

B = [0;0;0;0;0;1]
C = [1 0 0 0 0 0]
D = [0]

x = rand(n, 1)

# define some trajectories

T = 30; ng = 10
x0 = [100; 10; -7; -1; .5; -1.5]
w = initial(A,B,C,D, x0, 0, T)          # 30 unit long trajectory

# uncomment below to test for different values of t_given

t_given = rand(1:T, ng)           # select some 10 random time values of it 
# t_given = 1:n;                      # simulation 

wd = initial(A,B,C,D,x,0,100)       # some known trajecotry of the system, sufficiently long
w_given = find_w_given(w, t_given)  # find the point values from the 10 randomly selected points

# goal is to reconstruct the 30 unit long tajectory from these 10 randomly selected points and the given trajectory

hankel_test = hankel(wd, T)         # construct hankel matrix
g = hankel_test[t_given, :]\w_given # simple solving of selection vector g

#hankel_test[t_given,:] selects those rows in the hankel matrix, hankel_test corresponging to those specified in t_given

wh = hankel_test*g #reconstructed tajectory

vals1, vals2 = Lasso(w_given, hankel_test[t_given, :], 1.0) #reconstruction of trajectory using Optimisation technique

w_opt = hankel_test*vals2

Plots.plot(t_given, w_given, seriestype = :scatter, label = "Given points, w_given")
Plots.plot!(w ,seriestype = :scatter, markershape = :x, label = "Trajectory to be reconstructed, w")
Plots.plot!(wh ,seriestype = :scatter, markershape = :+, label = "Solving via unconstained least squares, wh")
Plots.plot!(w_opt,ylims = (90,200), xlims = (0,T+1), seriestype = :sticks , label = "Solving L1 norm, w_opt")
Plots.display(Plots.plot!(title = "LTI", xlabel = "Time", ylabel = "Y"))
savefig(string(Opt_folder,"_Opt_Data_1"))

