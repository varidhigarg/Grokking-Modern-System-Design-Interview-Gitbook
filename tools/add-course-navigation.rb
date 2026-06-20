require "pathname"

root = Pathname.new(Dir.pwd)
summary = (root + "SUMMARY.md").read

lessons = summary.scan(/^\s*\*\s+\[([^\]]+)\]\(([^)]+\.md)\)\s*$/).map do |title, file_path|
  { title: title, file_path: file_path }
end

ordered = [
  { title: "Course Index", file_path: "README.md" },
  *lessons.reject { |lesson| lesson[:file_path] == "README.md" },
]

nav_start = "<!-- COURSE_NAV_START -->"
nav_end = "<!-- COURSE_NAV_END -->"
nav_pattern = /\n?#{Regexp.escape(nav_start)}[\s\S]*?#{Regexp.escape(nav_end)}\n?/

def relative_link(from_file, to_file)
  from_dir = Pathname.new(from_file).dirname
  Pathname.new(to_file).relative_path_from(from_dir).to_s
end

def split_frontmatter(content)
  return ["", content] unless content.start_with?("---\n")

  ending = content.index("\n---\n", 4)
  return ["", content] unless ending

  [content[0, ending + 5], content[(ending + 5)..-1]]
end

ordered.each_with_index do |lesson, index|
  file = root + lesson[:file_path]
  next unless file.exist?

  original = file.read
  cleaned = original.gsub(nav_pattern, "\n").rstrip
  frontmatter, body = split_frontmatter(cleaned)

  previous_lesson = index.positive? ? ordered[index - 1] : nil
  next_lesson = ordered[index + 1]
  previous_link = previous_lesson ? "[Previous: #{previous_lesson[:title]}](#{relative_link(lesson[:file_path], previous_lesson[:file_path])})" : "Previous: none"
  next_link = next_lesson ? "[Next: #{next_lesson[:title]}](#{relative_link(lesson[:file_path], next_lesson[:file_path])})" : "Next: none"
  index_link = relative_link(lesson[:file_path], "README.md")

  nav = <<~NAV.strip
    #{nav_start}
    #{previous_link} | [Course Index](#{index_link}) | #{next_link}
    #{nav_end}
  NAV

  content = if lesson[:file_path] == "README.md"
    "#{body.lstrip}\n\n#{nav}\n"
  elsif frontmatter.empty?
    "#{nav}\n\n#{body.lstrip}\n\n#{nav}\n"
  else
    "#{frontmatter}\n#{nav}\n\n#{body.lstrip}\n\n#{nav}\n"
  end

  file.write(content)
end

puts "Updated navigation in #{ordered.length} markdown files."
