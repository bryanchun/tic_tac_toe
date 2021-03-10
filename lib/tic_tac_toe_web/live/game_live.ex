defmodule TicTacToeWeb.GameLive do
  use TicTacToeWeb, :live_view

  alias TicTacToeWeb.Components.Board

  def render(assigns) do
    ~H"""
    <Board
      id=42
      />
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> Surface.init()

    {:ok, socket}
  end
end
