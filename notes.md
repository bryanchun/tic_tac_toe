## Phoenix Guide notes

My notes for going through the [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html).


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

- What routes do: match HTTP requests -> controller actions, specify request pipeline transforms under a scope, wire up channel handlers
  - `get` is a macro, similar macros exist for the rest of HTTP verbs (post, put, patch, delete, options, connect, trace, head)
- Examine by `mix phx.routes`
- `resources` macro will span a standard matrix of HTTP verbs, paths (by naming conventions), and controller actions (as a shortcut)
  - `:only` and `:except` list options to opt-in/out that default list, i.e. :index, :edit, :new, :show, etc. This can allow for read-only, no-delete paths generated for you
- Path helpers
  - Functions, defined dynamically in `Router.Helpers` module for an application. Full path is `MyProjectNameWeb.Router.Helpers.whatever_path`
  - ```elixir
    HelloWeb.Router.Helpers.page_path(HelloWeb.Endpoint, :index) # "/"

    # So that in the template we can generate links to the page root
    <%= link "Welcome Page!", to: Routes.page_path(@conn, :index) %>
    ```
  - Aliased (`alias TicTacToeWeb.Router.Helper, as: Routes`) in `use TicTacToeWeb, :view` in `view/0` by default
  - This is a generic function for getting the path string for whatever request action, query params under a controller
  - `whatever_url` for getting the full url (host, port, proxy port, and SSL information)
  - Passing the `Endpoint` is like passing the state for evaulation. Prefer `conn` or `@conn` though.
- Nested resources is supported
  - ```
    resources "/users", UserController do
      resources "/posts", PostController
    end

    # For a 
    # user_post_path  GET     /users/:user_id/posts           HelloWeb.PostController :index

    # using
    user_post_path
    ```
- Scoped routes
  - Grouping routes under a common prefix or/and set of plugs
  - Good example: the admin namespace - `scope "/admin", HelloWeb.Admin, as: :admin do ...` gives "/admin/reviews/1234/edit" vs the normal "/reviews/1234/edit"
  - `:as` option to add back the wanted prefix in path helpers, so that we can generate those admin paths
  - The end effect is: "how every route, path helper and controller is properly namespaced."
  - We can further nest scopes arbitrarily technically...
  - Scopes can even share the paths so long as the routes do not duplicate. Will get a warning if there is a duplicate path.
- Pipelines
  - Or what is `pipe_through :browser`
  - The set of plugs that are attached to scoped, so that once a route matches a request, (Phoenix) will invoke all the plugs defined in all pipelines under that route/scope. E.g. "/".
  - Phonenix defines 2 built-in pipelines: `:browser` and `:api`. They each prepare for routes to render response targetting the browser/api call.
  - `:browser` has 5 plugs defined for you like `plug :accepts, ["html"]`; `:api` only has plug :accepts, ["json"]` for now.
  - They match roughly to eDSLs for HTTP header configurations
  - So `pipe_through :browser` really just let a scope specify that the request handler is chosen to be the declared-above one geared towards browser responses
  - Execution model
    1. Server accepts request
    2. Invoke any plugs on the router
    3. Try to match verb-and-path, this already considers all the routes/resources defined inside scopes
    4. If there's a match, pipe that request through the chosen pipeline of plugs, then dispatch to the controller's action (i.e. that handler function in the module)
    5. Else no matches, raise 404 (no pipeline invoked)
  - `pipe_through` marco supports a list of pipelines
  - But since pipelines are still plugs (closure), we might as well defined a wrapping pipeline and pipe through that pipeline of pipelines
- Forward
  - `Phoenix.Router.forward/4` sends matching requests to yet another (external) module plug. We can use this like plugs in the Router or in a scope.


#### Controllers

- Acting as intermediary modules
  - Functions in controllers are called actions
  - Responsibility: from matched response dispatched call, to sourcing all the neccessary data and doing all the other necessary things, finally to output by rendering a template (in view) or returning a response (which is also a kind of a view)
  - Controllers are plugs
- Actions
  - We can name it any name as long as the action matches in the routes
  - But there are conventions with common case: index, show, new, create, edit, update, delete
  - First parameter is always `conn`, a struct containing all the request information - and it also comes from Plug the middleware framework
  - Second parameter is `params`, a map of more dynamic parameters passed with the request. Good practice is to pattern match by map keys
- Rendering
  - Simplest: plain text with `text/2` - without any other HTML formatting
  - JSON response: `json/2`
  - HTML without a view: `html/2`, with String (not EEx) requires escaping (`Plug.HTML.html_escape/1`)
  - These are light: require neither Phoenix Views or Templates to render
  - Most typically we use Phoenix Views using `render/3`
    - Precondition: Controller and View and Template directory share the same root name (framework so demands), in which the template must have a `<action>.html.eex` such that this is possible: `render(conn, "show.html", messenger: messenger)`
    - Pass parameters by the third keyboard list parameter or skip it and modify assigns in the passed `conn` by
      ```elixir
      conn
      |> Plug.Conn.assign(:messenger, messenger)  # Phoenix.Controller imported `assign` already so we can just use assign/3
      |> render("show.html")
      ```
- Rendering: Assigning layouts
  - Special subset of templates living in `lib/tic_tac_toc_web/templates/layout`
  - The generated template has generated one for us by default: `app.html.eex`
  - This is paired with a View (of course!) called `LayoutView`
  - No layout at all or using a different layout
    - `Phoenix.Controller` has `put_layout/2`, second parameter is a layout basename (String) or `false` to disable layouts
- Rendering: Dynamically overriding the rendering format between text/json/html
  - Add a template for this other format, `lib/tic_tac_toe_web/templates/<view basename>/<action>.<insert format here>.eex` like `index.text.eex`
  - Need to enable this in the `:browser` pipeline's `plug :accepts ["html", "text"]`
  - Need to change the `render` call to using an atom like `render(conn, :index)` instead of that specific file path name
  - Then call with query param `?_format=text`, which `Phoenix.Controller.get_format` will grab and handle
- Rendering: more
  - Compose plugs to make direct (error) responses: `Plug.Conn.send_resp/3` like `conn |> send_resp(201, "<body>")`
  - `Plug.Conn.put_resp_content_type/2` to set the content type like "text/plain". Usable in `render` pipes as well. For example with a "text/xml" we need to add a `index.xml.eex`
  - `Plug.Conn.put_status/2` to set HTTP response code, use 3-digit number or a provided atom
- Redirection
  - Use case: redirect to a new URL after having visited some view/url, like after creating something we want to show a success/failure page
  - Phoneix differentiates between redirecting to an internal path in the application, and an external URL
  - `redirect/2` like `redirect(conn, to: "/path")` (preferred that we compose using path helpers - they also* returns the path as String) or `redirect(conn, external: "https://elixir-lang.org/")`
  - The network tab in the brower's developer inspector will show among others 2 requests made, one is 302 redirect, another is 200.
- Flash messages
  - `put_flash/3` and `get_flash/2` and `clear_flash/1`
  - We can use whatever keys in the second parameter so long the usage is consistent, but the convention is `:info` and `:error`
- Action fallback
  - Centralizes error handling in plug call chain when an action fails to return a connection struct
  - First attempt: use Elixir's `with` expression to cascade failures in the `else` pattern matches
  - For example, render 403 and 404 pages depending on the error from plugs
  - Poor reuse: needed to redefine this each controller
  - Let's define a module plug to handle these specifically
  - Just implement a new Controller (since controllers are plugs), then pattern-match the `call` like `def call(conn, {:error, :not_found}) do ... end` and `def call(conn, {:error, :unauthorized}) do ... end`
  - Then add the controller plug `action_fallback TicTacToeWeb.MyFallbackController` and still use the `with` in the action, only that we can omit the `else` branch altogether with his fallback controller

#### Views and templates

- Views is the usual (but not a must) way to build responses to requests, and Templates is the usual (but not a must) way to build a View's response
- Strong naming convention from controllers to views to the templates required (by the framework)
  - > The PageController requires a PageView to render templates in the lib/hello_web/templates/page directory.
  - While customizable, better follow Phoenix's convention
- 3 view modules generated: ErrorView, LayoutView, and PageView
- Everything function in scope in a view, the corresponding template can just reference and call inside
  - Because templates will be compiled into functions that live inside the respective view module. And since they are in the same module, we can skip the full module path when calling but only call toplevel.
  - `use TicTacToeWeb, :view` provides a good set of defaults
  - User-defined functions in a view like `title/0` can just be called as `<title><%= title() %></title>`
  - EEx have `<%= some_expr %>` to execute expressions then interpolate, e.g. `<%= if ... do %>` and `<%= for ... do %>`, note that the `<% else %>` and `<% end %>` are not *expressions* to capture but part of the if/for expressions, so do not capture them but write it using these inline tags.
- Template compilation
  - Simply render function clauses expanded (macros?)
  - Remember how we call `render` in controller actions? These effectively becomes implementations for each render call
  - > At compile-time, Phoenix precompiles all *.html.eex templates and turns them into render/2 function clauses on their respective view modules. At runtime, all templates are already loaded in memory. There's no disk reads, complex file caching, or template engine computation involved.
- We can also manually render templates
  - like `{:safe, ["This is the message: ", "Hello from IEx!"]} = Phoenix.View.render(HelloWeb.PageView, "test.html", message: "Hello from IEx!")`
  - So then we can render shared views and templates within a template by `<%= render("test.html", message: "Hello from sibling template!") %>` for rendering a template in the same View, or `<%= render(HelloWeb.PageView, "test.html", message: "Hello from layout!") %>` if the view is changed.
  - Layouts do this as well, by assigning this `@inner_content` just by convention
- Rendering JSON
  - Phoenix has great support for this beyond just `json/2` but with `render` and chopping off smaller functions that render smaller maps/lists
    - Just return a map/list in the `def render("index.json", %{key1: value1}), do: %{ans1: val1, ...}`
    - "recursively" call smaller rendering components carrying custom key/"schema" defined like `def render("page.json", %{page: page}), do: %{title: page.title}` by `render_one(page, HelloWeb.PageView, "page.json")` and `render_many/3` depending on it's an object or an array of objects to render
    - Good for breaking up concerns of generating the JSON response

