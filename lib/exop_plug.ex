defmodule ExopPlug do

  # conn.private.phoenix_controller - need to check for phoenix

  defmacro __using__(_opts) do
    quote do
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
        stacktrace = [{__MODULE__, :process, 1, [file: file, line: line]}]
        msg = "An operation without a parameter definition"

        IO.warn(msg, stacktrace)
      end

      @spec contract :: list(map())
      def contract, do: @contract
    end
  end

  @spec parameter(atom() | binary(), keyword()) :: any()
  defmacro parameter(name, opts \\ []) when is_atom(name) or is_binary(name) do
    quote generated: true, bind_quoted: [name: name, opts: opts] do
      @contract %{name: name, opts: [inner: opts]}
    end
  end
end
