# #-----------------------------------------------------------------------------# XPixel 
# """
# A pixel split into four values.  Adjacent pixels can be joined in multiple ways to create 
# different shapes.

# ```
# (x, y + h)                       (x + w, y + h)
#             █████████████████
#             █ █           █ █
#             █   █   T   █   █
#             █     █   █     █
#             █  L    █    R  █
#             █     █   █     █
#             █   █   B   █   █
#             █ █           █ █
#             █████████████████
# (x, y)                           (x + w, y)
# ```
# """
# mutable struct XPixel{T, S}
#     x::S 
#     y::S
#     h::S 
#     w::S

#     top::T
#     right::T 
#     bottom::T 
#     left::T
# end
# Base.sum(x::XPixel) = x.top + x.right + x.bottom + x.left

# #-----------------------------------------------------------------------------# HexGrid
# struct HexGrid{EX, EY}
#     xedges::EX 
#     yedges::EY
#     counts::Matrix{XPixel}
#     out::Int 
# end