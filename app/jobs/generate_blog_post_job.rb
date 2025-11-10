class GenerateBlogPostJob < ApplicationJob
    queue_as :default
  
    def perform(blog_post_id)
      post = BlogPost.find(blog_post_id)
      
      begin
        content = generate_with_gemini(post.title)
        
        if content.blank?
          content = generate_with_openai(post.title)
        end
  
        post.update(
          content: content || "Content generation failed",
          status: :published
        )
      rescue => e
        Rails.logger.error("Blog generation failed for #{post.title}: #{e.message}")
        post.update(status: :draft)
      end
    end
  
    private
  
    def generate_with_gemini(title)
      api_key = ENV['GEMINI_API_KEY']
      return nil if api_key.blank?
  
      client = Gemini.new(api_key: api_key)
      
      prompt = "Write a comprehensive blog post about '#{title}'. 800-1200 words, well-structured, professional tone."
  
      response = client.generate_content(prompt)
      response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    rescue => e
      Rails.logger.warn("Gemini API error: #{e.message}")
      nil
    end
  
    def generate_with_openai(title)
      api_key = ENV['OPENAI_API_KEY']
      return nil if api_key.blank?
  
      client = OpenAI::Client.new(access_token: api_key)
  
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            { role: "user", content: "Write a comprehensive blog post about '#{title}'. 800-1200 words, well-structured, professional tone." }
          ],
          temperature: 0.7,
          max_tokens: 2000
        }
      )
  
      response.dig('choices', 0, 'message', 'content')
    rescue => e
      Rails.logger.warn("OpenAI API error: #{e.message}")
      nil
    end
  end
  