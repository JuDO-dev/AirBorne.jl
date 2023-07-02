
#     FM - Financial Models
#     This file contains many functions and Types that can be used to model things like 
#     - Currencies
#     - Money (a numeric data type with an associated currency)
#     - Wallet (a collection with money elements or elements that can be associated to money types)

using Printf: @sprintf
using Base: Base
using Currencies: Currency

################
###  Money   ###
################
"""Just a float with an associated Symbol"""
struct Money{S}
    value::Float64
end
# Constructors
Base.:*(a::Float64, ::Type{Currency{S}}) where {S} = Money{S}(a) # allow 3.0USD as a valid expression
Base.:*(a::Real, ::Type{Currency{S}}) where {S} = Money{S}(Float64(a)) # allow 3USD as a valid expression

get_symbol(::Type{Money{S}}) where {S} = S # Symbol from Type
get_symbol(::Money{S}) where {S} = S # Symbol from Instance 

# COV_EXCL_START
function Base.show(io::IO, ::MIME"text/plain", v::Money{S}) where {S}
    return print(io, @sprintf("%.2f", v.value), "$S")
end
Base.show(io::IO, v::Money{S}) where {S} = show(io, MIME("text/plain"), v)
# COV_EXCL_STOP

sameCurrency(::Money{S}, ::Money{D}) where {S,D} = S == D

# Arithmetic operations
Base.:+(a::Money{A}, b::Money{A}) where {A} = Money{A}(a.value + b.value) # Same 
Base.:*(::Type{Currency{S}}, a::Float64) where {S} = Money{S}(a) # allow USD*3.0 as a valid expression
Base.:*(::Type{Currency{S}}, a::Real) where {S} = Money{S}(Float64(a)) # allow USD*3 as a valid expression
Base.:*(a::Real, b::Money{B}) where {B} = Money{B}(a * b.value) # allow to multiply money by a value
Base.:*(b::Money{B}, a::Real) where {B} = Money{B}(a * b.value) # Commutability of product

exchange(a::Money{A}, B::Symbol, rate::Real) where {A} = Money{B}(a.value * rate)
function exchange(
    a::Money{A}, B::Symbol, exchangeRate::Dict{Tuple{Symbol,Symbol},Real}
) where {A}
    if haskey(exchangeRate, (A, B))
        return Money{B}(a.value * exchangeRate[(A, B)])
    elseif haskey(exchangeRate, (B, A))
        return Money{B}(a.value / exchangeRate[(B, A)])
    elseif B == A
        return a
    else
        throw(KeyError("($A,$B) or ($B,$A)"))
    end
end

#################
###  Wallet   ###
#################

"""Just a wrapper around a dictionary"""
struct Wallet
    content::Dict{Symbol,Float64}
end
# Constructors
Wallet(::Type{Currency{S}}) where {S} = Wallet(Dict(S => 0.0))
Wallet(S::Symbol) = Wallet(Dict(S => 0.0))
Wallet(b::Money{B}) where {B} = Wallet(Dict(B => b.value))
# Base Operators/Functions
Base.setindex!(w::Wallet, a::Float64, S::Symbol) = Base.setindex!(w.content, a, S)
function Base.getindex(w::Wallet, S::Symbol)
    return haskey(w.content, S) ? Base.getindex(w.content, S) : 0.0
end
Base.length(a::Wallet) = length(a.content)
Base.haskey(a::Wallet, key) = haskey(a.content, key)
Base.keys(a::Wallet) = keys(a.content)

# COV_EXCL_START
function Base.show(io::IO, ::MIME"text/plain", w::Wallet)
    println(io, "Wallet object containing:")
    for (key, value) in w.content
        println(io, "  ", @sprintf("%.2f", value), "$(key)")
    end
end
Base.show(io::IO, w::Wallet) = show(io, MIME("text/plain"), w)
# COV_EXCL_STOP

####################################
###  Wallet and Money Functions  ###
####################################

function Base.:+(a::Wallet, b::Wallet)
    bigW, smallW = length(a) > length(b) ? (a, b) : (b, a)
    out = deepcopy(bigW) # We don't want to modify original
    for (key, value) in smallW.content
        if haskey(out, key)
            out[key] += value
        else
            out[key] = value
        end
    end
    return out
end

"""Test if Wallets are identical. Potentially can be redefined as === 
and leave == if different keys are set to 0"""
function Base.:(==)(a::Wallet, b::Wallet)
    if length(a) != length(b) || keys(a) != keys(b)
        return false
    end
    for (key, value) in a.content
        if value != b[key]
            return false
        end
    end
    return true
end
Base.:+(a::Money{A}, b::Money{B}) where {A,B} = Wallet(Dict(A => a.value, B => b.value)) #Different
Base.:+(a::Wallet, b::Money) = a + Wallet(b) # Add money to the wallet just by summing
Base.:+(b::Money, a::Wallet) = a + Wallet(b) # Commutability of operator
