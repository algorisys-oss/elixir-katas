# Kata 34: Enum Aggregates

## The Concept

Aggregation functions collapse collections into summary values. They are the final step in many data processing pipelines, producing counts, sums, extremes, frequency distributions, and groupings.

## Enum.count/1,2

Returns the number of elements, optionally filtered by a predicate:

```elixir
Enum.count([1, 2, 3, 4, 5])
# 5

Enum.count([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))
# 3

Enum.count([])
# 0
```

Note: For lists, `length/1` (a kernel function) is O(n) but runs in native code and may be faster. `Enum.count/1` works with all enumerables.

## Enum.sum/1

Sums all numeric elements:

```elixir
Enum.sum([1, 2, 3, 4, 5])
# 15

Enum.sum(1..100)
# 5050

Enum.sum([1.5, 2.5, 3.0])
# 7.0

Enum.sum([])
# 0
```

For products, use `Enum.product/1` (Elixir 1.14+) or `Enum.reduce(list, 1, &*/2)`.

## Enum.min/1,2 and Enum.max/1,2

Find the minimum or maximum element:

```elixir
Enum.min([5, 3, 8, 1, 9])
# 1

Enum.max([5, 3, 8, 1, 9])
# 9

# Both at once (single pass)
Enum.min_max([5, 3, 8, 1, 9])
# {1, 9}
```

## Enum.min_by/2,3 and Enum.max_by/2,3

Find min/max using a key function for comparison:

```elixir
Enum.max_by(["hi", "hello", "hey"], &String.length/1)
# "hello"

Enum.min_by([%{age: 25}, %{age: 18}, %{age: 30}], & &1.age)
# %{age: 18}
```

## Enum.frequencies/1

Counts occurrences of each value, returning a map:

```elixir
Enum.frequencies(["a", "b", "a", "c", "b", "a"])
# %{"a" => 3, "b" => 2, "c" => 1}

Enum.frequencies([1, 2, 2, 3, 3, 3])
# %{1 => 1, 2 => 2, 3 => 3}
```

## Enum.frequencies_by/2

Counts occurrences using a key function:

```elixir
Enum.frequencies_by(["apple", "avocado", "banana", "blueberry"], &String.first/1)
# %{"a" => 2, "b" => 2}

Enum.frequencies_by(1..10, &(rem(&1, 3)))
# %{0 => 3, 1 => 4, 2 => 3}
```

## Enum.group_by/2,3

Groups elements by a key function, returning a map of key => [elements]:

```elixir
Enum.group_by([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))
# %{false => [1, 3, 5], true => [2, 4, 6]}

Enum.group_by(["ant", "bear", "cat", "ape", "bee"], &String.first/1)
# %{"a" => ["ant", "ape"], "b" => ["bear", "bee"], "c" => ["cat"]}

# With value mapper (third argument)
Enum.group_by(employees, & &1.department, & &1.name)
# %{"Engineering" => ["Alice", "Bob"], "Design" => ["Carol"]}
```

## Practical Data Analysis

Aggregates shine when analyzing structured data:

```elixir
employees = [
  %{name: "Alice", dept: "Eng", salary: 95_000},
  %{name: "Bob",   dept: "Eng", salary: 88_000},
  %{name: "Carol", dept: "Design", salary: 82_000}
]

# Total payroll
employees |> Enum.map(& &1.salary) |> Enum.sum()
# 265_000

# Average salary
salaries = Enum.map(employees, & &1.salary)
Enum.sum(salaries) / Enum.count(salaries)
# 88_333.33

# Highest paid
Enum.max_by(employees, & &1.salary)
# %{name: "Alice", ...}

# Headcount by department
Enum.frequencies_by(employees, & &1.dept)
# %{"Eng" => 2, "Design" => 1}

# Group names by department
Enum.group_by(employees, & &1.dept, & &1.name)
# %{"Eng" => ["Alice", "Bob"], "Design" => ["Carol"]}
```

## Common Pitfalls

1. **Empty collections**: `min/1` and `max/1` raise on empty collections. Use `min/2` with a default or guard against empty input.
2. **frequencies vs group_by**: `frequencies` counts occurrences; `group_by` collects elements. Choose based on whether you need the count or the actual items.
3. **Single-pass efficiency**: `min_max/1` is more efficient than calling `min/1` and `max/1` separately (one pass vs two).
4. **group_by value mapper**: The third argument to `group_by/3` transforms the values, avoiding a separate `Enum.map` call.
