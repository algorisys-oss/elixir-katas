# Kata 79: Date & Time

## The Concept

Elixir provides four built-in types for working with dates and times, each with a specific level of precision and timezone awareness:

| Type | Sigil | Has Date? | Has Time? | Has Timezone? | Use For |
|------|-------|-----------|-----------|---------------|---------|
| **Date** | `~D` | Yes | No | No | Birthdays, deadlines, date-only data |
| **Time** | `~T` | No | Yes | No | Schedules, alarms, time-only values |
| **NaiveDateTime** | `~N` | Yes | Yes | No | Local events, logs, single-TZ apps |
| **DateTime** | `~U` | Yes | Yes | Yes (UTC) | APIs, cross-timezone scheduling |

**Rule of thumb:** Use the narrowest type that fits your needs.

## Creating Values

### With Sigils (compile-time)

```elixir
~D[2024-03-15]              # Date
~T[14:30:00]                # Time
~T[14:30:00.000123]         # Time with microseconds
~N[2024-03-15 14:30:00]     # NaiveDateTime
~U[2024-03-15 14:30:00Z]    # DateTime (UTC)
```

### At Runtime

```elixir
Date.utc_today()                       # today's date in UTC
DateTime.utc_now()                     # current UTC datetime
NaiveDateTime.local_now()              # current local datetime (no TZ)

Date.new(2024, 3, 15)                  # {:ok, ~D[2024-03-15]}
Date.new!(2024, 3, 15)                 # ~D[2024-03-15] (raises on invalid)
NaiveDateTime.new(~D[2024-03-15], ~T[14:30:00])  # {:ok, ~N[...]}
```

## Accessing Fields

All date/time structs expose their fields directly:

```elixir
date = ~D[2024-03-15]
date.year   # 2024
date.month  # 3
date.day    # 15

time = ~T[14:30:45]
time.hour   # 14
time.minute # 30
time.second # 45

dt = ~U[2024-03-15 14:30:00Z]
dt.year         # 2024
dt.time_zone    # "Etc/UTC"
dt.utc_offset   # 0
```

## Date Arithmetic

### Adding and Subtracting

```elixir
# Add/subtract days from a Date
Date.add(~D[2024-03-15], 10)     # ~D[2024-03-25]
Date.add(~D[2024-03-15], -5)     # ~D[2024-03-10]

# Add seconds to NaiveDateTime
NaiveDateTime.add(~N[2024-03-15 14:30:00], 3600)     # +1 hour
NaiveDateTime.add(~N[2024-03-15 14:30:00], -1800)     # -30 minutes

# Add seconds to DateTime
DateTime.add(~U[2024-03-15 14:30:00Z], 86400)         # +1 day
```

### Difference

```elixir
# Difference in days
Date.diff(~D[2024-12-31], ~D[2024-01-01])   # 365

# Difference in seconds
NaiveDateTime.diff(
  ~N[2024-03-15 15:30:00],
  ~N[2024-03-15 14:30:00]
)   # 3600
```

### Date Ranges

```elixir
range = Date.range(~D[2024-03-01], ~D[2024-03-07])

Enum.count(range)                # 7
Enum.to_list(range)              # [~D[2024-03-01], ..., ~D[2024-03-07]]
~D[2024-03-05] in range         # true

# Count weekdays
Enum.count(range, fn d -> Date.day_of_week(d) in 1..5 end)
```

## Comparing Dates and Times

```elixir
# All types support compare/2 -> returns :lt, :eq, or :gt
Date.compare(~D[2024-01-01], ~D[2024-12-31])         # :lt
Time.compare(~T[09:00:00], ~T[17:00:00])             # :lt
DateTime.compare(~U[2024-01-01 00:00:00Z], ~U[2024-12-31 00:00:00Z])  # :lt

# Before/after checks
Date.before?(~D[2024-01-01], ~D[2024-12-31])         # true
Date.after?(~D[2024-12-31], ~D[2024-01-01])          # true

# Sorting
dates = [~D[2024-03-15], ~D[2024-01-01], ~D[2024-07-04]]
Enum.sort(dates, Date)                                 # chronological order
Enum.sort(dates, {:desc, Date})                        # reverse chronological
```

## Formatting with Calendar.strftime

```elixir
dt = ~U[2024-03-15 14:30:45Z]

Calendar.strftime(dt, "%Y-%m-%d")                # "2024-03-15"
Calendar.strftime(dt, "%B %d, %Y")               # "March 15, 2024"
Calendar.strftime(dt, "%I:%M %p")                # "02:30 PM"
Calendar.strftime(dt, "%A, %B %d, %Y")           # "Friday, March 15, 2024"
Calendar.strftime(dt, "%Y-%m-%dT%H:%M:%SZ")      # "2024-03-15T14:30:45Z"
```

### Common Directives

| Directive | Meaning | Example |
|-----------|---------|---------|
| `%Y` | 4-digit year | 2024 |
| `%m` | Month (01-12) | 03 |
| `%d` | Day (01-31) | 15 |
| `%H` | Hour 24h (00-23) | 14 |
| `%I` | Hour 12h (01-12) | 02 |
| `%M` | Minute (00-59) | 30 |
| `%S` | Second (00-59) | 45 |
| `%p` | AM/PM | PM |
| `%A` | Full weekday | Friday |
| `%a` | Short weekday | Fri |
| `%B` | Full month | March |
| `%b` | Short month | Mar |

## Parsing

```elixir
# From ISO 8601 strings
Date.from_iso8601("2024-03-15")              # {:ok, ~D[2024-03-15]}
DateTime.from_iso8601("2024-03-15T14:30:00Z") # {:ok, ~U[...], 0}

# From Unix timestamps
DateTime.from_unix(1_700_000_000)            # {:ok, ~U[2023-11-14 22:13:20Z]}
DateTime.from_unix(1_700_000_000, :millisecond)  # from milliseconds

# To Unix timestamps
DateTime.to_unix(~U[2024-03-15 14:30:00Z])  # 1710513000
```

## Converting Between Types

```elixir
# DateTime -> Date, Time
DateTime.to_date(~U[2024-03-15 14:30:00Z])    # ~D[2024-03-15]
DateTime.to_time(~U[2024-03-15 14:30:00Z])    # ~T[14:30:00]

# DateTime -> NaiveDateTime
DateTime.to_naive(~U[2024-03-15 14:30:00Z])   # ~N[2024-03-15 14:30:00]

# NaiveDateTime -> DateTime (assume UTC)
DateTime.from_naive!(~N[2024-03-15 14:30:00], "Etc/UTC")
# ~U[2024-03-15 14:30:00Z]

# NaiveDateTime -> Date, Time
NaiveDateTime.to_date(~N[2024-03-15 14:30:00])  # ~D[2024-03-15]
NaiveDateTime.to_time(~N[2024-03-15 14:30:00])  # ~T[14:30:00]
```

## NaiveDateTime vs DateTime

| Aspect | NaiveDateTime | DateTime |
|--------|---------------|----------|
| Timezone | None -- "naive" | Included (e.g., UTC) |
| Use when | Single timezone, local events | Cross-TZ, APIs, distributed systems |
| Comparison | Only meaningful in same TZ | Globally comparable |
| Storage | Simpler (no TZ data) | More complete |
| Sigil | `~N[...]` | `~U[...]` (UTC) |

**When in doubt, use DateTime.** It's safer for most production applications.

## Common Patterns

### Age Calculation

```elixir
def age(birthday) do
  today = Date.utc_today()
  years = today.year - birthday.year

  if Date.compare(
    %{today | year: birthday.year},
    birthday
  ) == :lt do
    years - 1
  else
    years
  end
end

age(~D[1990-06-15])  # calculates current age
```

### Time Elapsed (Human-Readable)

```elixir
def time_ago(datetime) do
  diff = DateTime.diff(DateTime.utc_now(), datetime)

  cond do
    diff < 60 -> "#{diff} seconds ago"
    diff < 3600 -> "#{div(diff, 60)} minutes ago"
    diff < 86400 -> "#{div(diff, 3600)} hours ago"
    true -> "#{div(diff, 86400)} days ago"
  end
end
```

### Working with Date Ranges

```elixir
# Business days between two dates
def business_days(start_date, end_date) do
  Date.range(start_date, end_date)
  |> Enum.count(fn date -> Date.day_of_week(date) in 1..5 end)
end

# Next occurrence of a weekday
def next_weekday(date, target_day) do
  date
  |> Date.add(1)
  |> Stream.iterate(&Date.add(&1, 1))
  |> Enum.find(&(Date.day_of_week(&1) == target_day))
end
```

## Day of Week

```elixir
Date.day_of_week(~D[2024-03-15])   # 5 (Friday)

# ISO 8601: 1 = Monday, 7 = Sunday
# To get day name:
@day_names %{1 => "Mon", 2 => "Tue", 3 => "Wed", 4 => "Thu",
             5 => "Fri", 6 => "Sat", 7 => "Sun"}

# Or use Calendar.strftime:
Calendar.strftime(~D[2024-03-15], "%A")  # "Friday"
```

## Timezones Beyond UTC

The Elixir standard library only supports UTC. For other timezones, use the `tz` or `tzdata` library:

```elixir
# In mix.exs: {:tz, "~> 0.26"}
# Then:
DateTime.now("America/New_York")    # {:ok, #DateTime<...>}
DateTime.shift_zone(utc_dt, "Europe/London")
```

## Key Takeaways

1. **Four types, each with a purpose** -- Date (date only), Time (time only), NaiveDateTime (no TZ), DateTime (with TZ). Pick the narrowest type you need.
2. **Sigils for compile-time creation** -- `~D`, `~T`, `~N`, `~U` create validated structs at compile time.
3. **Date arithmetic is built in** -- `Date.add/2`, `Date.diff/2`, `Date.range/2` handle day-level math. `NaiveDateTime.add/2` handles seconds.
4. **Use Calendar.strftime for formatting** -- familiar %-directives like `%Y-%m-%d` work on all date/time types.
5. **NaiveDateTime vs DateTime** -- if your app deals with users in different timezones, always use DateTime. NaiveDateTime is fine for single-timezone or local-only data.
