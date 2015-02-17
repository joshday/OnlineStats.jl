# Author(s): name <email address>

# Each source file should contain
#  * Type definition
#    - Default Constructor(s)
#  * update!()
#  * state()



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# NewType
type NewType
    some_statistic
    sufficient_stats
    n::Int64
    nb::Int64
end

# default constructor(s)


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::NewType, newdata)
    # code to update obj
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::NewType)

end


