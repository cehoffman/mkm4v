class String
  def undent
    gsub /^(?!$).{#{slice(/^\s+/).length}}/, ''
  end
end