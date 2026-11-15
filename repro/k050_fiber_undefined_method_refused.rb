# K-050: an undefined method on a Fiber is refused at compile time ("unsupported call"); CRuby raises NoMethodError at run time, as Spinel does for [1].tag
f = Fiber.new { }
p((f.tag rescue [$!.class, $!.message]))
