defmodule TicTacToeWeb.GameLive do
  use TicTacToeWeb, :live_view
  alias TicTacToeWeb.Components.Board
  alias TicTacToeWeb.Components.Square

  def render(assigns) do
    ~H"""
    <Board />

    <Square
      piece={{ @loc_1_1_piece }}
      status={{ @loc_1_1_status }}
      click="move"
      loc_x=1 loc_y=1
    />

    <Square
      piece="X"
      status="won"
      loc_x=2 loc_y=1
    />

    <Square
      piece="X"
      click="move"
      loc_x=3 loc_y=1
    />
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> Surface.init()
      |> assign(:ans, 42)
      |> assign(:params, "")
      |> assign(:loc_1_1_piece, "")
      |> assign(:loc_1_1_status, "playing")

    {:ok, socket}
  end

  def handle_event("move", %{"loc_x" => "1", "loc_y" => "1"}, socket) do\
    socket =
      socket
      |> assign(:loc_1_1_piece, "X")
      |> assign(:loc_1_1_status, "won")

    {:noreply, socket}
  end
end
