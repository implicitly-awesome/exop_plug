defmodule ExopPlug do
  defmacro __using__(_opts) do
    quote do
      require Logger
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
      else
        Enum.each(@contract, fn %{action_name: action_name, opts: %{params: params}} ->
          params = Macro.escape(params)

          operation_body =
            quote generated: true, location: :keep do
              use Exop.Operation

              @contract Enum.reduce(unquote(params), %{}, fn {param_name, param_opts}, acc ->
                          Map.merge(acc, %{name: param_name, opts: param_opts})
                        end)

              parameter(:conn, struct: Plug.Conn)

              def process(%{conn: conn}), do: conn
            end

          Module.create(
            :"#{__MODULE__}.#{String.capitalize(Atom.to_string(action_name))}",
            operation_body,
            Macro.Env.location(__ENV__)
          )
        end)
      end

      @spec contract :: list(map())
      def contract, do: @contract

      @spec init(Plug.opts()) :: Plug.opts()
      def init(opts), do: opts

      @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t() | map() | any()
      def call(
            %Plug.Conn{private: %{phoenix_action: phoenix_action}, params: conn_params} = conn,
            opts \\ []
          ) do
        %{opts: %{params: %{} = params_specs, on_fail: on_fail}} =
          _action_contract =
          Enum.find(@contract, fn
            %{action_name: ^phoenix_action} -> true
            _ -> false
          end)

        if Enum.empty?(params_specs) do
          conn
        else
          operation_module = :"#{__MODULE__}.#{String.capitalize(Atom.to_string(phoenix_action))}"
          operation_params = Map.put(conn_params, :conn, conn)
          operation_result = Kernel.apply(operation_module, :run, [operation_params])

          case operation_result do
            {:ok, %Plug.Conn{} = conn} ->
              conn

            {:error, _} = error ->
              if is_function(on_fail) do
                on_fail.(conn, phoenix_action, error)
              else
                %{phoenix_action => error}
              end
          end
        end
      end
    end
  end

  @spec action(atom() | binary(), keyword()) :: any()
  defmacro action(action_name, opts \\ [])
           when (is_atom(action_name) or is_binary(action_name)) and is_list(opts) do
    quote generated: true, bind_quoted: [action_name: action_name, opts: opts] do
      file = String.to_charlist(__ENV__.file())
      line = __ENV__.line()
      stacktrace = [{__MODULE__, :action, 2, [file: file, line: line]}]

      already_has_action? =
        Enum.any?(@contract, fn
          %{action_name: ^action_name} -> true
          _ -> false
        end)

      if already_has_action? do
        raise(CompileError,
          file: file,
          line: line,
          description: "`#{action_name}` action is duplicated"
        )
      else
        opts = Enum.into(opts, %{})

        params = Map.get(opts, :params, :nothing)

        params =
          cond do
            is_list(params) and Enum.empty?(params) -> :nothing
            is_list(params) -> Enum.into(params, %{})
            is_map(params) and Enum.empty?(params) -> :nothing
            is_map(params) -> params
            true -> :nothing
          end

        opts =
          if params == :nothing do
            IO.warn(
              "`#{action_name}` action has been defined without params specification and will be omited during the validation",
              stacktrace
            )

            Map.put(opts, :params, %{})
          else
            opts
          end

        on_fail = Map.get(opts, :on_fail, :nothing)

        opts =
          cond do
            on_fail == :nothing ->
              Map.put(opts, :on_fail, nil)

            is_function(on_fail) && on_fail |> Function.info() |> Keyword.get(:arity, 0) == 3 ->
              opts

            is_function(on_fail) ->
              raise(CompileError,
                file: file,
                line: line,
                description: "`#{action_name}` action's `on_fail` callback should have arity = 3"
              )

            true ->
              raise(CompileError,
                file: file,
                line: line,
                description: "`#{action_name}` action's `on_fail` callback is not a function"
              )
          end

        @contract %{action_name: action_name, opts: opts}
      end
    end
  end
end
