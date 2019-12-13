# ExopPlug

This library provides a convenient way to validate incoming parameters
of your Phoenix application's controllers by providing you small but useful DSL
which makes as little magic behind the scenes as possible leaves you all the control
under HTTP request.

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
A parameter's validations specification is the same as Exop has.
You can check it [here](https://github.com/madeinussr/exop#parameter-checks)
along with available checks (validations).

```elixir
defmodule MyAppWeb.UserControllerPlug do
  use ExopPlug

  action(:show, params: %{"id" => [type: :integer]}, on_fail: &__MODULE__.on_fail/3)

  def on_fail(conn, action_name, {:error, {:validation, errors_map}} = errors) do
    Plug.Conn.assign(conn, :errors, errors)
  end
end

```

### 2. in a controller

Open your controller which actions parameters you'd like to validate and add
