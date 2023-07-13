
"""
    This modules provides an interface between AirBorne and NASDAQ API. 
"""
module NASDAQ
using HTTP: HTTP
using JSON: JSON
using DataFrames: DataFrame

"""
    screener()

    Returns the data from  [NASDAQ's screner page](https://www.nasdaq.com/market-activity/stocks/screener).

    It provides a simple way also of getting a relatively large amount of US tickers.
"""
function screener()
    url = "https://api.nasdaq.com/api/screener/stocks?tableonly=true&offset=0&download=true"
    r = HTTP.request("GET", url)
    body = deepcopy(r.body)
    resp_json = JSON.parse(String(body))
    out = DataFrame(resp_json["data"]["rows"])
    return out
end

end
