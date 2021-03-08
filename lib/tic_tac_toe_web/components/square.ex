defmodule TicTacToeWeb.Components.Square do
  use Surface.Component

  @doc "The piece symbol on the square"
  prop piece, :string, values: [" ", "X", "O"], default: " "

  @doc "The status of this square: we will highlight it when someone won"
  prop status, :string, values: ["playing", "won"], default: "playing"

  @doc "The event name triggered when the square gets clicked"
  prop click, :event

  @doc """
    x-Location of this square on the game board. Should be 1, 2, or 3.
    To be passed to the click event as parameters.
  """
  prop loc_x, :number, required: true

  @doc """
    y-Location of this square on the game board. Should be 1, 2, or 3.
    To be passed to the click event as parameters.
  """
  prop loc_y, :number, required: true

  @doc "status to color for display"
  def to_color("playing"), do: "white"
  def to_color("won"), do: "yellow"

  def render(assigns) do
    ~H"""
    <button
      class="square"
      style="background-color: {{ to_color(@status) }};"
      :on-click={{ @click }}
      phx-value-loc_x={{ @loc_x }}
      phx-value-loc_y={{ @loc_y }}
    >
      {{ @piece }}
    </button>
    """
  end
end
