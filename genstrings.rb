#!/usr/bin/env ruby

excluded_directories = ['Pods', 'Carthage']
excluded_files = []

regex = /"((?:[^"\\]|\\.)*)"[\s]*\.[\s]*localized\([\s]*comment:[\s]*"((?:[^"\\]|\\.)*)"/
exists = {}

Dir['./**/*.swift'].each do |file|
    next if excluded_directories.any? { |excluded_directory| file.include? "/#{excluded_directory}/" }
    next if excluded_files.any? { |excluded_file| file.end_with? "/#{excluded_file}" }

    IO.read(file).scan(regex).each do |match|
        next if exists[match.first]
        puts "\n/* #{match.last} */\n"
        puts "\"#{match.first}\" = \"#{match.first}\";\n"
        exists[match.first] = true
    end
end
