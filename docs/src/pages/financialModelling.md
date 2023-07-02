# Financial Modelling 
This page describes the modelling behind different financial structures and data types.

### Money, Currency and Wallets

###### Money
AirBorne provides a self-contained representation of money. Money is represented as a number with an associated *Symbol* parameter type that acts as the currency. Money with the same currency can be added together and Money can be multiplied by any real number. However Money cannot be multiplied by Money.

AirBorne is fully compatible with the module [Currencies](https://github.com/JuliaFinance/Currencies.jl/). But it can also support currencies outside ISO 4217, because the implementation of a currency is just through a Symbol representation.

```julia 
    using AirBorne: Money
    using Currencies: Currencies
    USD = Currencies.currency(:USD)
    GBP = Currencies.currency(:GBP)
    UYU = Currencies.currency(:UYU)
    a = 10USD
    b = 10.0USD
    c1 = Money{:GBP}(5.0)
    c2 = Money{:GBP}(5)
    # All the expression below are equivalent and should return true.
    println(2.0 * a == (b + b))
    println(2.0 * a == b * 2)
    println(2 * a == b * 2.0)
    println(USD * 2 == USD * 2.0)
```

###### Wallets
A Wallet is a collection of different types of Money. At its core is a dictionary with extra features for algebraic operations as one can add Money to a Wallet just by using the "+" operator, and wallets can be added together using the "+" operator as well. Moreover if a particular currency is not present in a wallet if you try to retrieve the amount of such currency from the wallet the answer will be 0 (instead of a KeyError response).

```julia 
    using AirBorne: Money, Wallet
    using Currencies: Currencies
    USD = Currencies.currency(:USD)
    GBP = Currencies.currency(:GBP)
    UYU = Currencies.currency(:UYU)
    
    # Different ways to instantiate a wallet
    w0 = Wallet(USD) 
    w1 = Wallet(:USD)
    w2 = Wallet(20USD)
    w3 = Wallet(50UYU)
    w4 = Wallet(Dict(:USD => 20, :UYU => 50))
    w5 = deepcopy(w3)
    w5[:USD] = 10.0 # Define up the amount of USD in Wallet

    # Arithmetic operations between wallets and money
    w2 + 50UYU == w4 # Add money to wallet
    20USD + w3 == w4 # Commutative property of addition
    w2 + w3 == w4 # Combine wallets
    20USD + 50UYU == w4 # Generate a wallet by adding different types of Money
    

    # Operations with keys
    haskey(w5, :USD) # Check if wallet has currency defined
    collect(keys(w5)) == [:UYU, :USD] # Get currencies in Wallet
```