after_start do
  unless summary.nil?
    text = summary.strip.gsub(/^#+ *(.+)/){ $1.upcase }.gsub(/<(http.+)>/, '\\1')
    puts "\n#{'-' * @column_size}\n\n#{text}\n\n#{'-' * @column_size}\n\n"
  end
end
