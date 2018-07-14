require "../ncurses"

module NCurses
  class Window
    ATTRIBUTES = [
      :normal, :attributes, :chartext, :color, :standout, :underline, :reverse,
      :blink, :dim, :bold, :altcharset, :invis, :protect, :horizontal, :left,
      :low, :right, :top, :vertical, :italic,
    ]

    # Create a new window with given size
    def initialize(height = nil, width = nil, y = 0, x = 0)
      max_height, max_width = NCurses.max_x, NCurses.max_y
      initialize(LibNCurses.newwin(height || max_height, width || max_width, y, x))
    end

    # Return width
    def max_x
      raise "getmaxx error" if (out = LibNCurses.getmaxx(self)) == ERR
      out
    end

    # Return height
    def max_y
      raise "getmaxy error" if (out = LibNCurses.getmaxy(self)) == ERR
      out
    end

    # Alias for `#max_x`
    def cols
      max_x
    end

    # Alias for `#max_y`
    def lines
      max_y
    end

    # Max height and width
    def max_dimensions
      {y: max_y, x: max_x}
    end

    private macro attr_mask(attributes)
      mask = LibNCurses::Attribute::NORMAL

      attributes.each do |attribute|
        mask |= case(attribute)
        {% for attribute in ATTRIBUTES %}
          when {{attribute}}
            LibNCurses::Attribute::{{attribute.upcase.id}}
        {% end %}
        else
          raise "unknown attribute #{attribute}"
        end
      end

      mask
    end

    def attr_on(*attributes)
      attr_on(attributes.to_a)
    end

    def attr_on(attributes : Array(Symbol?))
      LibNCurses.wattr_on(self, attr_mask(attributes), Pointer(Void).null)
    end

    def attr_off(*attributes)
      attr_off(attributes.to_a)
    end

    def attr_off(attributes : Array(Symbol?))
      LibNCurses.wattr_off(self, attr_mask(attributes), Pointer(Void).null)
    end

    def with_attr(*attributes, &block)
      with_attr(attributes.to_a, &block)
    end

    def with_attr(attributes : Array(Symbol?))
      attr_on(attributes)
      begin
        yield
      ensure
        attr_off(attributes)
      end
    end

    def current_color
      @current_color ||= 0
    end

    def set_color(slot)
      raise "wcolor_set error" if LibNCurses.wcolor_set(self, slot.to_i16, nil) == ERR
      @current_color = slot
    end

    def with_color(slot)
      old_color = current_color
      set_color(slot)
      yield
    ensure
      set_color(old_color || 0)
    end

    def current_background
      @current_background ||= 0
    end

    def set_background(color_pair : Int32)
      background = NCurses.color_pair(color_pair)
      LibNCurses.wbkgd(self, background)
      @current_background = background
    end

    # Get a character input
    def get_char
      raise "wgetch error" if (key = LibNCurses.wgetch(self)) == ERR
      return Key.from_value?(key) || key
    end

    # Get a character input for main loop
    def get_char(&block)
      no_timeout
      loop do
        ch = get_char
        yield ch
      end
    end

    # Enable or disable capturing function keys
    def keypad(enable)
      LibNCurses.keypad(self, enable)
    end

    # Wait for input
    def no_timeout
      LibNCurses.nodelay(self, false)
      LibNCurses.notimeout(self, true)
    end

    # Do not wait for input, return ERR
    def no_delay
      LibNCurses.notimeout(self, false)
      LibNCurses.nodelay(self, true)
    end

    # Set input timeout
    def timeout=(value)
      LibNCurses.notimeout(self, false)
      LibNCurses.wtimeout(self, value)
    end

    # Draw a character
    def add_char(chr, position = nil)
      if position
        return LibNCurses.mvwaddch(self, position[0], position[1], chr) == OK
      else
        return LibNCurses.waddch(self, chr) == OK
      end
    end

    # ditto
    def add_char(chr, pos_y, pos_x)
      LibNCurses.mvwaddch(self, pos_y, pos_x, chr) == OK
    end

    # Write a string
    def print(message, position = nil)
      if position
        return LibNCurses.mvwprintw(self, position[0], position[1], message) == OK
      else
        return "wprintw error" if LibNCurses.wprintw(self, message) == OK
      end
    end

    # ditto
    def print(message, pos_y, pos_x)
      LibNCurses.mvwprintw(self, pos_y, pos_x, message) == OK
    end

    # Move cursor to new position
    def move(y, x)
      raise "wmove error" if LibNCurses.wmove(self, y, x) == ERR
    end

    # Clear window
    def clear
      raise "wclear error" if LibNCurses.wclear(self) == ERR
    end

    # Refresh window
    def refresh
      raise "wrefresh error" if LibNCurses.wrefresh(self) == ERR
    end
  end
end
