#!/usr/bin/env ruby

require "optparse"
require "shellwords"
require "csv"
require "pp"
require 'benchmark'

require "nokogiri"
require "mini_magick"
require "pry"

Benchmark.bm() do |x|
  x.report do

# default options
opts = {
  mode: :dump,
  drop_if_empty: true,
  auto_sizing: true,
  root: "s",
  target: "new1/taiken",
  w: {
    append: true,
    scale: 1.0
  },
  h: {
    append: true,
    scale: 1.0
  },
  write_to: {
    indent_text: "\t",
    indent: 2
  }
}

# TODO: feature function
OptionParser.new do |opt|
  opt.on("--mode VALUE", "MODE: (dump|restore)") do |v|
    opts[:mode] = v.to_sym if /(dump|restore)/ === v
  end
  opt.on("--drop_if_empty", "Drop attribute which empty string.") do |v|
    opts[:drop_if_empty] = v if v
  end
  opt.on("--auto_sizing", "Get size from image file using ImageMagick.") do |v|
    opts[:auto_sizing] = v if v
  end
  opt.parse!(ARGV)
end



# このスクリプトを実行した位置からみた opt[:root]
app_root    = File.expand_path(File.join(File.dirname(__FILE__)))
doc_root    = File.join(app_root, opts[:root])
target_root = File.join(doc_root, opts[:target])

restore_table = CSV.table(app_root + "/dump.csv") if opts[:mode] == :restore

if opts[:mode] == :dump
  CSV.open(app_root + "/dump.csv", "w") do |csv|
    csv << ["alt", "width", "height", "src", "path", "hash"]
  end
end


p_replace = lambda do |path|
  #binding.pry
  doc = Nokogiri::HTML(open(path))

  # each img tag in page.
  doc.xpath("//img").each do |img|
    img_src = img["src"]

    # reject external resource
    next if /^http(s)?:/ === img_src

    # TODO: only supported end with extension.
    next unless /(gif|jpg|jpeg|png)$/ === img_src

    # move to directory containing current image
    Dir.chdir(File.dirname(path)) do |current_path|
      prepend_path = (/^\// === img_src) ? doc_root : current_path
      full_path = File.join(prepend_path, img_src)

      unless File.exists?(full_path)
        puts "File is not found: #{full_path}"
        next
      end

      # make path from document root
      doc_img_path = full_path.sub(doc_root, "")

      img_alt = img["alt"]
      img_w = 0
      img_h = 0
      if opts[:auto_sizing]
        img_obj = MiniMagick::Image.new(full_path)
        # get attribures from image file
        img_w = img_obj[:width]
        img_h = img_obj[:height]
      else
        # get attributes from img tag
        img_w = img["width"]
        img_h = img["height"]
      end

      # dump mode
      if opts[:mode] == :dump
        CSV.open(app_root + "/dump.csv", "a") do |csv|
          csv << [
            img_alt, img_w, img_h, doc_img_path, path,
            Digest::SHA1.hexdigest("%s%s" % [doc_img_path, path]) # hash for key
          ]
        end
      end



      # restore mode
      if opts[:mode] == :restore
        # get dumped info
        hash = Digest::SHA1.hexdigest("%s%s" % [doc_img_path, path])
        row = restore_table[restore_table[:hash].index(hash)] # find row by hash

        next if row.none?

        # no change?
        replacer = Digest::SHA1.hexdigest("%s%s%s%s" % [
          img["alt"], img["width"], img["height"], doc_img_path, path
        ])
        replacee = Digest::SHA1.hexdigest("%s%s%s%s" % [
          row[:alt], row[:width], row[:height], row[:src], row[:path]
        ])

        next if replacer == replacee

        w = row[:width]
        h = row[:height]
        alt = row[:alt]

        # overwrite width / height attributes
        if opts[:w][:scale]
          w = (img_obj[:width] * opts[:w][:scale]).to_i
        else
          w = img_obj[:width]
        end

        if opts[:h][:scale]
          h = (img_obj[:height] * opts[:h][:scale]).to_i
        else
          h = img_obj[:height]
        end

        # overwrite width / height attribute
        img["width"]  = w if ! img["width"].nil?  || opts[:w][:append]
        img["height"] = h if ! img["height"].nil? || opts[:h][:append]

        # if empty(attribute is empty value), remove the attribute.
        if opts[:drop_if_empty]
          img.delete("width")  if ! img["width"].nil?  && img["width"].empty?
          img.delete("height") if ! img["height"].nil? && img["height"].empty?
        end

        # overwrite alt attribute
        img["alt"] = alt

        # overwrite
        # TODO: unexpected change occured. (<br/> => <br>)
        open(path, "w") {|file| doc.write_html_to(file, opts[:write_to]) }
      end

    end
  end
end

Dir.glob(File.join(target_root, "/**/*.html"), &p_replace)



  end
end

exit 0
