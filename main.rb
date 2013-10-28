#!/usr/bin/env ruby

require "nokogiri"
require "mini_magick"
require "pry"

opts = {
  root: "sample",
  target: "course",
  w: {
    append: true,
    scale: 1.0
  },
  h: {
    append: true,
    scale: 1.0
  },
  remove_empty: false,
  write_to: {
    indent_text: "\t",
    indent: 1
  }
}


doc_root    = File.expand_path(File.join(File.dirname(__FILE__), opts[:root]))
target_root = File.join(doc_root, opts[:target])

p_replace = lambda do |path|
  doc = Nokogiri::HTML(open(path))

  doc.xpath("//img").each do |img|
    src = img["src"]

    # TODO: not unsupported versioning like foo.png?ver=12345
    next unless /(gif|jpg|jpeg|png)$/ === src

    # reject external resource
    next if /^http(s)?:/ === src

    Dir.chdir(File.dirname(path)) do |current_path|
      prepend_path = (/^\// === src) ? doc_root : current_path
      full_path = File.join(prepend_path, src)

      unless File.exists? full_path
        puts path
        puts src
        puts full_path
        puts "-----------"
        next
      end



      # overwrite width / height attributes
      img_obj = MiniMagick::Image.new(full_path)
      if opts[:w][:scale]
        w = (img_obj[:width]  * opts[:w][:scale]).to_i
      end

      if opts[:h][:scale]
        h = (img_obj[:height] * opts[:h][:scale]).to_i
      end

      img["width"]  = w unless img["width"].nil?  && opts[:w][:append]
      img["height"] = h unless img["height"].nil? && opts[:h][:append]



      # if emoty(attribute is empty value), remove the attribute.
      if opts[:remove_empty]
        # TODO: how can I remove attribute?
        img.delete("width")  if img["width"].nil?  || img["width"].empty?
        img.delete("height") if img["height"].nil? || img["height"].empty?
      end
      # overwrite alt attribute



      # overwrite
      open(path, "w") {|file| doc.write_html_to(file, opts[:write_to]) }
    end
  end
end

#p_replace.call "/Volumes/data/-local/276-023-shinkenzemi/s/new1/kyouzaia/challenge.html"
#exit

Dir.glob("#{target_root}/**/*.html", &p_replace)

exit 0








Dir.glob("#{target_root}/**/*.html") do |path|
  doc = Nokogiri::HTML(open(path))

  doc.xpath("//img").each do |img|
    src = img["src"]

    # TODO: not unsupported versioning like foo.png?ver=12345
    next unless /(gif|jpg|jpeg|png)$/ === src
    next if /^http(s)?:/ === src

    Dir.chdir(File.dirname(path)) do |current_path|
      prepend_path = (/^\// === src) ? doc_root : current_path
      full_path = File.join(prepend_path, src)

      unless File.exists? full_path
        puts path
        puts src
        puts full_path
        puts "-----------"
        next
      end

      # overwrite width / height attributes
      img_obj = MiniMagick::Image.new(full_path)
      w = (img_obj[:width]  * opts[:w][:scale]).to_i
      h = (img_obj[:height] * opts[:h][:scale]).to_i

      img["width"]  = w unless img["width"].nil?  && opts[:w][:append]
      img["height"] = h unless img["height"].nil? && opts[:h][:append]

      # if emoty(attribute is empty value), remove the attribute.
      if opts[:remove_empty]
        img["width"]  = nil if img["width"].empty?
        img["height"] = nil if img["height"].empty?
      end

      # overwrite alt attribute

      # overwrite
      open(path, "w") {|file| doc.write_html_to file }
      break
    end

    break
  end
  break
end
