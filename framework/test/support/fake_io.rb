# A byte-string stand-in for a socket: gets and read(n) as IO answers them.
# Spinel's StringIO does not link on this machine (docs/CATALOG.md K-009).
class FakeIO
  def initialize(data)
    @data = data
    @pos = 0
  end

  def gets
    return nil if @pos >= @data.size
    newline = @data.index("\n", @pos)
    stop = newline.nil? ? @data.size : newline + 1
    line = @data[@pos, stop - @pos]
    @pos = stop
    line
  end

  def read(n)
    return nil if @pos >= @data.size
    chunk = @data[@pos, n]
    @pos += chunk.size
    chunk
  end
end
