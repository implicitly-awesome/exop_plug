defmodule ExopPlugTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  setup do
    # private.phoenix_controller && private.phoenix_action
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

      # action :edit, params: %{user_id: [type: :integer], fields: [type: :map]}, on_fail: &__MODULE__.on_fail_func/2
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
end
