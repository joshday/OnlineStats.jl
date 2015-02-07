# OnlineStats

The main thing this package adds is the `OnlineStats` type which keeps track of the current estimate and the number of observations used.

The driving function will be `update!()`.  I still have to work out a type system so that `update!` can have different methods for different models/statistics.
