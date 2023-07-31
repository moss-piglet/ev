defmodule MetamorphicWeb.PageController do
  use MetamorphicWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, page_title: "Welcome", layout: false)
  end
end
