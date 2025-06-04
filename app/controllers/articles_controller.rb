class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy]

  def index
    @articles = Article.includes(:category, :tags)
    @articles = @articles.by_category(params[:category_id]) if params[:category_id].present?
    @articles = @articles.tagged_with(params[:tag]) if params[:tag].present?
    @articles = @articles.page(params[:page]).per(10)

    @categories = Category.all
    @popular_tags = Tag.popular.limit(20)
  end

  def show
    @related_articles = Article.where(category: @article.category)
                               .where.not(id: @article.id)
                               .limit(5)
  end

  def new
    @article = Article.new
    @categories = Category.all
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article, notice: '記事が正常に作成されました。'
    else
      @categories = Category.all
      render :new
    end
  end

  def edit
    @categories = Category.all
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: '記事が正常に更新されました。'
    else
      @categories = Category.all
      render :edit
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path, notice: '記事が削除されました。'
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :content, :category_id, :tag_list)
  end
end