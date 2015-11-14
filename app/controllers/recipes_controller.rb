require 'rake'
RecipeBook::Application.load_tasks


class RecipesController < ApplicationController

  before_action :require_current_user, :except => [:index]


  def create
    @recipe = current_user.recipes.create!
    @recipe.instructions.create!
    @recipe.ingredients.create!

    respond_to do |format|
      format.json { render json: @recipe.to_json(:include => [:instructions, :ingredients]), status: 201 }
    end
  end


  def show
    @recipe = Recipe.where(:id => params[:id])[0]

    if @recipe
      respond_to do |format|
        format.json { render json: @recipe.to_json(:include => [:instructions, :ingredients]), status: 200 }
      end
    else
      respond_to do |format|
        format.json { render nothing: true, status: 404 }
      end
    end

  end


  def update
    @recipe = Recipe.where(:id => params[:id])[0]

    if @recipe.update(recipe_params)
      if params['$name'] === 'scraper'
        Rake::Task['recipes:scrape_nyt'].invoke(@recipe)
        Rake::Task['recipes:scrape_nyt'].reenable
        @recipe = Recipe.where(:id => params[:id])[0]
      end

      respond_to do |format|
        format.json { render json: @recipe.to_json(:include => [:instructions, :ingredients]), status: 200 }
      end

    else
      respond_to do |format|
        format.json { render :nothing => :true, :status => 422 }
      end
    end
  end


  def destroy
    @recipe = Recipe.find(params[:id])

    if @recipe.destroy
      respond_to do |format|
        format.json { render :nothing => :true, :status => 204 }
      end
    else
      respond_to do |format|
        format.json { render :nothing => :true, :status => 422 }
      end
    end

  end


  private

    def recipe_params
      params.require(:recipe).permit( :title,
                                      :author,
                                      :photo_url,
                                      :description,
                                      :url,
                                      :ingredients_attributes => [:id, :name],
                                      :instructions_attributes => [:id, :body])
    end


    def require_current_user
      recipe = Recipe.find(params[:id])
      unless recipe.user == current_user
        flash.now[:danger] = "You're not authorized to do this!"
        respond_to do |format|
          format.json { render :nothing => :true, :status => 401 }
        end
      end
    end

end
