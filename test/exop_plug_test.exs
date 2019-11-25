defmodule ExopPlugTest do
  use ExUnit.Case, async: true

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

  defmodule MyPlug do
    use ExopPlug

    # should be omitted
    action(:index)
    action(:show, params: %{user_id: [type: :integer]})

    # action :edit, params: %{user_id: [type: :integer], fields: [type: :map]}, on_fail: &__MODULE__.on_fail_func/2
  end

  test "sdf", %{conn: conn} do
    # conn = Map.put(conn, :params, %{"user_id" => 1})
    conn = Map.put(conn, :params, %{user_id: 1})
    MyPlug.call(conn, [])
  end
end
