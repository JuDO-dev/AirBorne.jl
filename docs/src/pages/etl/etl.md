# ETL Pipeline.
> ETL, standing for Extract, Transform and Load, is the process of combining data from multiple sources into a large central repository of data.
> [What is ETL? (AWS)](https://aws.amazon.com/what-is/etl/)

This package should have an ETL capability to retrieve and store financial data 

#### 1. Extract
Data can extracted from:

1. APIs of data providers such as Quandl or Yahoo
1. APIs of brokers such as Alpaca
1. Local files such as CSVs or JSON with a predetermined format

#### 2. Transform
Once the data is extracted it locally is formatted and cleaned to standarize the format and schema they should comply with.

#### 3. Load
Lastly the data is served into a variable accesible for the package and persisted in an efficient file format.

## Supported schemas and file structure

### OHLCV




## File structures on other platforms
Many trading platforms have their own schemas for data

##### Zorro's 
The [zorro project](https://zorro-project.com/manual/en/data.htm) have what they call the T file formats, where a tx file a timestamp "t" and x elements. These files are CSV or JSON files stored in 

###### Headers:
- **Start** - token name or start string of the whole price structure. Determines from where to parse.
- **Timeformat** - format of the date/time field with DATE format codes, as in the CSV format string.
- **Time** - token name of the date/time field.
- **High,Low,Open,Close** - token names of the price fields.
- **AdjClose** - token name of the adjusted close field, or empty if the file contains no such field.
- **Volume** - toke name of the volume field, or empty if the file contains no volume data.
- **Ask** - token name of the best ask quote field.
- **AskSize** - token name of the ask size field.
- **Bid** - token name of the best bid quote field, or empty if the file contains no bid quotes.
- **BidSize** - token name of the bid size field, or empty.

###### File Format:
```c
typedef struct T1
{
  DATE  time; // UTC timestamp of the tick in DATE format
  float fPrice; // price data, positive for ask and negative for bid
} T1;
 
typedef struct T2
{
  DATE time;  // UTC timestamp in DATE format
  float fPrice; // price, negative for bid quotes
  float fVol; // trade volume or ask/bid size
} T2; 
 
typedef struct T6
{
  DATE  time; // UTC timestamp of the close, DATE format
  float fHigh,fLow;	
  float fOpen,fClose;	
  float fVal,fVol; // additional data, ask-bid spread, volume etc.
} T6;
 
typedef struct CONTRACT
{
  DATE  time;   // UTC timestamp in DATE format
  float fAsk,fBid; // premium without multiplier
  float fVal,fVol;  // additional data, like delta, open interest, etc.
  float fUnl;   // underlying price (unadjusted)
  float fStrike; // strike price
  long  Expiry; // YYYYMMDD format
  long  Type;   // PUT, CALL, FUTURE, EUROPEAN, BINARY
} CONTRACT;
```

##### Zipline  
Zipline uses what they call OHLCV format, standing for Open, High, Low, Close, Volume. Is a common format to convey daily trade information about a ticker, in addition to the columns in the name actually more columns need to be provided.

###### File Format:
Zipline actually stores data in a file system. Given a persistency (or cache) directory. It stores the data in bundles stored the following structure `$CACHE_PATH/{source_id}/{bundle_id}/` the bundle is then formed in [**bcolz**](https://bcolz.readthedocs.io/en/latest/intro.html) format
1. **Zipline OHLCV**: Date, Open, High, Low, Close, Volume, Dividend, Split




