require 'webrick'

MAPS_DIR = File.expand_path("../../maps")
ASSETS_DIR = File.expand_path("../../assets")

puts "Loading maps from " + MAPS_DIR

class Viz < WEBrick::HTTPServlet::AbstractServlet

  def do_GET(request, response)
    root, map_name, moves = request.path.split("/")

    map = read(map_name, moves)

    response.status = 200
    response['Content-Type'] = "text/html"
    response.body = render(map)
  end

  def read(map_name, moves)
    File.readlines(MAPS_DIR + "/" + map_name + ".map")
  end

  def render(map)
    html = header
    map.each do |row|
      html << "\n<tr>\n"
      row.each_char do |cell|
        css = css_class_for(cell)
        html << "  <td class='#{css}'></td>\n"
      end
      html << "</tr>\n"
    end
    html << footer
    html
  end

  def css_class_for(cell)
    case cell
    when "R"
      'robot'
    when "*"
      'rock'
    when '.'
      'earth'
    when '#'
       'wall'
    when 'L'
        'lift-closed'
    when 'O'
        'lift-open'
    when ' '
        'empty'
    when '\\'
        'lambda'
    end
  end

  def header
    "<html><head><link rel='stylesheet' type='text/css' href='/assets/base.css' /></head><body><table>"
  end

  def footer
    "</table></body></html>"
  end
end

if $0 == __FILE__ then
  server = WEBrick::HTTPServer.new(:Port => 8000)
  server.mount "/", Viz
  server.mount "/assets", WEBrick::HTTPServlet::FileHandler, ASSETS_DIR
  trap "INT" do server.shutdown end
  server.start
end
