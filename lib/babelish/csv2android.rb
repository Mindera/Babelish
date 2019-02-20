require 'nokogiri'

module Babelish
  class CSV2Android < Csv2Base
    attr_accessor :file_path

    def initialize(filename, langs, args = {})
      super(filename, langs, args)

      @file_path = args[:output_dir].to_s
      @output_basename = args[:output_basename].to_s
    end

    def language_filepaths(language)
      require 'pathname'
      output_name = "strings.xml"
      output_name = "#{@output_basename}.xml" unless @output_basename.empty?
      region = language.region.to_s.empty? ? "" : "-#{language.region}"
      filepath = Pathname.new(@file_path) + "values-#{language.code}#{region}" + output_name
      return filepath ? [filepath] : []
    end

    def process_value(row_value, default_value)
      value = super(row_value, default_value)
      # if the value begins and ends with a quote we must leave them unescapted
      if value.size > 4 && value[0, 2] == "\\\"" && value[value.size - 2, value.size] == "\\\""
        value[0, 2] = "\""
        value[value.size - 2, value.size] = "\""
      end
      value.to_utf8
    end

    def process_row(resources_node, row_key, row_value, comment = nil)
      unless comment.to_s.empty?
        comment_node = Nokogiri::XML::Comment.new(resources_node, comment)
        resources_node.add_child(comment_node)
      end
      string_node = Nokogiri::XML::Node.new("string", resources_node)
      string_node["name"] = row_key
      string_node.content = row_value
      resources_node.add_child(string_node)
    end

    def hash_to_output(content = {})
      document = Nokogiri::XML::Document.new
      if content && content.size > 0
        resources_node = Nokogiri::XML::Node.new("resources", document)
        document.add_child(resources_node)
        content.each do |key, value|
          comment = @comments[key]
          process_row(resources_node, key, value, comment)
        end
      end
      return document.to_xml
    end

    def extension
      "xml"
    end
  end
end
