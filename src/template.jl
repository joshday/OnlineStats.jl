# Author(s): name <email address>

# Each source file should contain
#  * Type definition
#    - Default Constructor(s)
#  * update!()
#  * state()
#  * convert(DataFrame, obj)

# Docile and Markdown are used for generating documentation

#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# NewType
type NewType
  some_statistic::Array  # Vector or Matrix
  sufficient_stats
  n::Vector{Int64}
  nb::Vector{Int64}
end

# default constructor(s)


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::NewType, newdata::Vector, add::false)
  # code to update obj
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::NewType)

end


#-----------------------------------------------------------------------------#
#----------------------------------------------------------------# Base.convert
function Base.convert(::Type{DataFrames.DataFrame}, obj::Summary)
  df = DataFrames.DataFrame()
  df[:some_statistic] = some_statistic
  df[:n] = obj.n
  df[:nb] = obj.nb
  return df
end
