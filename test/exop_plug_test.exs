defmodule ExopPlugTest do
  use ExUnit.Case, async: true

  defmodule MyPlug do
    use ExopPlug

    action :index # should be omitted
    action :show, params: %{user_id: [type: :integer]}
    # action :edit, params: %{user_id: [type: :integer], fields: [type: :map]}, on_fail: &__MODULE__.on_fail_func/2
  end
end
