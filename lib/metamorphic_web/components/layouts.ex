defmodule MetamorphicWeb.Layouts do
  use MetamorphicWeb, :html

  embed_templates "layouts/*"

  def favicon_link_meta(assigns) do
    ~H"""
    <!-- favicon -->
    <link rel="apple-touch-icon" sizes="57x57" href={~p"/favicon/apple-icon-57x57.png"} />
    <link rel="apple-touch-icon" sizes="60x60" href={~p"/favicon/apple-icon-60x60.png"} />
    <link rel="apple-touch-icon" sizes="72x72" href={~p"/favicon/apple-icon-72x72.png"} />
    <link rel="apple-touch-icon" sizes="76x76" href={~p"/favicon/apple-icon-76x76.png"} />
    <link rel="apple-touch-icon" sizes="114x114" href={~p"/favicon/apple-icon-114x114.png"} />
    <link rel="apple-touch-icon" sizes="120x120" href={~p"/favicon/apple-icon-120x120.png"} />
    <link rel="apple-touch-icon" sizes="144x144" href={~p"/favicon/apple-icon-144x144.png"} />
    <link rel="apple-touch-icon" sizes="152x152" href={~p"/favicon/apple-icon-152x152.png"} />
    <link rel="apple-touch-icon" sizes="180x180" href={~p"/favicon/apple-icon-180x180.png"} />
    <link rel="icon" type="image/png" sizes="192x192" href={~p"/favicon/android-icon-192x192.png"} />
    <link rel="icon" type="image/png" sizes="32x32" href={~p"/favicon/favicon-32x32.png"} />
    <link rel="icon" type="image/png" sizes="96x96" href={~p"/favicon/favicon-96x96.png"} />
    <link rel="icon" type="image/png" sizes="16x16" href={~p"/favicon/favicon-16x16.png"} />
    <link rel="manifest" href={~p"/favicon/manifest.json"} />
    <meta name="msapplication-TileColor" content="#ffffff" />
    <meta name="msapplication-TileImage" content="/ms-icon-144x144.png" />
    <meta name="theme-color" content="#ffffff" />
    """
  end
end
