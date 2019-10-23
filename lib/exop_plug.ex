defmodule ExopPlug do

  # conn.private.phoenix_controller - need to check for phoenix

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :contract, accumulate: true)

      @module_name __MODULE__

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true, location: :keep do
      if is_nil(@contract) || Enum.count(@contract) == 0 do
        file = String.to_charlist(__ENV__.file())
        line = __ENV__.line()
        stacktrace = [{__MODULE__, :init, 1, [file: file, line: line]}]
        msg = "A plug without an action definition"

        IO.warn(msg, stacktrace)
      end

      Enum.each(@contract, fn action_contract ->
        param_opts = Map.get(action_contract, :params, %{})

        if Enum.count(param_opts) == 0 do
          file = String.to_charlist(__ENV__.file())
          line = __ENV__.line()
          stacktrace = [{__MODULE__, :init, 1, [file: file, line: line]}]
          msg = "An action was defined without params specification"

          IO.warn(msg, stacktrace)
        end
      end)

      @spec contract :: list(map())
      def contract, do: @contract
    end
  end

  @spec action(atom() | binary(), keyword()) :: any()
  defmacro action(action_name, opts \\ []) when is_atom(action_name) or is_binary(action_name) do
    quote generated: true, bind_quoted: [action_name: action_name, opts: opts] do
      opts = Enum.into(opts, %{})
      params = Map.get(opts, :params, %{})

      @contract %{action_name: action_name, opts: Map.put(opts, :params, params)}
    end
  end
end
