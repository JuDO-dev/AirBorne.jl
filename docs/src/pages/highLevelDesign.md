
# High Level Design
In this section definition for the main objects in this package are presented as well as an introduction to the main logic behind the structure of the package.

## ETL Pipeline
> ETL, standing for Extract, Transform and Load, is the process of combining data from multiple sources into a large central repository of data.
> [What is ETL? (AWS)](https://aws.amazon.com/what-is/etl/)

This package needs to have an ETL capability to retrieve and store financial data, for reproducibility and post-analytics purposes.


## Objects
In this section we will describe the objects present in the package, some are related to physical and financial entities found in the real world. To ensure our definitions well aligned with the financial we leverage most of the definitions from well established financial entities and/or acadamic sources. In particular [**IG International Limited: Glossary of Trading Terms**](https://www.ig.com/en/glossary-trading-terms) is substantially used to support our definitions.

### Financial Entitities:

#### Investor

#### Broker
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/broker-definition):
> A broker is an independent person or a company that organises and executes financial transactions on behalf of another party. They can do this across a number of different asset classes, including stocks, forex, real estate and insurance. A broker will normally charge a commission for the order to be executed.
>Some brokers will provide you with market data and give you advice on the products you want to buy or sell – depending on whether they are a full service broker, or execution only. However, a broker must be licensed to give advice and execute the sale, and they will only perform trades on your behalf once you have given them the go-ahead.
#### Market
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/market-definition):
>A financial market is defined as a medium through which assets are traded, enabling buyers and sellers to interact and facilitate exchanges. However, the term can be used in a variety of different ways – it can refer physical places, virtual exchanges or groups of people that are interested in making transactions.

### Financial constructs and instruments

#### Currency
> [**Investopedia definition**](https://www.investopedia.com/terms/c/currency.asp) 
> Currency is a medium of exchange for goods and services. In short, it's money, in the form of paper and coins, usually issued by a government and generally accepted at its face value as a method of payment.

#### Asset
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/assets-definition):
>An asset is an economic resource which can be owned or controlled to return a profit, or a future benefit. In financial trading, the term asset relates to what is being exchanged on markets, such as stocks, bonds, currencies or commodities.

##### Spread
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/spread-definition):
> In finance, the spread is the difference in price between the buy (bid) and sell (offer) prices quoted for an asset.

#### Position
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/position-definition):
> A position is the expression of a market commitment, or exposure, held by a trader. It is the financial term for a trade that is either currently able to incur a profit or a loss – known as an open position – or a trade that has recently been cancelled, known as a closed position. Profit or loss on a position can only be realised once it has been closed.

#### Option
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/option-definition):
> An option is a financial instrument that offers you the right – but not the obligation – to buy or sell an asset when its price moves beyond a certain price with a set time period.

#### Portfolio
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/portfolio-definition):
> A portfolio refers to group of assets that are held by a trader or trading company. Assets in a portfolio can come in many forms, including stocks, bonds, commodities or derivatives.

### Technical Objects



## Simulations and Backtesting
In this section we will describe different calculations and methods used for the backtesting or simulation of a strategy.

### Portfolio calculations / Financial reports

#### Returns
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/rate-of-return-definition): 
> Rate of return (ROR) is the loss or gain of an investment over a certain period, expressed as a percentage of the initial cost of the investment. A positive ROR means the position has made a profit, while a negative ROR means a loss. You will have a rate of return on any investment you make.
#### PnL: Profit and Losses
>[**Definition from IG International Limited**](https://www.ig.com/en/glossary-trading-terms/profit-and-loss-definition): 
> A profit and loss (P&L) statement is a financial report that provides a summary of a company’s revenue, expenses and profit. It gives investors and other interested parties an insight into how a company is operating and whether it has the ability to generate a profit.
