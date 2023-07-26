defmodule Metamorphic.Cldr do
  use Cldr,
    gettext: MetamorphicWeb.Gettext,
    locales: ["en"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end
