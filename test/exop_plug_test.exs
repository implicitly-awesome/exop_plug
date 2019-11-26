defmodule ExopPlugTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  setup do
    conn =
      Map.merge(%Plug.Conn{}, %{
        private: %{
          phoenix_controller: MyApp.SomeController,
          phoenix_action: :show
        }
      })

    {:ok, conn: conn}
  end

  describe "with single simple action defined" do
    defmodule SimplePlug do
      use ExopPlug

      action(:show, params: %{user_id: [type: :integer]})
    end

    test "returns Plug.Conn for valid params", %{conn: conn} do
      valid_params = %{user_id: 1}

      conn = Map.put(conn, :params, valid_params)

      assert ^conn = SimplePlug.call(conn, [])
    end

    test "returns errors map for invalid params", %{conn: conn} do
      invalid_params = %{user_id: "1"}

      conn = Map.put(conn, :params, invalid_params)

      assert capture_log(fn ->
               assert %{show: {error, {:validation, %{user_id: ["has wrong type"]}}}} =
                        SimplePlug.call(conn, [])
             end) =~ "user_id: has wrong type"
    end
  end

  describe "with string param name" do
    defmodule SimpleStringPlug do
      use ExopPlug

      action(:show, params: %{"user_id" => [type: :integer]})
    end

    test "returns Plug.Conn for valid params", %{conn: conn} do
      valid_params = %{"user_id" => 1}

      conn = Map.put(conn, :params, valid_params)

      assert ^conn = SimpleStringPlug.call(conn, [])
    end

    test "returns errors map for invalid params", %{conn: conn} do
      invalid_params = %{"user_id" => "1"}

      conn = Map.put(conn, :params, invalid_params)

      assert capture_log(fn ->
               assert %{show: {error, {:validation, %{"user_id" => ["has wrong type"]}}}} =
                        SimpleStringPlug.call(conn, [])
             end) =~ "user_id: has wrong type"
    end
  end

  describe "with actions without params" do
    defmodule WithoutParamsPlug do
      use ExopPlug

      action(:show)
    end

    test "returns the conn", %{conn: conn} do
      assert ^conn = WithoutParamsPlug.call(conn, [])
    end
  end

  describe "on_fail callback" do
    defmodule OnFailPlug do
      use ExopPlug

      action(:show, params: %{user_id: [type: :integer]}, on_fail: &__MODULE__.on_fail/3)

      def on_fail(%{params: params} = _conn, :show, error), do: {params[:user_id], error}
    end

    test "a function specified in on_fail callback is called", %{conn: conn} do
      invalid_params = %{user_id: "1"}

      conn = Map.put(conn, :params, invalid_params)

      assert capture_log(fn ->
               assert {"1", {:error, {:validation, %{user_id: ["has wrong type"]}}}} =
                        OnFailPlug.call(conn, [])
             end) =~ "user_id: has wrong type"
    end
  end

  describe "with duplicated action names" do
    defmodule DuplicatedActionsPlug do
      use ExopPlug

      action(:show, params: %{user_id: [type: :integer]})
      action(:show, params: %{user_id: [type: :string]})
    end

    test "uses the first action specification", %{conn: conn} do
      valid_params = %{user_id: 1}

      conn = Map.put(conn, :params, valid_params)

      assert ^conn = DuplicatedActionsPlug.call(conn, [])
    end
  end
end
