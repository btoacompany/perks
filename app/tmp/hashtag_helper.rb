=begin
class HashtagHelper
  def render_hashtag(content)
    content_words = content.split(" ")
    content_with_links = content_words.map do | word |
      if word.contains("#")
	link_to hashtag.name, hashtag_path(hashtag.name)
      else
	word
      end
    end
  end
end
=end
