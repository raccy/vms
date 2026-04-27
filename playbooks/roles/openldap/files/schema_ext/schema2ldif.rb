#!/bin/env ruby
# schema2ldif.rb
# Copyright (c) 2015,2022 IGARASHI Makoto (raccy)
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require "pathname"

def add_entry(io, entry, line_length = 78)
  entry = entry.gsub(/\s+/, " ")
  if entry.size <= 78
    io.puts entry
  else
    _, first, entry = entry.split(/^(.{1,#{line_length}})/)
    io.puts first
    entry.scan(/.{1,#{line_length - 1}}/) do |remain_line|
      io.write " "
      io.puts remain_line
    end
  end
end

def schema2ldif(name, schema, ldif, line_length = 78)
  schema.open("r") do |schema_io|
    ldif.open("w") do |ldif_io|
      ldif_io.write <<~ENTRY
        dn: cn=#{name},cn=schema,cn=config
        objectClass: olcSchemaConfig
        cn: #{name}
      ENTRY
      entry = nil
      while (line = schema_io.gets)
        line.chomp!
        line.sub!(/\#.*$/, "")
        line.rstrip!
        next if line.empty?

        case line
        when /^attributetype(\s.*)?$/i
          add_entry(ldif_io, entry, line_length) if entry
          entry = ""
          entry << "olcAttributeTypes: "
          entry << Regexp.last_match(1) if Regexp.last_match(1)
        when /^objectclass(\s.*)?$/i
          add_entry(ldif_io, entry, line_length) if entry
          entry = ""
          entry << "olcObjectClasses: "
          entry << Regexp.last_match(1) if Regexp.last_match(1)
        when /^(\s.*)$/i
          raise "not start line: #{line}" if entry.nil?

          entry << Regexp.last_match(1)
        else
          raise "invalid line: #{line}"
        end
      end
      add_entry(ldif_io, entry, line_length) if entry
    end
  end
  true
end

if $0 == __FILE__
  if ARGV.empty?
    warn "Usage: #{$0} schema_files ..."
    exit 1
  end
  ARGV.each do |schema_file|
    puts "convert: #{schema_file}"
    $stdout.flush
    schema_path = Pathname(schema_file)
    unless schema_path.file?
      puts "-> NG: schema file not found."
      next
    end
    name = schema_path.basename(".*").to_s
    ldif_path = schema_path.dirname / (name + ".ldif")
    if ldif_path.exist?
      warn "ldif file exists, overwrite!"
      # puts "-> NG: ldif file exists."
      # next
    end
    begin
      if schema2ldif(name, schema_path, ldif_path)
        puts "-> OK"
      else
        puts "-> NG"
      end
    rescue StandardError => e
      puts "->ERR: #{e}"
    end
  end
end
