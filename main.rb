#!/usr/bin/env ruby

require "nokogiri"
require "mini_magick"

require "pry"

g_options = {
  w: {
    append: true,
    scale: 0.5
  },
  h: {
    append: true,
    scale: 0.5
  },
  remove_empty: true,
}

Dir.glob("sample/**/*.html") do |path|
  doc = Nokogiri::HTML(open(path))

  doc.xpath("//img").each do |img|
    puts img["width"] = 1000

    path
    full_path = img["src"]

    #img = MiniMagick::Image.new(full_path)
    img = MiniMagick::Image.new("./sample/course/baby/2011/images/bg_form_01.gif")
    w = (img[:width]  * g_options[:w][:scale]).to_i
    h = (img[:height] * g_options[:h][:scale]).to_i


    binding.pry
    break


  end


  open(path, "w") {|f| doc.write_html_to f }

  #binding.pry
  break

end







