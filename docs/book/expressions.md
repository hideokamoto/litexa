# Variables and Expressions

Variables are a programming language's way of
naming and storing chunks of data.

When your skill is live, multiple users will show
up and interact with it simultaneously, and your
endpoint will need to handle interleaved requests
coming from all of them. So each request will need
to "pick up" from where that users is in your skill.

Aside from that, with longer form skills you'll
usually want to remember things about your users,
say where they are in a longer game so they don't
have to start from scratch.

Both of these needs inform Litexa's approach to
variable *scoping*, the lifespan and visibility
of variables, producing three distinct kinds
of variables: *local, request and persistent*.

Because some variables will need to survive past
the current request, and possibly even pick up on
a different machine all together, in the case that
your skill endpoint is load balanced, Litexa
differentiates between two kinds of variable
*storage* types: *memory, and database*.

## Value Types

Each variable in Litexa can store one of a number of
different kinds of values.

* Numbers, integer or floating point, e.g. `1, -8, or 15.4`
* Booleans, the values `true` or `false`
* Strings, double quoted, e.g. `"Hello"` and `"World"`

Additionally, Litexa variables can also host any
valid JavaScript value, including objects, arrays,
null, undefined, and even functions, with one caveat:
any variables with *database storage* must survive
conversion to and from JSON.

Strings in Litexa may span more than one line, letting
you break up longer strings as you see fit. In this
case, white space to the left of the second line will
be collapsed into a single space, and subsequent lines
will remove the same amount of whitespace.

In the next sample, a and b will contain the same strings.

```coffeescript
launch
  local a = "here's a string
    with a second,
    and third line"

  local b = "here's a string with a second, and third line"
```

## Local Variables

The first kind of variable behaves much like
traditional variables in that they are *lexically
scoped*, meaning that their lifespan will align
with the block of code they sit in, and they will
be visible to any code inside that block.

Local variables must be declared before use, with
the `local` statement, and cannot be declared
again in the same scope, including in subordinate
blocks of code: Litexa does not allow *variable
shadowing.*

Local variables must also be initialized with a value.

```coffeescript
launch
  local counter = 0
  local name = "Jane"
  local flag = false
```

Local variables that are declared and used in a
single handler have memory storage. Local variables
can survive across more than one handler though,
when declared in the state's entry handler and then
referenced in any of the state's intent handlers or
the state's exit handler. In this case, they are
automatically promoted to database storage.

::: warning
Reentering a state will reset its "persistent"
local variables, since it will call the initialization
in the state's entry handler.
:::

In the next example:

1. The loops variable is declared and initialized to 0
in askForAction's entry handler.
2. While in askForAction, any help or unexpected intent
will increment loops by 1 in its handler.
3. In the handler for a valid action intent, a state
transition to takeAction is called. This triggers
askForAction's exit handler and reads out the loops value.

```coffeescript
askForAction
  local loops = 0
  say "What should we do?"

  when "let's $action"
    with $action = "jump", "run", "shoot"
    say "Alright, attempting $action"
    -> takeAction

  when AMAZON.HelpIntent
    loops = loops + 1
    say "Just tell me what you want to do."

  otherwise
    say "Yeah no, that's not going to work. What should we do?
      Maybe jump, run, or shoot?"
    loops = loops + 1

  if loops > 1
    say "Geez, that only took {loops} tries."
```

## Request Variables

Request variables live from the moment they are
declared until the end of the current request, that
is to say until the end of the next handler that
ends with a LISTEN or END statement. This means
they survive between states, and will always have
memory storage.

Request variable names must always begin with the
`$` character, and are declared and created on
their first assignment.

We've already come across several request variables
so far, in the form of slot values.

```coffeescript
askForName
  say "Hey, what's your name?"

  when "my name is $name"
    with $name = AMAZON.US_FIRST_NAME

    # the $name variable exists here
    say "Hello $name."
    -> flatterPlayer

flatterPlayer
  # because we came here directly from the other state
  # the request variable is still in scope
  say "$name is such a pretty name, don't you agree?"

  when AMAZON.YesIntent
    # as this intent happens in a different request,
    # the $name variable is no longer available
```

Request variables can be empty, that is to say they
might not have been assigned yet. In that case, they'll
contain a "falsy" value, meaning you can use an `if`
statement to choose behavior based on their existence.

In the following example, not all utterances contain
all slots, so in some cases the slot may not have a
value.

```coffeescript
askForAttack
  say "How should we attack?"

  when "attack the $enemy with the $weapon"
    or "attack the $enemy"
    or "use the $weapon"
    with $enemy = enemies.js:enemySlots
    with $weapon = weapons.js:weaponSlots

    if $enemy
      say "Attacking the $enemy."

    if $weapon
      say "Using the $weapon."
```

## Persistent Variables

Sometimes you need a variable to survive longer than
both local and request variables. Persistent variables
exist from the moment they are created until you decide
to destroy them.

Persistent variable names always begin with the `@`
symbol and always have database storage, meaning they
must be able to survive being converted to and from
JSON.

As with request variables, persistent variables that
haven't been assigned to yet will have a falsy value,
and can be tested directly.

```coffeescript
launch
  if @name
    say "Welcome back, @name."
    -> playGame
  else
    say "Hello, stranger"
    -> askName

askName
  say "What's your name?"

  when "My name is $name"
    with $name = AMAZON.US_FIRST_NAME

    say "Nice to meet you, $name"
    # store the result permanently
    @name = $name
```

## Expressions

There are various places in Litexa syntax that accept
an *expression*, which is a chunk of code that produces
a resulting value.

The simplest expressions are just primitive values.
Here we see the right side of an assignment statement
taking a few of these expressions.

```coffeescript
  local a = 15
  local name = "Sue"
```

Expressions can contain operators that combine two values
into a new one. Litexa supports the following list of
arithmetic operators `-`, `+`, `*`, and `/`

```coffeescript
  local a = 5 + 10
  local b = 10 / 2
  local phrase = "Hello" + " " + "World"
```

You can also produce boolean values using a the set of
comparison operators `==`, `!=`, `>`, `>=`, `<`, `<=`,
`and` and `or`

```coffeescript
  local a = 5 > 3
  local b = name == "Bob" and age == 18
```

You can control the order that parts of an expression
evaluate in by using parentheses.

```coffeescript
  local a = ( 5 + 10 ) * 3
```

You can also include variable names in expressions to
use their values.

```coffeescript
  local a = 10
  local b = a + 5
  $count = 10
  local c = ( a * $count ) + b - 7
```
