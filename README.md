# ExopPlug

This library provides a convenient way to validate incoming parameters
of your Phoenix application's controllers by providing you small but useful DSL
which makes as little magic behind the scenes as possible leaves you all the control
under HTTP request.

## Table of Contents

[CHANGELOG](https://github.com/madeinussr/exop_plug/blob/master/CHANGELOG.md)

- [Installation](#installation)
- [How it works](#how-it-works)
- [Step-by-step](#step-by-step)
  - [1. create a plug](#1-create-a-plug)
  - [2. in a controller](#2-in-a-controller)
- [More examples](#more-examples)
  - [coercing](#coercing)
  - [rely on `action_fallback`](#rely-on-action_fallback)
  - [respond directly from `on_fail` callback](#respond-directly-from-on_fail-callback)
- [LICENSE](#license)

## Installation

```elixir
def deps do
  [{:exop_plug, "~> 1.0.0"}]
end
```

## How it works

Basically speaking ExopPlug utilizes the power of [Exop](https://github.com/madeinussr/exop) library
by generating in compile time Exop-operations for your actions defined in a plug.

So, you define a plug with number of actions and parameters with validation checks.
Then you use this plug in corresponding controller and that's it: once HTTP request comes,
your controller's plug takes an action: it figures out whether this particular HTTP request's
parameters should be validated or not, and if yes - validates them.

If parameters pass the validation ExopPlug returns `Plug.Conn` (as usual plug does),
if not - it returns [Exop's](https://github.com/madeinussr/exop) error-tuple as described
[here](https://github.com/madeinussr/exop#operation-results). And it is up to you then to decide
how you want to handle the result.

Please keep in mind: ExopPlug doesn't transform your HTTP request nor `Plug.Conn.t()` structure.
So, if you define `get '/user/:user_id'` in your router you receive `%{"user_id" => "1"}` for
the request `http://localhost:4000/user/1`. There is no any coercion or type inference done
under the scenes.

_(if such feature(-s) will be requested, they'll be added and you'll need to specify them
explicitly in an action definition)_

## Step-by-step

### 1. create a plug

Create a new module plug and define actions with parameters you want to validate.
A parameter's validations are the same as Exop has for an operation parameter checks.
You can find all them [here](https://github.com/madeinussr/exop#parameter-checks)
along with other features like coercion.

```elixir
defmodule MyAppWeb.UserControllerPlug do
  use ExopPlug

  action(:show, params: %{"id" => [type: :string, length: %{min: 5}]}, on_fail: &__MODULE__.on_fail/3)

  def on_fail(conn, action_name, errors_map) do
    Plug.Conn.assign(conn, :errors, errors_map)
  end
end
```

Here we also defined an `on_fail` callback. This 3-arity function is called when an action's parameters
failed the specified validation.

### 2. in a controller

Simply add `plug MyAppWeb.UserControllerPlug` at the top of your controller.

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller

  plug MyAppWeb.UserControllerPlug

  # ...

  def show(conn, params) do
    json(conn, params)
  end

  # ...
end
```

Now, if you receive invalid parameters for your `show` you get (for example)
`errors: %{"id" => ["has wrong type"]}}` within your `Plug.Conn` assigns
(as you earlier specified in your plug). And then it is up to you how to deal with this errors map.

## More examples

The power of ExopPlug actually is provided by Exop and its validation capabilities.
Basically, every check you use in Exop you can apply for an action's parameter in your plug.

Below I put a couple of examples just in order to show different checks and things you can do with
a parameter or validation errors.


### coercing

In the example above there is one tricky thing which I've just omit for the sake of example:
with `get '/user/:user_id'` route you'll get `user_id` parameter as string, always, because it is
path parameter.

But you can coerce it before the validation:

```elixir
action(:show, params: %{"id" => [type: :integer, coerce_with: &__MODULE__.coerce_integer/2]})

def coerce_integer({_, param_value}, _) when is_binary(param_value) do
  {integer, ""} = Integer.parse(param_value)
  integer
end
```

_(and again: read more about `:coerce_with` option in Exop [docs](https://github.com/madeinussr/exop))_

### rely on `action_fallback`

After assigning errors to a connection you can later pattern-match it in a controller's action
and invoke your `action_fallback`'s fallback controller:

```elixir
# in a plug ...

action(:show, params: %{"id" => [type: :integer]}, on_fail: &__MODULE__.on_fail/3)

def on_fail(conn, action_name, errors_map) do
  Plug.Conn.assign(conn, :errors, errors_map)
end

# in a controller ...

action_fallback MyAppWeb.FallbackController

def show(%Plug.Conn{assigns: %{errors: errors_map}}, _params) do
  {:error, errors_map}
end

# in the fallback controller ...

def call(conn, {:error, errors_map}) do
  json(conn, errors_map)
end
```

### respond directly from `on_fail` callback

It might be useful not to assign validation errors to a connection, but respond immediately:

```elixir
action(:show, params: %{"id" => [type: :integer]}, on_fail: &__MODULE__.on_fail/3)

def on_fail(conn, action_name, errors_map) do
  response = %{
    action: action_name,
    errors: errors_map
  }

  Phoenix.Controller.json(conn, response)
end
```

## LICENSE

    Copyright © 2016 - 2019 Andrey Chernykh ( andrei.chernykh@gmail.com )

    This work is free. You can redistribute it and/or modify it under the
    terms of the MIT License. See the LICENSE file for more details.
