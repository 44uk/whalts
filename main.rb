#!/usr/bin/env ruby

require "nokogiri"
require "mini_magick"
require "csv"
require "pry"
require "pp"
require 'benchmark'

Benchmark.bm() do |x|
  x.report do



opts = {
  root: "sample",
  target: "./",
  w: {
    append: true,
    scale: 0.0
  },
  h: {
    append: true,
    scale: 0.0
  },
  remove_empty: false,
  write_to: {
    indent_text: "\t",
    indent: 1
  },
  mode: :dump
}

# このスクリプトを実行した位置からみた opt[:root]
doc_root    = File.expand_path(File.join(File.dirname(__FILE__), opts[:root]))
target_root = File.join(doc_root, opts[:target])

restore_table = CSV.table(doc_root + "/dump.csv")


CSV.open(doc_root + "/dump.csv", "w") do |csv|
  csv << ["alt", "width", "height", "src", "path", "hash"]
end


p_replace = lambda do |path|
  doc = Nokogiri::HTML(open(path))

  # each img tag in page.
  doc.xpath("//img").each do |img|
    src = img["src"]

    # reject external resource
    next if /^http(s)?:/ === src

    # TODO: only supported end with extension.
    next unless /(gif|jpg|jpeg|png)$/ === src



    # move to directory containing current image
    Dir.chdir(File.dirname(path)) do |current_path|
      prepend_path = (/^\// === src) ? doc_root : current_path
      full_path = File.join(prepend_path, src)

      unless File.exists?(full_path)
        #puts "-" * 80
        #puts "File is not found: #{full_path}"
        next
      end

      # fetch size from file
      img_obj = MiniMagick::Image.new(full_path)

      # make path from document root
      doc_img_path = full_path.sub(doc_root, "")

      # get img tag attributes from tag
      img_alt = img["alt"]
      img_w   = img["width"]
      img_h   = img["height"]



      # restore mode
      if opts[:mode] == :restore
        # get dumbed info
        hash = Digest::SHA1.hexdigest("%s%s" % [doc_img_path, path])
        row = restore_table[restore_table[:hash].index(hash)]

        # overwrite width / height attributes
        if opts[:w][:scale]
          w = (img_obj[:width]  * opts[:w][:scale]).to_i
        end

        if opts[:h][:scale]
          h = (img_obj[:height] * opts[:h][:scale]).to_i
        end

        img["width"]  = w unless img["width"].nil?  && opts[:w][:append]
        img["height"] = h unless img["height"].nil? && opts[:h][:append]

        # if empty(attribute is empty value), remove the attribute.
        if opts[:remove_empty]
          img.delete("width")  if img["width"].nil?  || img["width"].empty?
          img.delete("height") if img["height"].nil? || img["height"].empty?
        end

        # overwrite alt attribute
        img["alt"] = img_alt

        # overwrite
        # TODO: unexpected change occured. (<br/> => <br>)
        open(path, "w") {|file| doc.write_html_to(file, opts[:write_to]) }
      end

      # dump mode
      if opts[:mode] == :dump
        CSV.open(doc_root + "/dump.csv", "a") do |csv|
          csv << [
            img_alt, img_w, img_h, doc_img_path, path,
            Digest::SHA1.hexdigest("%s%s" % [doc_img_path, path]) # hash for key
          ]
        end
      end

    end
  end
end

#p_replace.call "/Volumes/data/-local/276-023-shinkenzemi/s/new1/kyouzaia/challenge.html"
#exit

Dir.glob("#{target_root}/**/*.html", &p_replace)

  end
end

exit 0
