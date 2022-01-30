# TypedEnum

A simple library to ease using enum-like fields in Ecto.Schemas.


## Installation

Add `typed_enum` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:typed_enum, "~> 0.1"}
  ]
end
```

Docs: [https://hexdocs.pm/typed_enum](https://hexdocs.pm/typed_enum).

<div align="center">
     <a href="#installation">Installation</a><span>&nbsp; |</span>
     <a href="#why">Why</a><span>&nbsp; |</span>
     <a href="#usage">Usage</a><span>&nbsp; |</span>
     <a href="#about">About</a><span>&nbsp; |</span>
     <a href="#copyright">Copyright</a>
</div>

### Why ?

Although Ecto ships (since 3.5) with an Enum type that allows you to easily limit the possible values a field can have while providing casting between `"strings"` to their `:atoms` representations there are still some issues that you might run into:

- If you need to share the type between schemas then you need to duplicate or keep the the declarations in multiple schemas somehow in synch
- You can't define enums with integers as their database layer representation
- It doesn't create a proper `@type` for use in specs
- The field "type" is declared in the `schema` itself, which in practical terms isn't a problem, but conceptually the type of a field should be independent from the schema that uses it
- You can't cast individual parameters outside of schema changeset.

### Usage

After adding `typed_enum` as a dependency, declare a module for your type using the `TypedEnum` `use` macro for defining your enum:

```elixir
defmodule ExampleTypeString do
  use TypedEnum, values: [:val_1, :val_2]
end
```

This defines an `Ecto.Type` `ExampleTypeString` that can assume two values, `:val_1` or `:val_2` and is stored in the database as a string. You can cast values independently with `ExampleTypeString.cast("val_1")` and include it in schemas as:

```elixir
defmodule SomeSchema do
  use Ecto.Schema

  schema("some_table_schema") do
    belongs_to(:user, User)

    field(:some_field, ExampleTypeString, default: :val_2)
  end
end
```

This means you can share it between schemas and not worry about keeping it in synch.
If you want to use integers as its underlying representation then declare it as:


```elixir
defmodule ExampleTypeInteger do
  use TypedEnum, values: [val_1: 1, val_2: 2]
end
```

Both versions allow and accept values in `atom` and `String` form. The `integer` version also allows as `integers` obviously.

Ecto equality testing is true between the different formats.

If you need to define special clauses to handle specific values you can define `cast/1`, `dump/1` and `defp get_term/1`.

```elixir
defmodule ExampleCallerModule do
  use TypedEnum, values: [val_1: 1, val_2: 2]

  def cast("some_prop"), do: {:ok, :val_1}
  def dump("some_prop"), do: {:ok, 1}
  defp get_term("some_prop"), do: :val_1
end
```

This would allow you to convert params/values in certain formats even if you don't want to allow storing or treat them as valid internally, which can be useful to deal with legacy api/endpoints/databases/sources while allowing you to use normalised values throughout your application code.


<div id="about"></div>

## About

<img src="https://github.com/mnussbaumer/typed_enum/blob/master/logo/cocktail_logo.png?raw=true" alt="Cocktail Logo" style="background-color: rgba(255, 255, 255, 0.5)">

[© rooster image in the cocktail logo](https://commons.wikimedia.org/wiki/User:LadyofHats)

<div id="copyright"></div>

## Copyright

```
Copyright [2021-∞] [Micael Nussbaumer]

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
