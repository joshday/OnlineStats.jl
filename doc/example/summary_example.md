
# Summary


```{julia;term=true;fig_width=5}
using Gadfly
x = linspace(0, 2π, 200)
plot(x=x, y = sin(x), Geom.line)
y = 20
plot(x=x, y = cos(x), Geom.line)
```


```julia
x = linspace(0, 200)
println(x)
```


~~~{julia;term=true;fig_width=5}
using Gadfly
x = linspace(0, 2π, 200)
plot(x=x, y = sin(x), Geom.line)
y = 20
plot(x=x, y = cos(x), Geom.line)
~~~

~~~julia
x = linspace(0, 200)
println(x)
~~~