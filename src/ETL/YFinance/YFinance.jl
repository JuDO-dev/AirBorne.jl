import HTTP

"""
    This modules provides an interface between AirBorne and Yahoo Finance API. 
"""
module YFinance

export rate_limits
export hello_yfinance

import Logging

rate_limits=""""""

"""
    hello_yfinance()

Returns a string saying "Hello YFinance!".
"""
function hello_yfinance()
    return "Hello YFinance!"
end

urlencode(x) = HTTP.URIs.escapeuri(x)

function get_chart_data(ticker, period1, period2, freq)
end

function get_interday_data()

end
end