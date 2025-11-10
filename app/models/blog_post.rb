class BlogPost < ApplicationRecord
    validates :title, :slug, presence: true
    validates :slug, uniqueness: true
  
    enum status: { draft: 0, published: 1, archived: 2 }
  
    before_save :generate_slug
  
    def self.generate_from_ai(title, keywords = [])
      post = new(title: title, keywords: keywords.join(','))
      post.status = :draft
      post.save
      post
    end
  
    private
  
    def generate_slug
      self.slug = title.parameterize if title.present?
    end
  end
  