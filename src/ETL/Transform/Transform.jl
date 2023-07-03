"""
    Transform is the module were standard transformation between data structure takes place.

    Particular datasources should adhere to data structures defined in this module. In particular
    strategies and markets may make use of data structures in this module in order to promote cross-compatibility 
    between different strategies, markets and engines.
    
"""
module Transform
export getSchema, addSchema

using Tables: Schema
using Dates: Dates
using Bijections: Bijection, inv

OHLCV_V1_specs = [
    :close; Float64;;
    :high; Float64;;
    :low; Float64;;
    :open; Float64;;
    :volume; Int64;;
    :date; Dates.DateTime;;
    :unix; Int64;;
    :exchangeName; String;;
    :timezone; String;;
    :currency; String;;
    :symbol; String
]

# Better implementation can be achieved by using Schemata.jl (left for ETL V2)
schemas = Bijection{String,Schema}()
getSchema(s::Schema) = get(inv(schemas), s, "UNREGISTERED_SCHEMA")
getSchema(s::String) = get(schemas, s, nothing)

function addSchema(name::String, schema::Schema)
    return schemas[name] = schema
end

addSchema("OHLCV_V1", Schema(OHLCV_V1_specs[1, :], OHLCV_V1_specs[2, :]))

end
