class String
  def undent
    gsub /^(?!$)#{self[/\A(\s+)/, 1]}/, ''
  end
end