# Technical glossary
This page describes the modelling behind different financial structures and data types.
In this section we will describe the entities present in the package, used during backtesting. Some are related to simulation frameworks, data structures or object oriented archiqutecture whilst other entities reflect a model of choice for financial objects found in the real world. It is important to point out that **Julia is not an object-oriented programming language**, therefore we avoid at all cost of refering to any of our data structures or modules as such.

Where possible we try to align the technical definitions with the ones of the [Financial Glossary](@ref financial_glossary).

## Data Pipeline

### ETL
> ETL, standing for Extract, Transform and Load, is the process of combining data from multiple sources into a large central repository of data.
> [What is ETL? (AWS)](https://aws.amazon.com/what-is/etl/)

## Backtesting
This section provides a quick definition of the entities modelled in AirBorne regarding backtesting. For a deep dive see [Backtesting and Event Driven Simulation](@ref backtesting).

### Engines
An engine is the orchastrator of a simulation, it dictates the sequence of actions carried out during the simulation. At the moment only one simulation engine is present in AirBorne, the **Discrete Event Driven Simulation** or DEDS for short. An engine dictates how markets, brokers and investors interact with each other during a simulation, what processes gets executed first and which later.
 
### Market
Markets are a conceptual group usually represented in a submodule that executes trading orders placed by trading strategies. Two functions are what define a market

1. **execute_order!**: This function takes an order placed by a strategy and modifies the portfolio and ledger accordingly, reflecting the order execution. The nature of the pricing and characteristc of the transaction is left for each market to specify. For example a market model may take a probablistic or stochastic process approach for valuation and may treat the price and volume as probability distributions whilst another market may just model the price as a fixed value given a dataset. Some markets may introduce a delay between the order time and executions and some other may not.
1. **expose_data**: Since there is some diversity on the formats of data available and the way the data is transferred the expose_data method is the one responsible to send data to the strategy when requested, this can be by slicing or transforming a large dataset and provide the strategy just with the data that it would see if it was trading in a real environment, the purpose of a market having the flexibility of exposing data in different formats is to allow a realistic data pipeline handling for the strategy. I.e., some markets may do a an SFTP drop into a server, some markets may send an email with summary data, and some markets may just simply write/respond an REST API call.

### Strategies
A strategy is a combination of an **initialization routine** were data structures and parameter relevant for the trading logic are initialized and  a **trading logic** routine were given new data a decision to place orders in a market may be applied. 

Strategies may also decide when to check for data again (in the form of an schedule or iteratively setting next check dates) or not. Market may provide particular mechanisms to place orders and and may have limited support for different types of orders, strategies should have this nuances in mind when designed such that they can place orders succesfully.

## Money, Currency and Wallets

### Money
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

### Wallets
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

## DataFrames Structures

### OHLCV V1 DataFrame
This is a standard format for the storage of equity asset information, the schema of this format of data is defined in **AirBorne.ETL.Transform**.

```julia
OHLCV_V1_specs = [
    :close; Float64;; # Tipical OHLCV candles
    :high; Float64;;
    :low; Float64;;
    :open; Float64;;
    :volume; Int64;; 
    :date; Dates.DateTime;; # DateTime Timestamp
    :unix; Int64;; # Unix timestamp
    :exchangeName; String;; # Name of the exchange trading the security
    :timezone; String;; # Timezone of the exchange
    :currency; String;; # Currency used to trade an asset in the exchange
    :symbol; String;; # Symbol of the asset in the exchange
    :assetId; String # Combination of the asset and the exchange that uniquely specifies the asset to be traded and the environment.
]
```

### Asset Value DataFrame
This dataframe contains one column per ticker/asset and one row per timestamp.
The value of each column corresponds to the value of the asset at the specified point in time of the row.

Additionally the dataframe contains an additional column `stockValue` that summarizes the values of all the assets in a dictionary with keys the ticker symbols and values the value of the unit of asset.

### Asset Return DataFrame
Similar to the **Asset Value DataFrame** this dataframe contains one column per ticker/asset and one row per timestamp. The value of each column corresponds to the return of the asset at the specified point in time of the row. This is usually defined with respect to the previous timestamp. The first return value is by default set to 0.

Additionally the dataframe contains an additional column `stockReturn` that summarizes the returns of all the assets in a dictionary with keys the ticker symbols and values the return of the unit of asset.