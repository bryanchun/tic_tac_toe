# TicTacToe

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

---

## Steps

### 1. Init

```bash
# ... Install elixir, iex, mix on your platform first
iex -v

# Install Hex and Phoenix
mix archive.install hex phx_new

# Create new project: Phoenix LiveView
mix phx.new tic_tac_toe --live
cd tic_tac_toe

# (Optional) Init database table
# ... Install postgresql on your platform first
# Update the password for the default user 'postgres' for Ecto to authenticate
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
mix ecto.create

# Run development server
mix phx.server
```