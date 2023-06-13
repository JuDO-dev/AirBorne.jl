module Structures
using Dates: DateTime
export TimeEvent

struct TimeEvent
    date::DateTime
    type::String
end

function lenght(::TimeEvent)
    return 1
end
end
