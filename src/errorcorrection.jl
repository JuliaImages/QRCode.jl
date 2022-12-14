module Polynomial

export Poly, geterrorcorrection

"""
Data structure to encode polynomials to generate the error correction codewords.
"""
struct Poly
    coeff::Vector{Int}
end

"""
    makelogtable()

Retrun a list of logarithm values for the Galois Field GF(256).
"""
function makelogtable()
    t = ones(Int, 256)
    v = 1
    for i in 2:256
        v = 2 * v
        if v > 255
            v = xor(v, 285) # According to the specs
        end
        t[i] = v
    end
    return t
end

"""
Logarithm table for GF(256).
"""
const logtable = Dict{Int, Int}(zip(0:255, makelogtable()))

"""
Anti-logarithm table for GF(256).
"""
const antilogtable = Dict{Int, Int}(zip(makelogtable(), 0:254))

"""
    function mult(a::Int, b::Int)

Multiplies two integers in GF(256).
"""
function mult(a::Int, b::Int)::Int
    if a == 0 || b == 0
        return 0
    end
    xa = antilogtable[a]
    xb = antilogtable[b]
    return logtable[(xa + xb) % 255]
end

import Base: length, iterate, ==, <<, +, *

"""
    length(p::Poly)

Return the degree of the polynomial.
"""
length(p::Poly) = length(p.coeff)

iterate(p::Poly) = iterate(p.coeff)
iterate(p::Poly, i) = iterate(p.coeff, i)

==(a::Poly, b::Poly)::Bool = a.coeff == b.coeff

"""
    <<(p::Poly, n::Int)

Increase the degree of `p` by `n`.
"""
<<(p::Poly, n::Int)::Poly = Poly(vcat(zeros(n), p.coeff))

+(p::Poly) = p

function +(a::Poly, b::Poly)::Poly
    l = max(length(a), length(b))
    return Poly([xor(get(a.coeff, i, 0), get(b.coeff, i, 0)) for i in 1:l])
end

*(a::Int, p::Poly)::Poly = Poly(map(x->mult(a, x), p.coeff))

function *(a::Poly, b::Poly)::Poly
    return sum([ c * (a << (p - 1)) for (p, c) in enumerate(b.coeff)])
end

"""
    generator(n::Int)

Create the Generator Polynomial of degree `n`.
"""
function generator(n::Int)::Poly
    prod([Poly([logtable[i - 1], 1]) for i in 1:n])
end

"""
    lead(p::Poly)

Return the leading coefficient of `p`.
"""
lead(p::Poly) = last(p.coeff)

"""
    init!(p::Poly)

Delete the leading coefficient of `p`.
"""
init!(p::Poly)::Poly = Poly(deleteat!(p.coeff, length(p)))

"""
    tail!(p::Poly)

Decrease the degree of `p` by one.
"""
tail!(p::Poly)::Poly = Poly(deleteat!(p.coeff, 1))

"""
    geterrorcorrection(a::Poly, n::Int)

Return a polynomial containing the `n` error correction codewords of `a`.
"""
function geterrorcorrection(a::Poly, n::Int)::Poly
    la = length(a)
    a = a << n
    g = generator(n) << la

    for _ in 1:la
        tail!(g)
        a = init!(lead(a) * g + a)
    end
    return a
end

end # module
