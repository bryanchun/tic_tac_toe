defmodule TicTacToeWeb.Components.Board do
  use Surface.LiveComponent

  alias TicTacToeWeb.Components.Square

  @squares for row_idx <- [1, 2, 3], col_idx <- [1, 2, 3], do: {row_idx, col_idx}

  @initial_statuses for square <- @squares, into: %{}, do: {square, "available"}
  data statuses, :map, default: @initial_statuses

  @initial_pieces for square <- @squares, into: %{}, do: {square, nil}
  data pieces, :map, default: @initial_pieces

  @initial_whose_turn "X"
  data whose_turn, :string, default: @initial_whose_turn

  @initial_winner_piece nil
  data winner_piece, :string, default: @initial_winner_piece

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="board container-col">
        <div class="board-row" :for={{ row_idx <- [1, 2, 3] }}>
          <span :for={{ col_idx <- [1, 2, 3] }}>
            <Square
              piece={{ @pieces |> Map.get({row_idx, col_idx}) }}
              status={{ @statuses |> Map.get({row_idx, col_idx}) }}
              click="move"
              loc_x={{ row_idx }}
              loc_y={{ col_idx }}
            />
          </span>
        </div>
      </div>
      <div class="container-col">
        <div class="instruction">
          {{ next_instruction(@whose_turn, @winner_piece) }}
        </div>
        <button
          :on-click="restart"
        >
          Restart
        </button>
      </div>
    </div>
    """
  end

  def next_instruction(whose_turn, nil), do: "Next player: #{whose_turn}"
  def next_instruction(_whose_turn, winner_piece) when winner_piece in ["O", "X"], do: "Winner: #{winner_piece}"
  def next_instruction(_whose_turn, " "), do: "Draw"

  # Simple binary flip
  def next_turn("X"), do: "O"
  def next_turn("O"), do: "X"

  @winning_lines [
    # Horizontal lines
    [{1, 1}, {1, 2}, {1, 3}],
    [{2, 1}, {2, 2}, {2, 3}],
    [{3, 1}, {3, 2}, {3, 3}],
    # Vertical lines
    [{1, 1}, {2, 1}, {3, 1}],
    [{1, 2}, {2, 2}, {3, 2}],
    [{1, 3}, {2, 3}, {3, 3}],
    # Diagonal lines
    [{1, 1}, {2, 2}, {3, 3}],
    [{1, 3}, {2, 2}, {3, 1}]
  ]

  @doc """
    Derive the next game state {statuses, winner_piece}
  """
  def next_game_state({statuses, whose_turn}, {_loc_x, _loc_y} = locs, pieces) do
    won_lines = for line <- @winning_lines,
      # Derive the winning lines subset for the taken square in this move
      locs in line,
      # Then restrict these winnable lines to those that contribtued to a win
      # Note that there can be multiple won lines in a game
      Enum.all?(line, & Map.get(pieces, &1) == whose_turn),
      do: line

    # Derive the next {statuses, winner_piece} based on whether there is won lines
    resolve_game({statuses, whose_turn}, locs, won_lines)
  end

  defp resolve_game({statuses, _whose_turn}, {_loc_x, _loc_y} = locs, []) do
    # Mark the locs as status "played"
    statuses = statuses |> Map.put(locs, "played")

    # Derive the winner_piece
    # If all squares have status "played" -> Draw
    # Otherwise -> Continue (still have available squares out there)
    winner_piece = if Enum.all?(@squares, & Map.get(statuses, &1) == "played"),
      do: " ",    # Draw
      else: nil   # Continue

    {statuses, winner_piece}
  end
  defp resolve_game({statuses, whose_turn}, _locs, won_lines) do
    # For each square in the won lines, mark them as status "won"
    won_squares =
      won_lines
      |> List.flatten()
      |> Enum.dedup()

    # For the rest of still-"available" sqaures, mark them as status "disabled"
    unused_squares = for square <- @squares,
      square not in won_squares and Map.get(statuses, square) == "available",
      do: square

    statuses =
      statuses
      |> Map.merge(for square <- won_squares, into: %{}, do: {square, "won"})
      |> Map.merge(for square <- unused_squares, into: %{}, do: {square, "disabled"})

    # Return whose_turn as the winner_piece
    winner_piece =
      whose_turn  # Won

    {statuses, winner_piece}
  end
  # By the end of the game
  # No "available" status squares are left
  # All squares can either be "won", "played" (played but not used to win), "disable" (not even played before game ends)


  def handle_event(
    "move",
    %{"status" => "available",
      "loc_x" => loc_x, "loc_y" => loc_y},
    socket
  ) do
    {loc_x, _} = Integer.parse(loc_x)
    {loc_y, _} = Integer.parse(loc_y)
    # IO.puts("Moved { #{loc_x}, #{loc_y} }")

    pieces =
      socket.assigns[:pieces]
      |> Map.put({loc_x, loc_y}, socket.assigns[:whose_turn])

    {statuses, winner_piece} =
      next_game_state({socket.assigns[:statuses], socket.assigns[:whose_turn]}, {loc_x, loc_y}, pieces)

    socket =
      socket
      |> update(:statuses, fn _ -> statuses end)
      |> update(:pieces, fn _ -> pieces end)
      |> update(:whose_turn, & next_turn(&1))
      |> update(:winner_piece, fn _ -> winner_piece end)

    {:noreply, socket}
  end
  def handle_event("move", %{"status" => "played"}, socket),    do: {:noreply, socket}
  def handle_event("move", %{"status" => "won"}, socket),       do: {:noreply, socket}
  def handle_event("move", %{"status" => "disabled"}, socket),  do: {:noreply, socket}

  def handle_event(
    "restart",
    _params,
    socket
  ) do
    socket =
      socket
      |> update(:statuses, fn _ -> @initial_statuses end)
      |> update(:pieces, fn _ -> @initial_pieces end)
      |> update(:whose_turn, fn _ -> @initial_whose_turn end)
      |> update(:winner_piece, fn _ -> @initial_winner_piece end)
    {:noreply, socket}
  end
end
