defmodule TicTacToeWeb.Components.Board do
  use Surface.LiveComponent

  alias TicTacToeWeb.Components.Square

  data statuses, :map,
    default: for row_idx <- [1, 2, 3], col_idx <- [1, 2, 3],
      into: %{},
      do: {{row_idx, col_idx}, "available"}

  data pieces, :map,
    default: for row_idx <- [1, 2, 3], col_idx <- [1, 2, 3],
      into: %{},
      do: {{row_idx, col_idx}, nil}

  data whose_turn, :string, default: "X"

  data winner_piece, :string, default: nil

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
        {{ next_instruction(@whose_turn, @winner_piece) }}
      </div>
    </div>
    """
  end

  defp next_instruction(whose_turn, nil), do: "Next player: #{next_turn(whose_turn)}"
  defp next_instruction(_whose_turn, winner_piece) when winner_piece in ["O", "X"], do: "Winner: #{winner_piece}"
  defp next_instruction(_whose_turn, " "), do: "Draw"

  defp next_turn("X"), do: "O"
  defp next_turn("O"), do: "X"


  # TODO: Debug winning not working
  defp next_statuses({statuses, whose_turn}, pieces, {1, 1}), do:
    [
      [{1, 1}, {1, 2}, {1, 3}],
      [{1, 1}, {2, 1}, {3, 1}],
      [{1, 1}, {2, 2}, {3, 3}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {1, 2}), do:
    [
      [{1, 1}, {1, 2}, {1, 3}],
      [{1, 2}, {2, 2}, {3, 2}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {1, 3}), do:
    [
      [{1, 1}, {1, 2}, {1, 3}],
      [{1, 3}, {2, 3}, {3, 3}],
      [{1, 3}, {2, 2}, {3, 1}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {2, 1}), do:
    [
      [{1, 1}, {2, 1}, {3, 1}],
      [{2, 1}, {2, 2}, {2, 3}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {2, 2}), do:
    [
      [{1, 2}, {2, 2}, {3, 2}],
      [{2, 1}, {2, 2}, {2, 3}],
      [{1, 1}, {2, 2}, {3, 3}],
      [{1, 3}, {2, 2}, {3, 1}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {2, 3}), do:
    [
      [{1, 3}, {2, 3}, {3, 3}],
      [{2, 1}, {2, 2}, {2, 3}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {3, 1}), do:
    [
      [{3, 1}, {3, 2}, {3, 3}],
      [{1, 1}, {2, 1}, {3, 1}],
      [{3, 1}, {2, 2}, {1, 3}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {3, 2}), do:
    [
      [{3, 1}, {3, 2}, {3, 3}],
      [{1, 2}, {2, 2}, {3, 2}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, whose_turn}, pieces, {3, 3}), do:
    [
      [{3, 1}, {3, 2}, {3, 3}],
      [{1, 3}, {2, 3}, {3, 3}],
      [{1, 1}, {2, 2}, {3, 3}]
    ] |> next_statuses_lines({statuses, whose_turn}, pieces)
  defp next_statuses({statuses, _whose_turn}, _pieces, _locs), do: {statuses, nil}

  defp next_statuses_lines(lines, {statuses, whose_turn}, pieces), do:
    lines
    |> Enum.reduce({statuses, whose_turn}, & next_statuses_line(&2, pieces, &1))
    # TODO: How to make squares disabled? How to reduce the correct winner_piece?

  defp next_statuses_line({statuses, whose_turn}, pieces, line) do
    {statuses, winner_piece} = cond do
      line |> Enum.all?(& Map.get(pieces, &1) == whose_turn) ->
        {
          statuses |> Map.merge(for square <- line, into: %{}, do: {square, "won"}),
          whose_turn
        }
      true ->
        {
          statuses,
          nil
        }
    end

    {statuses, winner_piece}
  end

  def handle_event(
    "move",
    %{"status" => "available",
      "loc_x" => loc_x, "loc_y" => loc_y},
    socket
  ) do
    {loc_x, _} = Integer.parse(loc_x)
    {loc_y, _} = Integer.parse(loc_y)
    IO.puts("Moved { #{loc_x}, #{loc_y} }")

    pieces =
      socket.assigns[:pieces]
      |> Map.put({loc_x, loc_y}, next_turn(socket.assigns[:whose_turn]))

    {statuses, winner_piece} =
      next_statuses({socket.assigns[:statuses], socket.assigns[:whose_turn]}, pieces, {loc_x, loc_y})

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
end
