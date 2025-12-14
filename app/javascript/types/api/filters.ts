export type SortOption =
  | 'rating_desc'
  | 'rating_asc'
  | 'created_desc'
  | 'created_asc'
  | 'title_asc'
  | 'title_desc'
  | 'author_asc'
  | 'author_desc'
  | 'category_asc'
  | 'category_desc';

export interface FilterParams {
  page: number;
  category_id?: number;
  author_id?: number;
  title?: string;
  ingredient?: string;
  query?: string;
  sort_by?: SortOption;
}
