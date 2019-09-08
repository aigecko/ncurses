require "./../src/ncurses"

NCurses.start
NCurses.cbreak
NCurses.no_echo
NCurses.no_timeout
NCurses.keypad true
NCurses.mouse_mask(NCurses::Mouse::AllEvents | NCurses::Mouse::Position)

NCurses::Key.each do |key|
  NCurses.print(key.to_s)
end
NCurses.print "\n\nPress something!"

NCurses.refresh

NCurses.get_wchar do |ch|
  NCurses.clear
  NCurses.print(ch.inspect, 0, 0)
  if ch.is_a?(Char)
    NCurses.print("#{ch} char", 1, 0)
  end
  NCurses.refresh
  break if ch == 'q' || ch == '離'
  if ch == NCurses::Key::Mouse
    mouse = NCurses.get_mouse
    NCurses.print(mouse.to_s, 1, 0)
  end
  NCurses.print "\n\nPress q to quit"
end

NCurses.end
