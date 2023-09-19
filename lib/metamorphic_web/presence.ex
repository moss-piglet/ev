defmodule MetamorphicWeb.Presence do
  use Phoenix.Presence,
    otp_app: :metamorphic,
    pubsub_server: Metamorphic.PubSub
end
