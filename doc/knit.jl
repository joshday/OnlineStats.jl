module MakeDocs
reload("KnitDocs")
using KnitDocs, OnlineStats

knit(OnlineStats)

end
