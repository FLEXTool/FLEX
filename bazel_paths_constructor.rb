directory_path = `git rev-parse --show-toplevel`.strip

header_mappings = {}

def update_imports(file, header_maps)
    lines = File.readlines(file)
    modified_lines = []
    for line in lines
        if !line.start_with? "#import"
            modified_lines << line
            next
        end
        found_match = false
        for filename, path in header_maps
            if line.start_with? "#import \"#{filename}\""
                modified_lines << line.gsub("#import \"#{filename}\"", "#import \"#{path}\"")
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

Dir.glob(directory_path + "/Classes/**/*.h").each do |file|
    basename = File.basename(file, "")
    header_mappings[basename] = file.gsub(directory_path + "/", "")
end

Dir.glob(directory_path + "/Classes/**/*.h").each do |file|
    update_imports(file, header_mappings)
end

Dir.glob(directory_path + "/Classes/**/*.m").each do |file|
    update_imports(file, header_mappings)
end

Dir.glob(directory_path + "/Classes/**/*.mm").each do |file|
    update_imports(file, header_mappings)
end
