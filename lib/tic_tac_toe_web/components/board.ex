defmodule TicTacToeWeb.Components.Board do
  use Surface.Component
  alias TicTacToeWeb.Components.Square

  def render(assigns) do
    ~H"""
    <div class="board-row" :for.index={{ row_idx <- [1, 2, 3] }}>
      <span :for.index={{ col_idx <- [1, 2, 3] }}>
        <Square
          click="move"
          loc_x={{ row_idx }}
          loc_y={{ col_idx }}
        />
      </span>
    </div>
    """
  end
end
