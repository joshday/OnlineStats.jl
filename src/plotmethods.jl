import Plots


function Plots.plot(o::OnlineStat; kw...)
    Plots.plot([nobs(o)], vcat(state(o)[1])', kw...)
end
