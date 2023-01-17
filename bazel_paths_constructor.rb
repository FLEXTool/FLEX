$directory_path = `git rev-parse --show-toplevel`.strip

$header_mappings = {}

def update_imports(statement, file, header_maps)
    lines = File.readlines(file)
    modified_lines = []
    for line in lines
        if !line.start_with? statement
            modified_lines << line
            next
        end
        found_match = false
        for filename, path in header_maps
            if line.start_with? "#{statement} \"#{filename}\""
                modified_lines << line.gsub("#{statement} \"#{filename}\"", "#{statement} \"#{path}\"")
                found_match = true
                break
            end
        end
        if !found_match
            modified_lines << line
        end
    end
    File.write(file, modified_lines.join(""))
end

Dir.glob($directory_path + "/Classes/**/*.h").each do |file|
    basename = File.basename(file, "")
    $header_mappings[basename] = file.gsub($directory_path + "/", "")
end

def process_directory_imports(suffix)
    Dir.glob($directory_path + suffix).each do |file|
        update_imports("#import", file, $header_mappings)
        update_imports("#include", file, $header_mappings)
    end
end

process_directory_imports("/Classes/**/*.h")
process_directory_imports("/Classes/**/*.m")
process_directory_imports("/Classes/**/*.mm")
