import type { Category } from './category';
import type { Author } from './author';

export interface Recipe {
  id: string;
  title: string;
  image_url: string | null;
  ratings: number | null;
  cook_time: number;
  prep_time: number;
  cuisine: string | null;
  category: Category | null;
  author: Author | null;
  ingredients: string[];
}

export interface RecipeDetail extends Recipe {
  created_at: string;
}
