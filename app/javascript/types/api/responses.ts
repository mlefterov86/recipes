import type { Recipe, RecipeDetail } from '../models/recipe';
import type { Category } from '../models/category';
import type { Author } from '../models/author';
import type { PaginationMeta } from './pagination';

export interface RecipesResponse {
  data: Recipe[];
  meta: PaginationMeta;
}

export interface RecipeDetailResponse {
  data: RecipeDetail;
}

export interface CategoriesResponse {
  data: Category[];
}

export interface AuthorsResponse {
  data: Author[];
}
