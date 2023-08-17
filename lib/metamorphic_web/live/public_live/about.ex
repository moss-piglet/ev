defmodule MetamorphicWeb.PublicLive.About do
  @moduledoc false
  use MetamorphicWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white py-24 sm:py-32">
      <div class="mx-auto max-w-7xl px-6 lg:px-8">
        <div class="mx-auto max-w-2xl space-y-16 divide-y divide-gray-100 lg:mx-0 lg:max-w-none">
          <div class="grid grid-cols-1 gap-x-8 gap-y-10">
            <div>
              <h2 class="text-3xl font-bold tracking-tight text-zinc-900">About Us</h2>
              <p class="mt-4 leading-7 text-zinc-600">We're a small, people focused team dedicated to providing a (better) way to connect and share online.</p>
            </div>
            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:col-span-2 lg:gap-8">
              <span class="group">
                <div class="group-hover:bg-brand-50 sm:group-hover:scale-105 transition rounded-2xl bg-gray-50 p-10">
                  <h3 class=" text-base font-semibold leading-7 text-brand-600 inline-flex items-center align-middle">
                    <.icon
                      name="hero-hand-thumb-up-solid"
                      class="h-5 w-5 mr-1 inline-flex items-center align-middle"
                    /> Small tech
                  </h3>
                  <dl class="mt-3 space-y-1 text-sm leading-6 text-zinc-600">
                    <div class="mt-1">
                      <p>
                        We're not interested in chasing venture capital or IPO-sized fortunes — we're customer focused and proudly bootstrapped.
                      </p>
                    </div>
                  </dl>
                </div>
              </span>
              <span class="group">
                <div class="group-hover:bg-brand-50 sm:group-hover:scale-105 transition rounded-2xl bg-gray-50 p-10">
                  <h3 class=" text-base font-semibold leading-7 text-brand-600">
                    <.icon name="hero-eye-slash-solid" class="h-5 w-5 mr-1 inline-flex items-center" />
                    Privacy by design
                  </h3>
                  <dl class="mt-3 space-y-1 text-sm leading-6 text-zinc-600">
                    <div class="mt-1">
                      <p>
                        We're not interested in selling or harvesting your data. We care about making a service that helps you (feel better) live easier.
                      </p>
                    </div>
                  </dl>
                </div>
              </span>
            </div>
          </div>
        </div>

        <h2 class="mt-16 text-2xl font-bold tracking-tight text-gray-900">Our story (so far)</h2>
        <span class="space-y-6 leading-6">
          <p class="mt-6">Metamorphic started with Mark and is supported by parent company Moss Piglet Corporation (co-founded by Mark, Ryan, and Mark's dad), with the goal to provide an uncompromisingly simple way to connect and share online — free from the surveillance world of today.</p>

          <p>We felt that you shouldn't have to be marginalized, harvested, drained, or otherwise rendered <em>less</em> just to get online and connect with others. So after several years of iterations, we've finally launched with the streamlined version you see here today.</p>

          <p>And while it's currently free, we will probably have to come up with a way to cover the costs of building and maintaining this service — like a subscription or something (we won't ever sell your data).</p>

          <p>It's been a transformative experience pushing back against big tech and building what we believe to be a better alternative for people.</p>

          <p class="text-zinc-500"><em>We hope you join us on this road to a better (online) life.</em></p>

          <p>Mark & Ryan</p>
          Creator & Co-founders of Metamorphic / Moss Piglet
        </span>
      </div>

    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
