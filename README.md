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

Stepping through the [Guides](https://hexdocs.pm/phoenix/overview.html)


### 0. VSCode extensions setup

- `vscode-elixir` for syntax highlighting
- `ElixirLS` from https://github.com/elixir-lsp/vscode-elixir-ls
  - Debugging server crash by fixing elixir installation: https://github.com/elixir-lsp/vscode-elixir-ls/issues/134#issuecomment-678733850
  - Then we have "Go to implementation"!
  - More intro at https://thinkingelixir.com/elixir-in-vs-code/


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

### 2. Understand the framework

#### Directory structure

- `lib/tic_tac_toe/`: stores business logic, effectively the "Model" in MVC.
  - `application.ex` defines the application to run in the end of the day - an Elixir Application (the need to define these has nothing to do with Phoenix)
  - Application contains services. Services start in the defined order, and terminate in the reverse order.
  - `repo.ex` is the database connection interface, handles choice of database etc.
- `lib/tic_tac_toc_web/`: exposes business logic to the world (e.g. through a web app), effectively the "View" and "Controller" in MVC.
  - See `controllers`, `templates`, `views`.
  - `endpoint.ex` is the entry point for incoming (HTTP) requests from clients at http://localhost:4000, and will hit the router.
  - `router.ex` defines how to dispatch a request to a controller using rules.
  - A controller then uses templates and views to render a response (HTML page) back to the client.
  - `telemetry.ex` is for collecting metrics and sending monitoring events for the application. This file defines and implements the Supervisor needed to for telemetry to happen.
  - `gettext.ex` provides i18n.


#### Request life-cycle

- When your browser accesses http://localhost:4000/, it sends a HTTP request (Verb + Path) to whatever service is running on that address: in this case our Phoenix application.
  - e.g. http://localhost:4000/hello/world	-> GET	/hello/world
- Add a new page
  1. Add a new route
    - ```elixir
      get "/", PageController, :index
      ```
    - translates to: all GET requests to the "/" path -> handled by `index` function of the `PageController` controller.
    - Add a line by choosing the Verb and Path. The controller + function are added right after.
  2. Add a new controller
    - We need a module e.g. `TicTacToeWeb.HomeController` with an action/function `TicTacToeWeb.HomeController.index`.
    - `conn` is a struct, it describes the request with lots of data.
    - `params` is request parameters. Separated out from the request as add-ons and optional.
    - Here the controller "by default" expects a similarly named view to pass on
      - Views are modules responsible for rendering.
      - `TicTacToeWeb.HomeView` is the expected view module's name by this framework convention.
    - ```elixir
      render(conn, "index.html")

      # or: for Phoenix not to expect a similarly named view but dispatch using "Accept Headers"
      render(conn, :index)
      ```
  3. Add a new view
    - To make our lives easier, we often use similarly named template files for creating the to-be-rendered HTML pages.
    - Add a new template
      - Add it to `lib/tic_tac_toe_web/template/home/index.html.eex` in this case.
      - Template files are named under the convention `NAME.FORMAT.TEMPLATING_LANGUAGE`
      - where format is usually `html` and templating language is usually `eex`, which is Embedded Elixir that ships built-in with Elixir.

#### Plug

- `Plug` is the HTTP-layer component we expected to primarily manipulate at this layer.
  - Spec/abstraction/interface for composing modules/connection adapters in between web apps.
- Every steps of the request life-cycle involves Plugs, in fact all the Endpoints, Routers, Controllers are interally Plugs.
- Plug's idea: Unify the concept of "connection".
- Flavor: Function Plugs
  - ```elixir
    @spec fun(Plug.Conn, any) :: Plug.Conn
    def fun(conn, _opts) do
      ...
      conn
    end

    # In endpoint
    plug :fun
    ```
- Flavor: Module Plugs
  - Needs to `import Plug.Conn` and implement `init/1` and `call/2` (same as function plug)
  - ```elixir
    # In router
    plug TicTacToeWeb.Plugs.Locale, "en"
    ```
- Where to plug
  - Endpoint
    - Add at top-level.
    - A lot of good defaults are placed already at project generation time.
    - Feel free to add custom logic to make certain plugs take effect conditionally, e.g. only for dev.
  - Router
    - Add in `pipeline`s.
    - Once a route matches, all the plugs of the pipeline declared usage with `pipe_through :pipeline1` will be executed.
    - Pipelines are also* Plugs.
  - Controller
    - Add at top-level.
    - Allows for rooute/controller-specific request processing.
  - Plugs for composition: Railway programming
    - Without Plugs, e.g. in a controller, we may need to add verbose custom (often inline) logic checks in `show/2`.
    - With Plugs, we can just define-and-pick/sequence the request transforms needed, so it flattens the previously nested code.
      - If the check using `conn` is a success, often we just `assign(conn, :some_key, :some_value)` as proof/for propagation.
      - If this check failed, it usually goes like
        ```elixir
        conn |> put_flash(:info, "<error message>") |> redirect(to: "/") |> halt()
        ```
      - `halt/0` will stop Plugs from executing the next Plug.
    - Plugs effectively compose failable operations in a sequence.


#### Routing

- 
