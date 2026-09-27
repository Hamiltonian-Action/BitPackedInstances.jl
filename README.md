
# BitPackedInstances.jl

[![Build Status](https://github.com/QuantumSavory/BitPackedInstances.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/QuantumSavory/BitPackedInstances.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/QuantumSavory/BitPackedInstances.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/QuantumSavory/BitPackedInstances.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

BitPackedInstances is lightweight package that facilitates the bit packing of any data types that support the `instances` querying interface via compact and efficient `@generated` implementations. The provided experience largely resembles that of a typical dictionary to the extent permissible by the prolific abuse of the `Julia` type system that is required in order to achieve the desired functionality.


# WARNINGS

- This package was developed with the primary objective of reducing the register pressure required to handle `@enum` parameters controlling tunable functionality. As such, the intended use case favours encoding statically known types rather than being a general purpose data structure.

- Due to thoroughly employing a large swathe of `@generated` function invocations, world age restrictions are of particular importance. To wit, any content which one wishes to encode must be completely defined before `BitPackedInstances.jl` is imported into the parent scope.

# Performance considerations

This section concerns data types that can be freely iterchanged to and form an integer representation.

- Optimal encoding and retrieval is realised when querying the instances returns (upon transforming to a common integer type, reinterpreting as an unsigned value, and subtracting the first entry) an iterable constituting an increasingly ordered arithmetic progression.

- Whilst there are other progressions that could be handled just as efficiently, this project shall make no effort to account for all of them given that this is the default `@enum` behaviour. Concerned individuals and/or projects are encouraged to employ suitable translation layers as they see fit.

# Exemplary usage

```julia
# MUST precede importing `BitPackedInstances`.
@enum Season begin winter; spring; summer; autumn; end
@enum Weather begin snowy; windy; sunny; rainy; end
@enum Mood begin pessimistic; optimistic; end

using BitPackedInstances

# Construct by passing an unsigned type and any number of values.
bit_pack = MutablePackedInstances(UInt64, sunny)
# Preferred content matching style.
@assert match_content(bit_pack, sunny)
# Regular retrieval is also possible in two distinct styles.
@assert bit_pack.Weather == bit_pack[Weather]
# Alter the underlying type.
bit_pack = AbstractPackedInstances(UInt8, bit_pack)
@assert encoding_type(bit_pack) == UInt8
# Overwrite existing content.
bit_pack.Weather = rainy
@assert match_content(bit_pack, rainy)
bit_pack[Weather] = snowy
@assert match_content(bit_pack, snowy)
# Preferred modification style.
overwrite!(bit_pack, windy)
@assert match_content(bit_pack, windy)
# Extend with new content.
bit_pack = AbstractPackedInstances(bit_pack, summer)
@assert match_content(bit_pack, summer)
# Both at once if so desired.
bit_pack = AbstractPackedInstances(bit_pack, sunny, optimistic)
@assert match_content(bit_pack, summer, sunny, optimistic)
# Eliminate what is no longer needed.
bit_pack = discard(bit_pack, Mood)
@assert !haskey(bit_pack, Mood)
# Convert to/from mutable and immutable forms if so desired.
bit_pack = ImmutablePackedInstances(bit_pack)
@assert !ismutable(bit_pack)
bit_pack = MutablePackedInstances(bit_pack)
@assert ismutable(bit_pack)

# World age restrictions forbid certain possibilities.
@enum Catastrophy begin impossible; end
# Failure awaits whoever attempts.
try
	ImmutablePackedInstances(UInt64, impossible)
	@assert false
catch error
	@assert error isa MethodError
end
```
