defmodule ExopPlug do
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

      @spec contract :: list(map())
      def contract, do: @contract

      @spec init(Plug.opts()) :: Plug.opts()
      def init(opts), do: opts

      @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
      def call(%Plug.Conn{private: %{phoenix_action: phoenix_action}} = conn, opts \\ []) do
        Enum.each(@contract, fn
          %{action_name: ^phoenix_action, opts: %{params: %{} = params_specs}} = action_contract ->
            if Enum.empty?(params_specs) do
              conn
            else
              IO.inspect("validate")
            end

          _action_contract ->
            conn
        end)
      end
    end
  end

  # TODO: add contracts types
  @spec action(atom() | binary(), keyword()) :: any()
  defmacro action(action_name, opts \\ []) when is_atom(action_name) or is_binary(action_name) do
    quote generated: true, bind_quoted: [action_name: action_name, opts: opts] do
      opts = Enum.into(opts, %{})
      params = Map.get(opts, :params, %{})

      if Enum.empty?(params) do
        file = String.to_charlist(__ENV__.file())
        line = __ENV__.line()
        stacktrace = [{__MODULE__, :init, 1, [file: file, line: line]}]

        msg =
          "`#{action_name}` action has been defined without params specification and was omited in the validation"

        IO.warn(msg, stacktrace)
      end

      @contract %{action_name: action_name, opts: Map.put(opts, :params, params)}
    end
  end
end
