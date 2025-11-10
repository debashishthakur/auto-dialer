class Api::V1::BlogPostsController < ApplicationController
    skip_before_action :verify_authenticity_token
  
    def index
      @posts = BlogPost.all.order(created_at: :desc)
      render json: @posts.map { |p| blog_post_json(p) }
    end
  
    def batch_create
      titles = params[:blog_titles].to_s.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
      
      results = titles.map do |title|
        post = BlogPost.create!(
          title: title,
          status: :draft,
          content: "Generating content for #{title}..."
        )
        GenerateBlogPostJob.perform_later(post.id)
        blog_post_json(post)
      end
  
      render json: { posts: results, message: "#{results.length} blog posts queued for generation" }, status: :created
    end
  
    private
  
    def blog_post_json(post)
      {
        id: post.id,
        title: post.title,
        slug: post.slug,
        content: post.content,
        status: post.status,
        created_at: post.created_at,
        updated_at: post.updated_at
      }
    end
  end
  